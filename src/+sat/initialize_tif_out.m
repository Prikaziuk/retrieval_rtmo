function path = initialize_tif_out(path, tab, x, y, b)
    % z == 1
    tif_path = fullfile(path.outdir_path, [path.time_string, '.tif']);

    tags = struct();
    tags.ImageLength = x;
    tags.ImageWidth = y;
    tags.Photometric = Tiff.Photometric.MinIsBlack;
    tags.BitsPerSample = 64;
%     tags.SamplesPerPixel = 2;  % n_bands
    tags.RowsPerStrip = 1;
    % tagstruct.Compression = Tiff.Compression.LZW;
%     tags.PlanarConfiguration = Tiff.PlanarConfiguration.Separate;
    tags.SampleFormat = Tiff.SampleFormat.IEEEFP;
    tags.Software = 'MATLAB';
%     setTag(t,tags)
    
    ref_tags = tags;
    ref_tags.SamplesPerPixel = b;
    ref_tags.PlanarConfiguration = Tiff.PlanarConfiguration.Separate;
    
    t = Tiff(tif_path, 'w');
    setTag(t, ref_tags)
    t.write(zeros(1, 1, b))  % apparently not valid without writitng
    close(t)
    
    var_tags = tags;
    var_tags.SamplesPerPixel = 1;
    var_tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    
    fit_var = tab.variable(tab.include);
    tif_vars = {};
    for i = 1:length(fit_var)
        var = fit_var{i};
        fit_path = fullfile(path.outdir_path, [var, '.tif']);
        t = Tiff(fit_path, 'w');
        setTag(t, var_tags)
        t.write(0)  % apparently not valid without writitng
        close(t)
        tif_vars{i} = fit_path;
    end
    
    rmse_path = fullfile(path.outdir_path, 'rmse.tif');
    t = Tiff(rmse_path, 'w');
    setTag(t, var_tags)
    t.write(0)  % apparently not valid without writitng
    close(t)

    %% output
    path.tif_path = tif_path;
    path.tif_vars = tif_vars;
    path.rmse = rmse_path;
    
end