function [Esun_, Esky_, E_int] = transmittances2irradiance(irr_measured, rdd, rsd, Rin)   
    
    if ismember('t', fieldnames(irr_measured))
        t = irr_measured.t;
        assert((size(t, 1) == size(rdd, 1)) && (size(t, 1) == size(rsd, 1)), ... 
            'T18 and reflectance factors size mismatch, something is not interpolated')
        irr_measured.sun = pi * t(:, 1) .* t(:, 4);
        irr_measured.sky = pi ./ (1 - t(:, 3) .* rdd) .* (t(:, 1) .* (t(:, 5) + t(:, 12) .* rsd));
    end

    Esun_ = irr_measured.sun;
    Esky_ = irr_measured.sky;
    
    % replace zeros and NaNs by small values
    Esun_   = max(nanmean(Esun_)*1E-3,Esun_);
    Esky_   = max(nanmean(Esky_)*1E-3,Esky_);
    E_int = 1E-3 * Sint(Esun_ + Esky_, irr_measured.wl);
    
    if ~isempty(Rin)
        fSun = Esun_ / E_int;
        fSky = Esky_ / E_int;
        Esun_ = fSun * Rin;
        Esky_ = fSky * Rin;
    end
    
end


function int = Sint(y,x)

    % Simpson integration
    % x and y must be any vectors (rows, columns), but of the same length
    % x must be a monotonically increasing series
    
    % WV Jan. 2013, for SCOPE 1.40
    
    nx   = length(x);
    if size(x,1) == 1
        x = x';
    end
    if size(y,1) ~= 1
        y = y';
    end
    step = x(2:nx) - x(1:nx-1);
    mean = .5 * (y(1:nx-1) + y(2:nx));
    int  = mean * step;
end
