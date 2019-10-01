function path = create_output_folder(path)

    time_string = sprintf('%4.0f-%02.0f-%02.0f-%02.0f%02.0f%02.0f', clock);
%     time_string = 'test';
    outdir_path    = fullfile(path.output_path, path.simulation_name, time_string);
    mkdir(outdir_path)
    
    xlsx_path = fullfile(outdir_path, [time_string '.xlsx']);
    copyfile(path.input_path, xlsx_path,'f');
    
    path.outdir_path = outdir_path;
    path.time_string = time_string;
    path.xlsx_path = xlsx_path;

end