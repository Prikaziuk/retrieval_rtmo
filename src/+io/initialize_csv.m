function path = initialize_csv(path, var_names)
    
    outdir_path = path.outdir_path;

    files.output = fullfile(outdir_path, 'output.csv');
    files.meas = fullfile(outdir_path, 'Rmeas.csv');
    files.mod = fullfile(outdir_path, 'Rmod.csv');
    files.soil_mod = fullfile(outdir_path, 'Rsoilmod.csv');
    files.fluo = fullfile(outdir_path, 'Fluorescence.csv');
    files.fluo_norm = fullfile(outdir_path, 'Fluorescence_norm.csv');
    files.ts = fullfile(outdir_path, 'TS_out.csv');
    files.wl = fullfile(outdir_path, 'wl_meas.csv');
    
    row_names.output = [{'rmse'}; var_names; strcat('std_', var_names)];
    
    path.files = files;
    path.row_names = row_names;
end