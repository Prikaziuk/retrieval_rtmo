function ind = top_indices_angles(i, meas_refl, lut3d, sza1d, angle_info)

    if mod(i, 100000) == 0
        fprintf('done %i / %i  pixels\n', i, length(meas.refl))
    end
    
    [~, i_dim] = min(abs(angle_info.tts - sza1d(i)));
    lut_refl = lut3d(:, :, i_dim);
    
    if size(meas_refl, 2) ~= size(lut_refl, 2)
        meas_refl = meas_refl';
    end
    
    rmses = sqrt(mean((meas_refl(i, :) - lut_refl) .^ 2, 2));
    
    [~, I] = sort(rmses);
    ind = [i_dim, I(1:10)'];  % top 10
%     rmses = rmses(ind);

end

