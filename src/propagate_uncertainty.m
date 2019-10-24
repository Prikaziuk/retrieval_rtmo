function uncertainty = propagate_uncertainty(paramsout, measurement, tab, angles, irr_meas, fixed, sensor)    

    tab.value = paramsout;
    
    %% here modification of parameters should occur
    tab = helpers.modify_tab_parameters(tab);
        
    %% save prior (x0) values
    tab.x0 = tab.value;
    
    tab.include = true(numel(tab.include), 1);
    f_jac = @(params)COST_4SAIL_common(params, measurement, tab, angles, irr_meas, fixed, sensor);
    J = clc_jacobian(tab.value, f_jac);
    J = J(measurement.i_fit,:);

    % propagation of uncertainty in refl to uncertainty in variables?
    meas_std_fit = measurement.std(measurement.i_fit);
    meas_std_fit(isnan(meas_std_fit)) = 0;
    std = abs((inv(J.'*J)) * J.' * meas_std_fit);

    % propagation of uncertainty in variables to uncertainty in reflectance
    in_covar_mat = diag(tab.uncertainty);  % we do not have and do not need covariances
    out_covar_mat = J * in_covar_mat * J';
    std_refl = diag(out_covar_mat);  % on diagonal var are located

    uncertainty.J = J;
    uncertainty.std_params = std;
    uncertainty.std_refl = std_refl;
    
%     figure(c*1000)
% %     plot(measurement.wl(measurement.i_fit), std_j)
%     errorbar(measurement.wl(measurement.i_fit), reflSAIL(measurement.i_fit), std_j)
%     ylim([0, 1])
end


function J = clc_jacobian(x, f)
    n = length(x); 
    [~, ~, fx] = f(x);
    step = 1e-6; 
    J = zeros(length(fx), n);

    for k=1:n
       xstep = x;
       xstep(k)=x(k) + step;
       [~, ~, fxstep] = f(xstep); 
       J(:,k)= (fxstep - fx) ./ step;
    end
end