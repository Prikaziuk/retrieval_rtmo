function write_nc_j(j, results_j, uncertainty_j, measurement, tab, n_row, n_col, nc_path, var_names)

    [r, c] = ind2sub([n_row, n_col], j);
    
    %% variables
    fit_var = tab.variable(tab.include);
    fit_val = results_j.parameters(tab.include);
    for k=1:length(fit_var)
        ncwrite(nc_path, fit_var{k}, fit_val(k), [r, c])
    end
    ncwrite(nc_path, 'rmse', results_j.rmse, [r, c])
    ncwrite(nc_path, 'sif_total', sum(results_j.sif), [r, c])

    %% bands (can be extended to soil)
    n_bands = length(var_names.bands);
    for k=1:n_bands
        var_name = sprintf('modelled_%s', var_names.bands{k});
        ncwrite(nc_path, var_name, results_j.refl_mod(k), [r, c])
    end
end