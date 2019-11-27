function [irradiance, signal_at_sensor] = irradiance2sensor_wl(irr_full, instrument, wl_meas)
    
    [wl_sensor, fwhm] = parse_instrument(instrument);
    
    if isfield(irr_full, 't')
        to_resample = irr_full.t;
    else
        to_resample = [irr_full.sun irr_full.sky];
    end
    
    n_wl = length(wl_sensor);
    ncol = size(to_resample, 2);
    signal_at_sensor = zeros(n_wl, ncol);
    for i = 1:n_wl
        wl = wl_sensor(i);
        HWHM = fwhm(i) / 2;
        i_wl = (irr_full.wl >= wl - HWHM) & (irr_full.wl <= wl + HWHM);
        % Gaussian, weighted average or other are also possible here instead of simple mean
        signal_at_sensor(i, :) = nanmean(to_resample(i_wl, :));
    end
    
    i_nan = any(isnan(signal_at_sensor), 2);  % stable interpolation over nan_regions
    signal_in_meas = interp1(wl_sensor(~i_nan), signal_at_sensor(~i_nan, :), wl_meas, 'splines', NaN);
    
    irradiance.wl = wl_meas;
    if isfield(irr_full, 't')
        irradiance.t = signal_in_meas;
    else
        irradiance.sun = signal_in_meas(:, 1);
        irradiance.sky = signal_in_meas(:, 2);
    end
    
end


function [wl, fwhm] = parse_instrument(instrument)
    [nrow, ncol] = size(instrument);
%     if ncol ~= 2
    if any(strcmp(instrument.Properties.VariableNames, 'SSI'))
        wl = [];
        fwhm = [];
        for i=1:nrow
            domain = instrument(i,:);
            wl_domain = domain.start : domain.SSI : domain.stop;
            fwhm_domain = repmat(domain.FWHM, size(wl_domain));
            wl = [wl, wl_domain];
            fwhm = [fwhm, fwhm_domain];
        end
    else
        wl = instrument.wl;
        fwhm = instrument.FWHM;
    end
end
