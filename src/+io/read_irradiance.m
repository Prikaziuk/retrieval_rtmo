function irradiance = read_irradiance(path)
    
    if ~isempty(path.atmfile)
        atmfile       = importdata(fullfile(path.atmfile));
        irradiance.wl = atmfile.data(:, 2);
        t = atmfile.data(:, 3:end);
        if any(isnan(t))
            t = fillmissing(atmfile.data(:, 3:end), 'spline', 1);  % >=2016b
        end
        irradiance.t = t;
    else
        e_sun     = load(fullfile(path.Esun));
        e_sky     = load(fullfile(path.Esky));
        wl_sun = e_sun(:, 1);
        wl_sky = e_sky(:, 1);
        assert(size(e_sun, 1) == size(e_sky, 1) && all(wl_sun == wl_sky), ...
            'sizes or wavelengths of sun and sky irradiance do not match')
        irradiance.wl = wl_sun;
        irradiance.sun = fillmissing(e_sun(:, 2), 'spline');  % >=2016b
        irradiance.sky = fillmissing(e_sky(:, 2), 'spline');
    end
    
end


function v = fillmissing_my(v)
%% for < 2016b users

    % https://nl.mathworks.com/matlabcentral/answers/375459-can-the-fillmissing-function-be-used-earlier-than-2016b-if-not-how-can-i-use-spline-interpolatio
    % grab integer indices of v to input to spline, and find where NaNs are
    x = 1:length(v);
    m = isnan(v);
    % x(~m) contains the indices of the non-NaN values
    % v(~m) contains the non-NaN values
    % x(m) contains the indices of the NaN values, and thus the points at
    % which we would like to query the spline interpolator
    s = spline(x(~m),v(~m),x(m));
    % replace NaN values with interpolated values; plot to see results
    v(m) = s;
end