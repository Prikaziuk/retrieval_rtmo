function results = fit_spectra(measurement, tab, angles, irr_meas, fixed, sensor_in)

    %% here modification of parameters should occur
    tab = helpers.modify_tab_parameters(tab);
        
    %% save prior (x0) values
    tab.x0 = tab.value;
    
    %% initial parameter values, and boundary boxes
    iparams = tab.include;
    params0 = tab.value(iparams);
    lb = tab.lower(iparams);
    ub = tab.upper(iparams);
    
    stoptol = 1E-6;  % we recommend e-6
    opt = optimset('MaxIter', 30, 'TolFun', stoptol, 'DiffMinChange', 1E-2);
    
    %% function minimization
    f = @(params)COST_4SAIL_common(params, measurement,  tab, angles, irr_meas, fixed, sensor_in);

    if any(tab.include)  % analogy of any(include == 1)
        tic
        [paramsout,~,~,exitflag,~,~,Jac]= lsqnonlin(f, params0, lb, ub, opt);
        toc
    else % skip minimization and get resuls of RTMo_lite run with initial  parameters (param0)
        paramsout = params0;
    end
    
    %% best-fitting parameters
    tab.value(tab.include) = paramsout;
    results.parameters = helpers.demodify_parameters(tab.value, tab.variable);

    %% best-fittiing spectra
    [er, rad, reflSAIL, rmse, soil, fluo] = f(paramsout);
    
    results.rmse = rmse;
    results.refl_mod = reflSAIL;
    results.sif = fluo.SIF;
    results.sif_norm = fluo.SIFnorm;
    results.soil_mod = soil.refl_in_meas;
    results.exitflag = exitflag;
    
end
