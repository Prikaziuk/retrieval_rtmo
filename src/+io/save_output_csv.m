function save_output_csv(j, results_j, uncertainty_j, measurement, path)
    
    wl = measurement.wl;
    wlF = wl(measurement.i_sif);

    if j ~= 0  % all matrices are one columns
        out = readtable(path.files.output, 'ReadRowNames', true, 'ReadVariableNames', false);
        out = table2array(out);
        out(:, j) = [results_j.rmse; results_j.parameters; uncertainty_j.std_params];
        
        refl_meas = csvread(path.files.meas);
        refl_meas(:, j) = measurement.refl;
        
        refl_mod = csvread(path.files.mod);
        refl_mod(:, j) = results_j.refl_mod;
        
        refl_soil = csvread(path.files.soil_mod);
        refl_soil(:, j) = results_j.soil_mod;
        
        sif_rad = csvread(path.files.fluo);
        sif_rad(:,j) = results_j.sif;
        
        sif_norm = csvread(path.files.fluo_norm);
        sif_norm(:,j) = results_j.sif_norm;
        
    else
        out = [results_j.rmse; results_j.parameters; uncertainty_j.std_params];
        refl_meas = measurement.refl;
        refl_mod = results_j.refl_mod;
        refl_soil = results_j.soil_mod;
        sif_rad = results_j.sif;
        sif_norm = results_j.sif_norm;
    end

    tab = array2table(out,'RowNames', path.row_names.output);
    writetable(tab, path.files.output, 'WriteRowNames', true, 'WriteVariableNames', false)
    
    csvwrite(path.files.meas, [wl, refl_meas])
    csvwrite(path.files.mod, [wl, refl_mod])
    csvwrite(path.files.soil_mod, [wl, refl_soil])
    csvwrite(path.files.fluo, [wlF, sif_rad])
    csvwrite(path.files.fluo_norm, [wlF, sif_norm])

end