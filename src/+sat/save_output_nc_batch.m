function save_output_nc_batch(path, parameters, rmse_all, refl_mod, sif_rad, extiflags, n_row, n_col, n_times, include, ...
    batch_r, batch_c)
    
    nc_path = path.nc_path;
    nc_vars = path.nc_vars;
    
    %% reshaping for all-at-once writing
    r = n_row;
    c = n_col;
    t = n_times;
    
    % tensors
    parameters = parameters(include, :);  % we write only what was asked to fit
    parameters = permute(reshape(parameters, [size(parameters, 1), r, c, t]), [2 3 4 1]);
    refl_mod = permute(reshape(refl_mod, [size(refl_mod, 1), r, c, t]), [2 3 4 1]);
    
    % vectors
    rmse = reshape(rmse_all, [r, c, t, 1]);
    extiflags = reshape(extiflags, [r, c, t, 1]);
    sif_tot = reshape(sum(sif_rad), [r, c, t, 1]);
        
    %% variables
    for k=1:length(nc_vars.params)
        ncwrite(nc_path, nc_vars.params{k}, parameters(:, :, :, k))
    end
    
    ncwrite(nc_path, nc_vars.rmse, rmse)
    ncwrite(nc_path, nc_vars.sif_total, sif_tot)
    ncwrite(nc_path, nc_vars.exitflag, extiflags)

    %% bands (can be extended to soil)
    for k=1:length(nc_vars.bands)
        ncwrite(nc_path, nc_vars.bands{k}, refl_mod(:, :, :, k))
    end

end