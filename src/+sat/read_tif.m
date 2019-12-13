function measured = read_tif(tif_path, var_names)
    % .tif doesn't have band names but band indices

    tif = imread(tif_path);
    
    n_bands = length(var_names.bands);
    warning('reading .tif: taking first %d bands as reflectance', n_bands)
    refl = tif(:, :, 1:n_bands);
    measured.refl = permute(refl, [1 2 4 3]);  % adding time for consistency

    [qc_n, success] = str2num(var_names.quality_flag_name);
    if success
        fprintf('reading band #%d as quality flag\n', qc_n)
        measured.qc = tif(:, :, qc_n);
    end

    for prop = {'sza', 'saa', 'oza', 'oaa'}
        prop = prop{:};
        [n, success] = str2num(var_names.(prop));
        if success
            fprintf('reading band #%d as %s\n', n, prop)
            measured.(prop) = tif(:, :, n);
        end
    end

end
