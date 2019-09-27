function [toa_band, soil_band, fluo] = rtmo2srf_radiance(rad, SIF, soil_refl, wlP, irr_prospect, sensor)
    rso     = rad.rso;
    rdo     = rad.rdo;
    rdd     = rad.rdd;
    rsd     = rad.rsd;
    SIFs    = SIF;
    
    if ~ismember('t', fieldnames(irr_prospect))
        error('Can calculate TOA only with MODTRAN T18')
    end
    
    % Verhoef, Van der Tol, Middleton 2018 eq. 12
    t = irr_prospect.t;
    Ltoa = t(:, 1) .* t(:, 2) + t(:, 1) .* (t(:, 8) .* rso + t(:, 9) .* rdo + t(:, 10) .* rsd + t(:, 11) .* rdd) ./ (1 - rdd .* t(:, 3)); 
    [E_sun, E_sky, E_int] = equations.transmittances2irradiance(irr_prospect, rdd, rsd, sensor.Rin);
%     Ltoc = (rso .* E_sun + rdo .* E_sky) / pi;
    
    toa_band = cut_to_srfs(Ltoa, wlP, sensor);
    soil_band = cut_to_srfs(soil_refl, wlP, sensor);
    
    %% calculate fluorescence for legacy
    fluo.SIF = SIFs(640-399:850-399);
    fluo.SIFnorm = fluo.SIF / E_int;
    
end

function refl_band = cut_to_srfs(refl, wl_refl, sensor)
%     i_wlP = sensor.srf.i_wlP;
    i_wlP = get_i_srf_in_wl(wl_refl, sensor.srf.wl);
    resp = sensor.srf.resp;
    n_bands = size(i_wlP, 2);
    refl_band = zeros(n_bands, 1);
    for i=1:n_bands
        i_nans = isnan(i_wlP(:, i));
        i_refl = i_wlP(~i_nans, i);
        resp_band = resp(~i_nans, i);
        refl_band(i) = nansum(refl(i_refl) .* resp_band) / nansum(resp_band);
    end
end

function i_wlP = get_i_srf_in_wl(wl_indexed, wl_srf)

    [n_rows, n_bands] = size(wl_srf);  % columns of wl_srf are bands
    i_wlP = zeros(n_rows, n_bands);

    for i = 1:n_bands
        wl = wl_srf(:, i);
        [~, ~, i_p] = intersect(wl, wl_indexed);
        i_p(end + 1 : n_rows) = nan;
        i_wlP(:, i) = i_p;
    end
    
end
