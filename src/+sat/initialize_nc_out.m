function initialize_nc_out(nc_out_path, tab, x, y, z, band_names)

    fit_var = tab.variable(tab.include);
    fit_units =  tab.units(tab.include);
    fit_description =  tab.description(tab.include);
    
    mod_var = {'rmse', 'sif_total'};
    mod_units = {'-', 'W m-2 sr-1'};
    mod_description = {'root mean square error', ...
        'integrated value of canopy sun induced fluorescence in observation direction'};
    
    vars = [fit_var; mod_var'];
    units = [fit_units; mod_units'];
    description = [fit_description; mod_description'];
    
    n_vars = length(vars);
    for i=1:n_vars
        var_name = vars{i};
        nccreate(nc_out_path, var_name, 'Dimensions', {'x', x, 'y', y, 'z', z}, 'FillValue', NaN);
        ncwriteatt(nc_out_path, var_name, 'units', units{i})
        ncwriteatt(nc_out_path, var_name, 'description', description{i})
    end
    
    n_bands = length(band_names);
    for i=1:n_bands
        var_name = sprintf('modelled_%s', band_names{i});
        nccreate(nc_out_path, var_name, 'Dimensions', {'x', x, 'y', y, 'z', z}, 'FillValue', NaN);
        ncwriteatt(nc_out_path, var_name, 'units', '-')
        ncwriteatt(nc_out_path, var_name, 'description', 'best fit simulated RTMo reflectance')
    end
    
    ncwriteatt(nc_out_path, '/', 'auto_grouping', 'modelled_*')  % TODO doesn't work
    
    
end