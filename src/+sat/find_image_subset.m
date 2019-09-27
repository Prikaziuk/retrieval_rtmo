function [i_row, i_col] = find_image_subset(sensor, measured, x, y)

    pix_lat = sensor.pix_lat;
    pix_lon = sensor.pix_lon;
    K = ceil(sensor.K);
    lat = measured.lat;
    lon = measured.lon;
    
    % check that kernel size is valid, i.e. odd integer
    if mod(K, 2) == 0
        disp('Why did you provide even kernel size N? I will add 1 myself to make it odd.')
        K = K + 1;
    end

    warning(['Only a part of image (%1$d x %1$d around [%2$0.4f, %3$0.4f]) will be fit. ', ...
            'If you want to fit ALL pixels of the image set K == 0'], K,  pix_lat, pix_lon)
    
        
    % find indices to subset refl
    if size(lat, 2) == 1  % goes together with lon
        [~, i_lat] = min(abs(lat - pix_lat));
        [~, i_lon] = min(abs(lon - pix_lon));
        if (size(lat, 1) == x) && (size(lon, 1) == y)
            pix_x = i_lat;
            pix_y = i_lon;
        elseif (size(lon, 1) == x) && (size(lat, 1) == y)
            pix_x = i_lon;
            pix_y = i_lat;
        else
            error('Cannot understand lat/lon to row/col relation')
        end
    else
        pix = [pix_lat, pix_lon];
        coord = [lat(:), lon(:)];
        i_pix = dsearchn(coord, pix);
        [pix_x, pix_y] = ind2sub([x, y], i_pix);
    end
    
    % find coordinates of the subset
    step = (K - 1) / 2;
    i_row = max(pix_x - step, 1) : min(pix_x + step, x);
    i_col = max(pix_y - step, 1) : min(pix_y + step, y);
    % intentionally out-of-bound indices are left here for pretty .nc file 
%     i_row = (pix_x - step) : (pix_x + step);
%     i_col = (pix_y - step) : (pix_y + step);
end