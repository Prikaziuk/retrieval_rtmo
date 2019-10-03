function measured = read_sixs(nc_path, i_srf, measured)
    band_names = cellfun(@(s) sprintf('Oa%02d', s), num2cell(1:21), 'UniformOutput', false);

    xa_names = cellfun(@(s) sprintf('%s_xa', s), band_names, 'UniformOutput', false); 
    xb_names = cellfun(@(s) sprintf('%s_xb', s), band_names, 'UniformOutput', false); 
    xc_names = cellfun(@(s) sprintf('%s_xc', s), band_names, 'UniformOutput', false); 
    rad_names = cellfun(@(s) sprintf('%s_radiance', s), band_names, 'UniformOutput', false); 

    xa = read_variable_4d(nc_path, xa_names(i_srf));
    xb = read_variable_4d(nc_path, xb_names(i_srf));
    xc = read_variable_4d(nc_path, xc_names(i_srf));
    rad = read_variable_4d(nc_path, rad_names(i_srf));
    
    measured.xa = double(xa);
    measured.xb = double(xb);
    measured.xc = double(xc);
    measured.rad = double(rad);
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