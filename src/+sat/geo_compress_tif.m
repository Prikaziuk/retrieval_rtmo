function geo_compress_tif(path) 
    %% georeferencing
    input_image_path = path.image_path;
    
    ver_out = ver;
    toolboxes = {ver_out.Name};
    geo_tif = any(strcmp('Mapping Toolbox', toolboxes));
    
    if geo_tif
        fprintf('copying georeference tags from input image %s\n', input_image_path)
        geoinfo = geotiffinfo(input_image_path);
        key = geoinfo.GeoTIFFTags.GeoKeyDirectoryTag;
        R = geoinfo.SpatialRef;
    else
        warning(['Mapping Toolbox is not installed. Output .tifs can not be georeferenced.\n'...
            'Use gdal_translate to georeference from input image %s\n'...
            'Output .tifs are identical to input image'], input_image_path)
    end
    
    %% compression
    comp = struct();
    % compresses single and multi band 
    % slow to open in SNAP
%     comp.Compression = Tiff.Compression.LZW;
    % compresses multiband only but with the same result as LZW,
    % fast in SNAP, default for geotiff
    comp.Compression = Tiff.Compression.PackBits;
    
    %% rewriting
    if geo_tif
        for v = [path.tif_path, path.tif_vars, path.rmse]
            v = v{:};
            im = read_tif(v);
            if size(im, 3) == 10
                im = im(:, :, 1:9);
            end
            geotiffwrite(v, im, R, 'GeoKeyDirectoryTag', key, 'TiffTags', comp)
        end
    else
        if ~isempty(comp)
            rewrite_tif(path.tif_path, path.ref_tags, comp) % multiband tags
            for v = [path.tif_vars, path.rmse]
                rewrite_tif(v{:}, path.var_tags, comp)
            end
        end
    end

end

    
function im = read_tif(tif_path)
    t = Tiff(tif_path);
    im = t.read();
    t.close()
end


function rewrite_tif(tif_path, tags, comp)
    im = read_tif(tif_path);
    t = Tiff(tif_path, 'w');
    setTag(t, tags)
    setTag(t, comp)
    t.write(im)
    t.close()
end

