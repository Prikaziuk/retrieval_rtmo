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