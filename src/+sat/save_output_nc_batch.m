function save_output_nc_batch(path, parameters, rmse_all, refl_mod, sif_rad, extiflags, n_row, n_col, i_t, include, batch_r)
    
    nc_path = path.nc_path;
    nc_vars = path.nc_vars;
    
    %% reshaping for all-at-once writing
    r = n_row;
    c = n_col;
%     t = n_times;
    start_i = [batch_r, 1, i_t];
    
    % tensors
    parameters = parameters(include, :);  % we write only what was asked to fit
    parameters = permute(reshape(parameters, [size(parameters, 1), r, c]), [2 3 1]);
    refl_mod = permute(reshape(refl_mod, [size(refl_mod, 1), r, c]), [2 3 1]);

    
    % vectors
    rmse = reshape(rmse_all, [r, c, 1]);
    extiflags = reshape(extiflags, [r, c, 1]);
    sif_tot = reshape(sum(sif_rad), [r, c, 1]);
    
    %% variables
    for k=1:length(nc_vars.params)
        ncwrite(nc_path, nc_vars.params{k}, parameters(:, :, k), start_i)
    end
    
    ncwrite(nc_path, nc_vars.rmse, rmse, start_i)
    ncwrite(nc_path, nc_vars.sif_total, sif_tot, start_i)
    ncwrite(nc_path, nc_vars.exitflag, extiflags, start_i)

    %% bands (can be extended to soil)
    for k=1:length(nc_vars.bands)
        ncwrite(nc_path, nc_vars.bands{k}, refl_mod(:, :, k), start_i)
    end

end