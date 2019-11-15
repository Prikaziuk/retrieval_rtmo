function [refl_band, soil_band, fluo] = rtmo2srf_refl(rad, SIF, soil_refl, wlP, irr_prospect, sensor)
    rso     = rad.rso;
    rdo     = rad.rdo;
    rdd     = rad.rdd;
    rsd     = rad.rsd;
    SIFs    = SIF;

    [Esun_, Esky_, E_int] = equations.transmittances2irradiance(irr_prospect, rdd, rsd, sensor.Rin);
    
    piL_    = rso .* Esun_ + rdo .* Esky_ + SIFs;
    
    Etot    = cut_to_srfs(Esun_ + Esky_, wlP, sensor);
    piL_    = cut_to_srfs(piL_, wlP, sensor);
    refl_band = piL_ ./ Etot;

    % this is incorrect to subset reflectance but for soil we don't have radiance
%     refl = piL_ ./ (Esun_ + Esky_);
%     refl_band = cut_to_srfs(refl, wlP, sensor);
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
