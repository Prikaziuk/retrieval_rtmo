function compress_tif(path)
    
    %% refl
    im_path = path.tif_path;
    t = Tiff(im_path);
    im = t.read();
    t.close()

    ref_tags = path.ref_tags;
    ref_tags.Compression = Tiff.Compression.LZW;
    t = Tiff(im_path, 'w');
    setTag(t, ref_tags)
    t.write(im)
    t.close()
    
    %% vars
    tags = path.var_tags;
    tags.Compression = Tiff.Compression.LZW;
    for v = [path.tif_vars, path.rmse]
        v = v{:};
        t = Tiff(v);
        im = t.read();
        t.close()
        t = Tiff(v, 'w');
        setTag(t, tags)
        t.write(im)
        t.close()
    end
end