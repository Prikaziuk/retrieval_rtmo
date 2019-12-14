function save_output_tif_batch(path, parameters, rmse_all, refl_mod, n_row, n_col, include, batch_c)

    %% reshaping for all-at-once writing
    r = n_row;
    c = n_col;
    
    % tensors
    parameters = parameters(include, :);  % we write only what was asked to fit
    parameters = single(permute(reshape(parameters, [size(parameters, 1), r, c]), [2 3 1]));
    refl_mod = single(permute(reshape(refl_mod, [size(refl_mod, 1), r, c]), [2 3 1]));

    n_row_batch = size(parameters, 1);
    
    % vectors
    rmse = single(reshape(rmse_all, [r, c]));
    
    %% variables
    vars = path.tif_vars;
    for k=1:length(vars)
        t = Tiff(vars{k}, 'r+');
        for i = 1:n_row_batch
            i_stripe = i + batch_c - 1;
            writeEncodedStrip(t, i_stripe, parameters(i, :, k))
        end
        t.close()
    end
    
    %% rmse
    
    t = Tiff(path.rmse, 'r+');
    for i = 1:n_row_batch
        i_stripe = i + batch_c - 1;
        writeEncodedStrip(t, i_stripe, rmse(i, :, :, :))
    end
    t.close()

    %% bands
    t = Tiff(path.tif_path, 'r+');
    for i = 1:n_row_batch
        i_stripe = i + batch_c - 1;
        writeEncodedStrip(t, i_stripe, refl_mod(i, :, :))
    end
    t.close()
    
end