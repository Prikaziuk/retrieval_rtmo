function h = reflectance_hidden(meas_wl, reflSAIL, refl_meas, j, rmse)

    h = figure('Visible', 'off');  % no way to make it numbered properly
    
    plot(meas_wl, reflSAIL, 'o-')
    hold on
    plot(meas_wl, refl_meas, 'x-')
    title(sprintf('RMSE=%0.4f, spectrum # %d', rmse, j))
    
    legend('RTMo','Measured')
    xlabel('wavelength (nm)')
    ylabel('reflectance')
end