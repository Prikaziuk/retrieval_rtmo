function [refl, soil_refl, fluo] = rtmo2measured_refl(rad, SIF, soil_refl, wlP, irr_meas, measurement, Rin)    

    % we assume reflectance factors are smooth enough to be interpolated without errors
    rso     = interp1(wlP, rad.rso, measurement.wl, 'splines', 1E-4);
    rdo     = interp1(wlP, rad.rdo, measurement.wl, 'splines', 1E-4);
    rdd     = interp1(wlP, rad.rdd, measurement.wl, 'splines', 1E-4);
    rsd     = interp1(wlP, rad.rsd, measurement.wl, 'splines', 1E-4);
    SIFs    = interp1(wlP, SIF, measurement.wl, 'splines', 1E-4);

    [Esun_, Esky_, Eint] = helpers.transmittances2irradiance(irr_meas, rdd, rsd, Rin);

    piL_    = rso .* Esun_ + rdo .* Esky_ + SIFs;
    E_tot = Esun_ + Esky_;
    refl    = piL_./ E_tot;
    
    soil_refl  = interp1(wlP, soil_refl, measurement.wl, 'splines', 1E-4);
    
    %% fluorescence in measurement wl
    fluo.SIF = SIFs(measurement.i_sif);
    fluo.SIFnorm = SIFs(measurement.i_sif) / Eint;
    
end