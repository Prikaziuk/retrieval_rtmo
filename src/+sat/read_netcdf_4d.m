function out = read_netcdf_4d(nc_path, var_names)
    % dim1 - lat
    % dim2 - lon
    % dim3 - time (even if not present)
    % dim4 - band

    % vars in nc file
    nc_info = ncinfo(nc_path);
    n_vars = length(nc_info.Variables);
    assert(length(nc_info.Dimensions) <= 3, ...
           'I do not operate with datacubes with more than 3 dimensions.')
%     nc_var_names = strings(n_vars, 1);  % > 2017b
    nc_var_names = {}; % < 2017
    for i = 1:n_vars
%         nc_var_names(i) = nc_info.Variables(i).Name; % > 2017
        nc_var_names{i} = nc_info.Variables(i).Name;  % < 2017
    end
    
    %% reflectance
    [band_names, ~, ~] = intersect(var_names.bands, nc_var_names, 'stable');
    if length(band_names) ~= length(var_names.bands)
        missing = setdiff(var_names.bands, band_names);
        error(['some band names (%s) you specified were not found in your .nc file. '...
        'Did you misspell band name on `bands` sheet?'], [missing{:}])
    end
    % if some bands have different sizes cat will collapse
    refl = read_variable_4d(nc_path, band_names);
    
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
        if all(nc_info.Variables(ci(1)).Size == nc_info.Variables(ci(2)).Size)        
            coords = read_variable_4d(nc_path, coord_names);
           % we are sure that the order is {lat, lon} because we forced it in coord_names_expected
            out.lat = coords(:, :, :, 1);
            out.lon = coords(:, :, :, 2);
        else
            out.lat = ncread(nc_path, var_names.latitude);
            out.lon = ncread(nc_path, var_names.longitude);
        end
    end
    % dimensions of coordinates are not fixed can be 1d, 2d, 3d
    
    %% angles
    
    if ~isempty(var_names.sza)
        out.sza = ncread(nc_path, var_names.sza);
    end
    
    if ~isempty(var_names.oza)
        out.oza = ncread(nc_path, var_names.oza);
    end
    
    if ~isempty(var_names.saa) && ~isempty(var_names.oaa)
        saa = ncread(nc_path, var_names.saa);
        oaa = ncread(nc_path, var_names.oaa);
        out.raa = calc_psi(saa, oaa);
    end
    
%     angle_names_expected = {var_names.oaa, var_names.oza, var_names.saa, var_names.sza};
%     [angle_names, ~, ~] = intersect(angle_names_expected, nc_var_names, 'stable');
%     if length(angle_names) ~= length(angle_names_expected)
%         warning(['Ignore this warning if '... 
%             'you prefer to use constant geometry for all pixels (tto, tts, psi). \n' ...
%             'Bands with angles were not found in your .nc file. '], '')
%     else
%         angles = read_variable_4d(nc_path, angle_names);
%         % we are sure that the order is {oaa, oza, saa, sza} because we forced it in angle_names_expected
%         oaa = angles(:, :, :, 1);
%         saa = angles(:, :, :, 3);
%         
%         out.oza = angles(:, :, :, 2);
%         out.sza = angles(:, :, :, 4);
%     end
    
    %% quality flags
    if ~isempty(var_names.quality_flag_name)
        out.qc = ncread(nc_path, var_names.quality_flag_name);
    end
    
    %% display image
%     rgb = refl(:, :, [9 6 3]);
%     rgb_lat_lon = permute(rgb, [2 1 3]);  % for matlab x is row
%     imshow(rgb_lat_lon, []);
    
    %% display one pixel spectra
%     plot(squeeze(wl(1, 1, :)), squeeze(refl(1, 1, :)))

end

function nc_mat = read_variable_4d(nc_path, var_names)
    n_vars = length(var_names);
    nc_mat = [];
    for i = 1:n_vars
        varname = char(var_names(i));
        nc_var = ncread(nc_path, varname);
        nc_mat = cat(4, nc_mat, nc_var);  % lat, lon, time, band_n
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
