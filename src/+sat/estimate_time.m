function estimate_time(refl, i_row, i_col)
    
    if nargin == 3
        refl = refl(i_row, i_col);
    end
    
    SEC_PER_PIXEL = 3;

    [x, y, b] = size(refl);
    meas_2d = zeros(x * y, b);
    valid = true(x * y, 1);
    for i=1:x*y
        [r, c] = ind2sub([x y], i);
        pixel = refl(r, c, :);
        meas_2d(i, :) = pixel;
        if all(isnan(pixel))
            valid(i) = false;
        end
    end
    
    n_valid = sum(valid);
    warning('found %d valid pixels, retrieval will take at least %0.2f hs (%0.0f s / pixel / CPU)', ...
        n_valid, n_valid * SEC_PER_PIXEL / 3600, SEC_PER_PIXEL)
end