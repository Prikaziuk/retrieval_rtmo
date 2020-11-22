function save_output(path, rmse_all, parameters, parameters_std, refl_meas, refl_mod, refl_soil, sif_norm, sif_rad)
    
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