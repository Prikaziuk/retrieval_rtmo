function irradiance = read_irradiance(path)
    
    if ~isempty(path.atmfile)
        atmfile       = importdata(fullfile(path.atmfile));
        irradiance.wl = atmfile.data(:, 2);
        irradiance.t = fillmissing(atmfile.data(:, 3:end), 'spline', 1);
    else
        e_sun     = load(fullfile(path.Esun));
        e_sky     = load(fullfile(path.Esky));
        wl_sun = e_sun(:, 1);
        wl_sky = e_sky(:, 1);
        assert(size(e_sun, 1) == size(e_sky, 1) && all(wl_sun == wl_sky), ...
            'sizes or wavelengths of sun and sky irradiance do not match')
        irradiance.wl = wl_sun;
        irradiance.sun = fillmissing(e_sun(:, 2), 'spline');
        irradiance.sky = fillmissing(e_sky(:, 2), 'spline');
    end
    
end