function path = initialize_tif_out(path, tab, r, c, b)
    % z == 1
    tif_path = fullfile(path.outdir_path, [path.time_string, '.tif']);

    tags = struct();
    tags.ImageLength = r;
    tags.ImageWidth = c;
    tags.Photometric = Tiff.Photometric.MinIsBlack;
    tags.BitsPerSample = 32;  % float 32
%     tags.SamplesPerPixel = 2;  % n_bands
    tags.RowsPerStrip = 1;
    % tagstruct.Compression = Tiff.Compression.LZW;
    tags.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
    tags.SampleFormat = Tiff.SampleFormat.IEEEFP;
    tags.Software = 'MATLAB';
    
    ref_tags = tags;
    ref_tags.SamplesPerPixel = b;
%     ref_tags.PlanarConfiguration = Tiff.PlanarConfiguration.Separate;
%     ref_tags.ExtraSamples = Tiff.ExtraSamples.Unspecified;
    
    t = Tiff(tif_path, 'w');
    setTag(t, ref_tags)
    t.write(single(nan(r, c, b)))  % apparently not valid without writitng
    close(t)
    
    var_tags = tags;
    var_tags.SamplesPerPixel = 1;
    
    fit_var = tab.variable(tab.include);
    placeholder = single(nan(r, c));
    tif_vars = {};
    for i = 1:length(fit_var)
        var = fit_var{i};
        fit_path = fullfile(path.outdir_path, [var, '.tif']);
        t = Tiff(fit_path, 'w');
        setTag(t, var_tags)
        t.write(placeholder)  % apparently not valid without writitng
        close(t)
        tif_vars{i} = fit_path;
    end
    
    rmse_path = fullfile(path.outdir_path, 'rmse.tif');
    t = Tiff(rmse_path, 'w');
    setTag(t, var_tags)
    t.write(placeholder)  % apparently not valid without writitng
    close(t)

    %% output
    path.tif_path = tif_path;
    path.tif_vars = tif_vars;
    path.rmse = rmse_path;
    path.ref_tags = ref_tags;
    path.var_tags = var_tags;
    
end