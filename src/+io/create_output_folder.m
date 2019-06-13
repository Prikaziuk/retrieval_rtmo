function path = create_output_folder(input_path, path, var_names)

    time_string = sprintf('%4.0f-%02.0f-%02.0f-%02.0f%02.0f%02.0f', clock);
%     time_string = 'test';
    outdir_path    = fullfile(path.output_path, path.simulation_name, time_string);
    mkdir(outdir_path)

    copyfile(input_path, fullfile(outdir_path, 'Input_data.xlsx'),'f');
    
    files.output = fullfile(outdir_path, 'output.csv');
    files.meas = fullfile(outdir_path, 'Rmeas.csv');
    files.mod = fullfile(outdir_path, 'Rmod.csv');
    files.soil_mod = fullfile(outdir_path, 'Rsoilmod.csv');
    files.fluo = fullfile(outdir_path, 'Fluorescence.csv');
    files.fluo_norm = fullfile(outdir_path, 'Fluorescence_norm.csv');
    files.ts = fullfile(outdir_path, 'TS_out.csv');
    files.wl = fullfile(outdir_path, 'wl_meas.csv');
    
    row_names.output = [{'rmse'}; var_names; strcat('std_', var_names)];
    
    path.outdir_path = outdir_path;
    path.files = files;
    path.row_names = row_names;
end