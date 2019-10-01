function save_output_nc_j(j, results_j, uncertainty_j, measurement, tab, n_row, n_col, n_times, path)
    
    nc_path = path.nc_path;
    nc_vars = path.nc_vars;

    [r, c, t] = ind2sub([n_row, n_col, n_times], j);
    
    %% variables
    fit_val = results_j.parameters(tab.include);
    for k=1:length(nc_vars.params)
        ncwrite(nc_path, nc_vars.params{k}, fit_val(k), [r, c, t])
    end
    ncwrite(nc_path, nc_vars.rmse, results_j.rmse, [r, c, t])
    ncwrite(nc_path, nc_vars.sif_total, sum(results_j.sif), [r, c, t])
    ncwrite(nc_path, nc_vars.exitflag, results_j.exitflag, [r, c, t])

    %% bands (can be extended to soil)
    for k=1:length(nc_vars.bands)
        ncwrite(nc_path, nc_vars.bands{k}, results_j.refl_mod(k), [r, c, t])
    end
end