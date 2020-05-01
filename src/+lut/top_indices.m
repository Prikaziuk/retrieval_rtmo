function ind = top_indices(i, meas_refl, lut_refl)

    if mod(i, 100000) == 0
        fprintf('done %i / %i  pixels\n', i, length(meas_refl))
    end

    if size(meas_refl, 2) ~= size(lut_refl, 2)
        meas_refl = meas_refl';
    end
    
    rmses = sqrt(mean((meas_refl(i, :) - lut_refl) .^ 2, 2));
    
    [~, I] = sort(rmses);
    ind = [1, I(1:10)'];  % top 10  % 1 for 3d dim of lut_spec
%     rmses = rmses(ind);

end

