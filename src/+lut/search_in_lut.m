function rmses = search_in_lut(measured, lut)

    if nargin < 2
        lut = load('lut/lut.mat');
        lut = lut.lut;
    end

    n_to_fit = size(measured.refl, 2);
    rmses = nan(size(lut, 1), n_to_fit);

    for i=1:n_to_fit
        tic
        disp(i)
        spec = measured.refl(:, i)';
        rmse_i = sqrt(nanmean((lut - spec) .^ 2, 2));
        rmses(:, i) = rmse_i;
        toc
    end

    save rmses.mat rmses

end