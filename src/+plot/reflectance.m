function reflectance(meas_wl, reflSAIL, refl_meas, j, rmse)

    figure(j * 1e3)  % e3 to prevent overlapping with hidden plots
    
    plot(meas_wl, reflSAIL, 'o-')
    hold on
    plot(meas_wl, refl_meas, 'x-')
    title(sprintf('RMSE=%0.4f, spectrum # %d', rmse, j))
    
    legend('RTMo','Measured')
    xlabel('wavelength (nm)')
    ylabel('reflectance')
end