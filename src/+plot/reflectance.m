function reflectance(meas_wl, reflSAIL, refl_meas, j, rmse, reflSAIL_std)
    
    figure(j * 1e2)  % e3 to prevent overlapping with hidden plots
    
    if nargin < 6
        reflSAIL_std = zeros(size(reflSAIL));
    end
    
    if size(reflSAIL, 2) ~= 1
        reflSAIL = reflSAIL(:, j);
        refl_meas = refl_meas(:, j);
        rmse = rmse(j);
        reflSAIL_std = reflSAIL_std(:, j);
    end
    
    errorbar(meas_wl, reflSAIL, reflSAIL_std)
    hold on
    plot(meas_wl, refl_meas, 'x-')
    legend('RTMo','Measured')       
    title(sprintf('RMSE=%0.4f, spectrum # %d', rmse, j))
    xlabel('wavelength (nm)')
    ylabel('reflectance')
end