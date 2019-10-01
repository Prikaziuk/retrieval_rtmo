function path = initialize_xlsx(path, measured, var_names, fluo_wl, n_spectra)

    xlsx_path = fullfile(path.outdir_path, [path.time_string '.xlsx']);

    sheets.output = 'output';
    sheets.meas = 'Rmeas';
    sheets.mod = 'Rmod';
    sheets.soil_mod = 'Rsoilmod';
    sheets.fluo = 'Fluorescence';
    sheets.fluo_norm = 'Fluorescence_norm';
    sheets.ts = 'TS_out';
    
    excel_columns = num2cell('A':'Z');
%     n_col = size(measured.refl, 2);
    n_col = n_spectra;
    repeats = fix(n_col / length(excel_columns));  % integer part
    col_needed = excel_columns;
    for i=1:repeats
        col_extra = strcat(excel_columns{i}, excel_columns);
        col_needed = [col_needed, col_extra];
    end
    col_needed = strcat(col_needed, '2'); % in '1' there is header on each sheet
     
    col = col_needed{1};
    
    xlswrite(xlsx_path, measured.wl, sheets.mod, col);
    xlswrite(xlsx_path, measured.wl, sheets.meas, col);
    xlswrite(xlsx_path, measured.wl, sheets.soil_mod, col);
    
    if nargin < 5
        fluo_wl = measured.wl(measured.i_sif);
    end
    
    xlswrite(xlsx_path, fluo_wl, sheets.fluo, col);
    xlswrite(xlsx_path, fluo_wl, sheets.fluo_norm, col);
    
    % rmse, params, std_params 
    output_names = [{'rmse'}; var_names; strcat('std_', var_names)];
   
    xlswrite(xlsx_path, output_names, sheets.output, col);
    
    path.xlsx_path = xlsx_path;
    path.xlsx_cols = col_needed;
    path.sheets = sheets;

end