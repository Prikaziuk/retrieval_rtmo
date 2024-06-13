function save_output(path, rmse_all, parameters, parameters_std, refl_meas, refl_mod, refl_soil, sif_norm, sif_rad, measurement)
    
    if isunix
        wl = measurement.wl;
        wlF = wl(measurement.i_sif);

        csvwrite(path.files.meas, [wl, refl_meas])
        csvwrite(path.files.mod, [wl, refl_mod])
        csvwrite(path.files.soil_mod, [wl, refl_soil])
        csvwrite(path.files.fluo, [wlF, sif_rad])
        csvwrite(path.files.fluo_norm, [wlF, sif_norm])

        params = [rmse_all;  parameters; parameters_std];
        tab = array2table(params,'RowNames', path.row_names.output);
        writetable(tab, path.files.output, 'WriteRowNames', true, 'WriteVariableNames', false)

        fprintf('Saved ouput in %s\n',  path.files.output)
        
    else
        xlsx_path = path.xlsx_path;
        sheets = path.sheets;
        col = path.xlsx_cols{2}; % first is occupied by names
        
        xlswrite(xlsx_path, refl_meas, sheets.meas, col);
        
        xlswrite(xlsx_path, refl_mod, sheets.mod, col);
        xlswrite(xlsx_path, refl_soil, sheets.soil_mod, col);
        
        xlswrite(xlsx_path, sif_rad, sheets.fluo, col);
        xlswrite(xlsx_path, sif_norm, sheets.fluo_norm, col);
        
        params = [rmse_all;  parameters; parameters_std];
        xlswrite(xlsx_path, params, sheets.output, col);
        
        fprintf('Saved ouput in %s\n', xlsx_path)
    end

end