function [wl, meas, mod, rmse, params, params_std, tab] = read_output(output_xlsx_path)
    sheets.output = 'output';
    sheets.meas = 'Rmeas';
    sheets.mod = 'Rmod';
    sheets.soil_mod = 'Rsoilmod';
    sheets.fluo = 'Fluorescence';
    sheets.fluo_norm = 'Fluorescence_norm';
    sheets.ts = 'TS_out';
    
%     path.xlsx_path = output_xlsx_path;
    %% for fit quality testing `plot.reflectance()`
    meas = xlsread(output_xlsx_path, sheets.meas);
    mod = xlsread(output_xlsx_path, sheets.mod);
    wl = meas(:, 1);
    meas = meas(:, 2:end);
    mod = mod(:, 2:end);
    
    [params_all, names, ~] = xlsread(output_xlsx_path, sheets.output);
    rmse = params_all(1, :);
    
    %% for validation plot `plot.modelled2measured()`
    names = names(2:end);  % first - empty
    tab = io.read_input_sheet(output_xlsx_path);
    [~, i_names, ~] = intersect(names, tab.variable, 'stable');
    params = params_all(i_names, :);
    [~, i_names_std, ~] = intersect(names, strcat('std_', tab.variable), 'stable');
    params_std = params_all(i_names_std, :);
end