function save_output_j(j, results_j, uncertainty_j, measurement, path)

    xlsx_path = path.xlsx_path;
    sheets = path.sheets;
    col = path.xlsx_cols{j + 1};  % +1 because first column with names
    
    xlswrite(xlsx_path, measurement.refl, sheets.meas, col);
    
    xlswrite(xlsx_path, results_j.refl_mod, sheets.mod, col);
    xlswrite(xlsx_path, results_j.soil_mod, sheets.soil_mod, col);
    
    xlswrite(xlsx_path, results_j.sif, sheets.fluo, col);
    xlswrite(xlsx_path, results_j.sif_norm, sheets.fluo_norm, col);
    
    params = [results_j.rmse;  results_j.parameters; uncertainty_j.std_params];
    xlswrite(xlsx_path, params, sheets.output, col);

end