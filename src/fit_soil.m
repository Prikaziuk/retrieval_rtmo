function fit_soil(refl_path, wl_path)
    
%     refl_path = "D:\George\0_Vredepel\2019-07-17\for_retrieval\20190717_vre_plot.csv";
%     wl_path = "D:\George\0_Vredepel\2019-07-17\for_retrieval\wl.csv";

    refl = io.read_dat(refl_path);
    wl = io.read_dat(wl_path);
    refl_soil_meas = refl(wl >= 400 & wl <= 2400, 1);

    stoptol = 1E-6;  % we recommend e-6
    opt = optimset('MaxIter', 30, 'TolFun', stoptol);
    
    names = {'B', 'BSMlat', 'BSMlon', 'SMC'};
    params0 = [0.5 25 45 30];
    lb =      [0   20 40 5];
    ub =      [0.9 40 60 55];
    
    optipar = load(fullfile('..', 'input', 'fluspect_data', 'Optipar2017_ProspectD'));
    optipar = optipar.optipar;
    
    f = @(params) COST4BSM(params, refl_soil_meas, optipar);
%     plot_bsm_limits(f)
    
    params_out = lsqnonlin(f, params0, lb, ub, opt);
    
    [~, refl_bsm] = f(params_out);
    
    figure()
    plot(optipar.wl, refl_bsm, 'o-')
    hold on
    plot(optipar.wl, refl_soil_meas, 'o-')
    legend('BSM', 'measured')
    
    table(names', params_out')
end
    
    
function [er1, refl_bsm] = COST4BSM(params, refl_meas, optipar)

    soilpar.B = params(1);        % soil brightness
    soilpar.BSMlat = params(2);      % spectral shape latitude (range = 20 - 40 deg)
    soilpar.BSMlon = params(3);      % spectral shape longitude (range = 45 - 65 deg)
    soilpar.SMC = params(4);      % soil moisture volume percentage (5 - 55)

    soilemp.SMC   = 25;        % empirical parameter (fixed) [soil moisture content]
    soilemp.film  = 0.015;     % empirical parameter (fixed) [water film optical thickness]

    % soilspec.wl  = optipar.wl;  % in optipar range
    soilspec.GSV  = optipar.GSV;
    soilspec.kw   = optipar.Kw;
    soilspec.nw   = optipar.nw;


    refl_bsm = models.BSM(soilpar, soilspec, soilemp);
    er1 = refl_bsm - refl_meas;
    er1 = er1(~isnan(er1));
end


function plot_bsm_limits(f)
    names = {'B', 'BSMlat', 'BSMlon', 'SMC'};
    change = [0   20 40 5; ...
              0.5 25 45 30; ...
              0.9 40 60 55];
    
    for i=1:4
        params0 = [0.5 25 45 30];
        now = change(:, i);
        subplot(2, 2, i)
        for j=1:3
            params0(i) = now(j);
            [~, refl_bsm] = f(params0);
            plot(400:2400, refl_bsm, 'o-')
            hold on
            axis([400 2400 0 0.5])
        end
        title(names{i})
        legend(cellstr(num2str(now)))
    end
end
