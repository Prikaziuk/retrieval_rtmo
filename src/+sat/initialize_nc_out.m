function path = initialize_nc_out(path, tab, x, y, z, band_names, measured, i_row, i_col)
    
    nc_path = fullfile(path.outdir_path, [path.time_string, '.nc']);

    fit_var = tab.variable(tab.include);
    fit_units =  tab.units(tab.include);
    fit_description =  tab.description(tab.include);
    
    mod_var = {'rmse', 'sif_total', 'exitflag'};
    mod_units = {'-', 'W m-2 sr-1', '-'};
    mod_description = {'root mean square error', ...
        'integrated value of canopy sun induced fluorescence in observation direction', ...
        'lsqnonlin exitflag (value > 0 means ok)'};
    
    vars = [fit_var; mod_var'];
    units = [fit_units; mod_units'];
    description = [fit_description; mod_description'];
    
    n_vars = length(vars);
    for i=1:n_vars
        var_name = vars{i};
        nccreate(nc_path, var_name, 'Dimensions', {'x', x, 'y', y, 'z', z}, 'FillValue', NaN);
        ncwriteatt(nc_path, var_name, 'units', units{i})
        ncwriteatt(nc_path, var_name, 'description', description{i})
    end
    
    %% bands
    nc_var_bands = cellfun(@(x) sprintf('modelled_%s', x), band_names, 'UniformOutput', false);
    for i=1:length(nc_var_bands)
        nccreate(nc_path, nc_var_bands{i}, 'Dimensions', {'x', x, 'y', y, 'z', z}, 'FillValue', NaN);
        ncwriteatt(nc_path, nc_var_bands{i}, 'units', '-')
        ncwriteatt(nc_path, nc_var_bands{i}, 'description', 'best fit simulated RTMo reflectance')
    end
    
    %% coordinates
    % TODO: possible inversion: lon is x and lat is y
    if all(isfield(measured, {'lat', 'lon'}))
        if size(measured.lat, 2) == 1
            nccreate(nc_path, 'lat', 'Dimensions', {'x', x})
            ncwrite(nc_path, 'lat', measured.lat(i_row))
            nccreate(nc_path, 'lon', 'Dimensions', {'y', y})
            ncwrite(nc_path, 'lon', measured.lon(i_col))
        else
            nccreate(nc_path, 'lat', 'Dimensions', {'x', x, 'y', y})
            ncwrite(nc_path, 'lat', measured.lat(i_row, i_col))
            nccreate(nc_path, 'lon', 'Dimensions', {'x', x, 'y', y})
            ncwrite(nc_path, 'lon', measured.lon(i_row, i_col))
        end
    end
    
    %% output
    path.nc_path = nc_path;
            
    path.nc_vars = struct();
    path.nc_vars.bands = nc_var_bands;
    path.nc_vars.params = fit_var;
    path.nc_vars.rmse = 'rmse';
    path.nc_vars.sif_total = 'sif_total';
    path.nc_vars.exitflag = 'exitflag';
    
end