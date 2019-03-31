function save_output(input_path, path, measured, c, reflSAIL_all, rsoil_all, soilpar_all, leafbio_all, ...
    canopy_all, fluorescence_all, rmse_all, J_all)
    
    time_string = sprintf('%4.0f-%02.0f-%02.0f-%02.0f%02.0f%02.0f', clock);
    Output_dir      =fullfile(path.output_path, path.simulation_name);
    mkdir(Output_dir)

    copyfile(input_path,fullfile(Output_dir, [time_string '.xlsx']),'f');
    outfile = fullfile(Output_dir, [time_string '.xlsx']);

    xlswrite(outfile,measured.refl(:,c),'Rmeas','B2'  );
    xlswrite(outfile,measured.wl,'Rmod','A2'  );
    xlswrite(outfile,measured.wl,'Rmeas','A2'  );
    xlswrite(outfile,measured.wl,'Rsoilmod','A2'  );
    
    xlswrite(outfile,reflSAIL_all,'Rmod','B2'  );
    xlswrite(outfile,rsoil_all,'Rsoilmod','B2'  );
    xlswrite(outfile,soilpar_all.B','output','B2'  );
    xlswrite(outfile,soilpar_all.BSMlat','output','B3'  );
    xlswrite(outfile,soilpar_all.BSMlon','output','B4'  );
    xlswrite(outfile,soilpar_all.SMC','output','B5'  );
    xlswrite(outfile,leafbio_all.Cab','output','B6'  );
    xlswrite(outfile,leafbio_all.Cw','output','B7'  );
    xlswrite(outfile,leafbio_all.Cdm','output','B8'  );
    xlswrite(outfile,leafbio_all.Cs','output','B9'  );
    xlswrite(outfile,leafbio_all.Cca','output','B10'  );
    xlswrite(outfile,leafbio_all.Cant','output','B11'  );
    xlswrite(outfile,leafbio_all.N','output','B12'  );
    xlswrite(outfile,canopy_all.LAI','output','B13'  );
    xlswrite(outfile,canopy_all.LIDFa','output','B14'  );
    xlswrite(outfile,canopy_all.LIDFb','output','B15'  );
    xlswrite(outfile,fluorescence_all.wpcf,'output','B16'  );
    xlswrite(outfile,fluorescence_all.SIF,'Fluorescence','B2'  );
    xlswrite(outfile,fluorescence_all.SIFnorm,'Fluorescence_norm','B2'  );
    xlswrite(outfile,rmse_all','output','B20'  );
    xlswrite(outfile,leafbio_all.std','output','B21');

    save(fullfile(Output_dir, [time_string '_J']), 'J_all')
end