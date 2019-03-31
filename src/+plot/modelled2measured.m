function modelled2measured(modelled, modelled_names, measured)

    measured_names = table2array(measured(:, 1));
    measured(:, 1) = [];
    measured = table2array(measured);

    [vars, i_meas, i_mod] = intersect(measured_names, modelled_names, 'stable');
    
    n_plots = length(vars);
    n_row = 1;
    if n_plots > 4
        n_row = 2;
    end
    n_col = round(n_plots / n_row);
    
    figure(100000)
    n_spectra = size(measured, 2);
    cmap=colormap(jet(n_spectra));
    for i = 1:length(vars)
        subplot(n_row, n_col, i)
        mod = modelled(i_mod(i), :);
        meas = measured(i_meas(i), :);
        scatter(meas, mod, 100, cmap)
        for j = 1:n_spectra
            text(meas(j), mod(j), num2str(j), 'HorizontalAlignment', 'center')
            hold on
        end
        rmse = sqrt(nanmean((meas-mod) .^ 2));
        title(sprintf('%s: rmse=%.2f', vars{i}, rmse))
        hold on
        refline(1, 0)
        hold off
    end
    
%     caxis([0 size(measured, 2)])
%     hp4 = get(subplot(n_row, n_col, i),'Position');
%     colorbar('Position', [hp4(1)+hp4(3)+0.01  hp4(2)  0.1  hp4(2)+hp4(3)*2.1])

end