function create_sensor_from_fwhm(input_path)
    % example input_path in ../input/bands_from_fwhm.xlsx
    centre_fwhm = xlsread(input_path, 'fwhm');

    n_bands = size(centre_fwhm, 1);
    
    %% simulating gaussian response
    out = struct();
    for i=1:n_bands
        centre = centre_fwhm(i, 1);
        fwhm = centre_fwhm(i, 2);
        wl_range = round((centre-fwhm * 2) : (centre+fwhm * 2));
        response = gaussian_fwhm(wl_range, centre, fwhm);
        out.(sprintf('band%d', i)) = [wl_range', response];
    end
    
    %% filling with NaNs to make all equal length
    n_longest = max(structfun(@length, out));
    tab = table();
    for i=1:n_bands
        band_i = out.(sprintf('band%d', i));
        n_wl = length(band_i);
        tab.(sprintf('lambda%d', i)) = [band_i(:, 1); nan(n_longest - n_wl , 1)];
        tab.(sprintf('response%d', i)) = [band_i(:, 2); nan(n_longest - n_wl , 1)];
    end

    writetable(tab, input_path, 'Sheet', 'sensor')
    
    %% plot bands
    figure()
    legend_cell = cell(1, n_bands);
    for i=1:n_bands
        band_i = out.(sprintf('band%d', i));
        plot(band_i(:, 1), band_i(:, 2))
        hold on
        legend_cell{i} = sprintf('band%d', i);
    end
    legend(legend_cell, 'location', 'bestoutside')
%     xticks(400:50:900)
%     axis([400 900 0 1])
%     title('Altum camera')
end

function dist = gaussian_fwhm(wl, centre, fwhm)
    % simulation of gaussian distribution
    % source: Liu, Bo (2009): Simulation of EO-1 Hyperion Data from ALI Multispectral Data Based on the Spectral Reconstruction Approach
        
    nWl = length(wl);
    dist = zeros(nWl, 1);
    sigma = fwhm / (2 * sqrt(2 * log(2)));
    
    for i = 1 : nWl
        num = (centre - wl(i)) ^ 2;
        denom = 2 * (sigma ^ 2);
        dist(i) = exp(-1 * (num / denom));
    end
end

