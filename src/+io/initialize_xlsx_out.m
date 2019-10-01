function path = initialize_xlsx_out(path, measured, var_names, n_spectra, fluo_wl)
    
    if ~isfield(path, 'xlsx_path')  % not copied by create folder
        time_string = sprintf('%4.0f-%02.0f-%02.0f-%02.0f%02.0f%02.0f', clock);
        outdir_path    = fullfile(path.output_path, path.simulation_name);
        mkdir(outdir_path)
        
        xlsx_path = fullfile(outdir_path, [time_string '.xlsx']);
        copyfile(path.input_path, xlsx_path, 'f');
        path.xlsx_path = xlsx_path;
    end
    xlsx_path = path.xlsx_path;

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
    
%     path.outdir_path = outdir_path;
    path.xlsx_path = xlsx_path;
    path.xlsx_cols = col_needed;
    path.sheets = sheets;
%     path.time_string = time_string;

end