function out = read_netcdf(nc_path, var_names)  % nc_path

    % vars in nc file
    nc_path = fullfile(nc_path);
    nc_info = ncinfo(nc_path);
    n_vars = length(nc_info.Variables);
    nc_var_names = strings(n_vars, 1);
    nc_var_sizes = zeros(n_vars, 2);  % 2 to length(nc_info.Dimensions)
    for i = 1:n_vars
        nc_var_names(i) = nc_info.Variables(i).Name;
        var_size = nc_info.Variables(i).Size;
        if ~isempty(var_size)
            if length(var_size) == 1
                var_size = [var_size, 0];  % metadata field
            end
            if length(var_size) > 2
                disp('ups')
            end
            nc_var_sizes(i, :) = var_size;
        end
    end
    
    %% reflectance
    [band_names, ~, bi] = intersect(var_names.bands, nc_var_names, 'stable');
    assert(length(band_names) == length(var_names.bands), ...
        ['some band names you specified were not found in your .nc file. '...
        'Did you misspell band name on `bands` sheet?'])
    [x_b, y_b] = get_band_dimensions(nc_var_sizes, bi);
    refl = read_variable(nc_path, x_b, y_b, band_names);
%     refl = read_variable_any_size(nc_path, band_names);
    
    %% there is a test on reflectance validity, but some fill values like -1, -999 will fail it
%     refl_na_free = refl(~isnan(refl));
%     assert(all(refl_na_free(:) >= 0 & refl_na_free(:) <= 1), ['provided reflectance is > 1 or < 0. ', ...
%         'We fit only top of canopy reflectance (expected in the range [0 1])'])
    out.refl = refl;
    
    %% coordinates
    coord_names_expected = {var_names.latitude, var_names.longitude};
    [coord_names, ~, ci] = intersect(coord_names_expected, nc_var_names, 'stable');
    if length(coord_names) ~= length(coord_names_expected)
        warning(['Ignore this warning if '... 
            'you fit whole image not a subset around (pix_lat, pix_lon). \n' ...
            'Bands with coordinates were not found in your .nc file. '], '')
        coords = [];
    else
        [x_c, y_c] = get_band_dimensions(nc_var_sizes, ci);
        assert(x_c == x_b && y_c == y_b, ['lat/lon and reflectance have different dimentions. '...
            'Did you misspell lat/lon band name on `satellite` sheet?'])
        coords = read_variable(nc_path, x_c, y_c, coord_names);
       % we are sure that the order is {lat, lon} because we forced it in coord_names_expected
        out.lat = coords(:, :, 1);
        out.lon = coords(:, :, 2);
    end
    
    %% angles
    angle_names_expected = {var_names.oaa, var_names.oza, var_names.saa, var_names.sza};
    [angle_names, ~, ai] = intersect(angle_names_expected, nc_var_names, 'stable');
    if length(angle_names) ~= length(angle_names_expected)
        warning(['Ignore this warning if '... 
            'you prefer to use constant geometry for all pixels (tto, tts, psi). \n' ...
            'Bands with angles were not found in your .nc file. '], '')
    else
        [x_a, y_a] = get_band_dimensions(nc_var_sizes, ai);
        angles = read_variable(nc_path, x_a, y_a, angle_names);
        % extrapolating angles of Sentinel-3
        if x_a ~= x_b || y_a ~= y_b
            warning(['angles and reflectance have different dimentions. \n' ...
                'DO NOT WORRY: it is a known feature of Sentinel-3. \n' ...
                'I will try extrapolating angles with `TP_latitude`, `TP_longitude` over coordinates \n' ...
                'If you do not have TP bands or coordinates - solve it yourself, please'], '')
            assert(~isempty(coords), 'No, you do not have lat/lon bands or you misspelled them')

            tie_point_names = {'TP_latitude', 'TP_longitude'};
            [tp_names, ~, tpi] = intersect(tie_point_names, nc_var_names, 'stable');
            assert(length(tp_names) == length(tie_point_names), ...
                'No, you do not have tie_point (TP) bands, corresponding to angles dimensions')
            [x_tp, y_tp] = get_band_dimensions(nc_var_sizes, tpi);
            assert(x_tp == x_a && y_tp == y_a, ['You have TP bands, but somehow their dimensions '...
                'differ from angles dimentions.'])
            tp_coords = read_variable(nc_path, x_tp, y_tp, tp_names);
            angles = interpolate_tp(angles, tp_coords, coords);
        end
        % we are sure that the order is {oaa, oza, saa, sza} because we forced it in angle_names_expected
        oaa = angles(:, :, 1);
        saa = angles(:, :, 3);
        out.raa = calc_psi(saa, oaa);
        out.oza = angles(:, :, 2);
        out.sza = angles(:, :, 4);
    end
    
    %% display image
%     rgb = refl(:, :, [9 6 3]);
%     rgb_lat_lon = permute(rgb, [2 1 3]);  % for matlab x is row
%     imshow(rgb_lat_lon, []);
    
    %% display one pixel spectra
%     plot(squeeze(wl(1, 1, :)), squeeze(refl(1, 1, :)))

end

function nc_mat = read_variable(nc_path, x, y, var_names)
    n_vars = length(var_names);
    nc_mat = zeros(x, y, n_vars);
    for i = 1:n_vars
        varname = char(var_names(i));
        nc_mat(:, :, i) = ncread(nc_path, varname);
    end
end

function nc_mat = read_variable_any_size(nc_path, var_names)
    n_vars = length(var_names);
    nc_mat = [];
    for i = 1:n_vars
        varname = char(var_names(i));
        nc_var = ncread(nc_path, varname);
        nc_mat = cat(4, nc_mat, nc_var);
    end
    nc_mat = squeeze(nc_mat);
end

function [x, y] = get_band_dimensions(nc_sizes, i_nc_sizes)
    x_y_band = unique(nc_sizes(i_nc_sizes, :), 'stable');
    assert(length(x_y_band) == 2, ['Bands have different number of pixels. '...
        'I cannot deal with it. Resample all bands to single resolution, please.'])
    x = x_y_band(1);
    y = x_y_band(2);
end

function nc_full = interpolate_tp(nc_tp, tp_coord, coord)
    tp_lat = tp_coord(:, :, 1);
    tp_lon = tp_coord(:, :, 2);
    lat = coord(:, :, 1);
    lon = coord(:, :, 2);
    [x, y] = size(lat);  % we already assured that size(refl) == size(lat)
    n_bands = size(nc_tp, 3);  % typically 4 angles
    nc_full = zeros(x, y, n_bands);
    for i = 1:n_bands
        band = nc_tp(:, :, i);
        F = scatteredInterpolant(double(tp_lat(:)), double(tp_lon(:)), band(:));
        nc_full(:, :, i) = F(lat, lon);
    end
end


function raa = calc_psi(saa, oaa)
    daa = saa - oaa;
    while any(daa < 0 | daa >= 360)
        if any(daa < 0)
            daa = daa + 360;
        else
            daa = daa - 360;
        end
    end
    raa = abs(daa - 180);
end
