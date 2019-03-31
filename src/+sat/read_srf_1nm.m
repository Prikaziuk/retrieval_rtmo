function srf = read_srf_1nm(sensors_path, instrument_name, i_srf)
    
    [~, sheets] = xlsfinfo(sensors_path);
    assert(any(strcmp(instrument_name, sheets)), ['instrument_name `%s` '...
        'does not correspond to any of sheet names in `%s`.'], instrument_name, sensors_path)

    [num, ~, ~] = xlsread(sensors_path, instrument_name);

    ncol = size(num, 2);
    assert(mod(ncol, 2) == 0, 'odd number of columns in SRFs. Expected even: (wl, response) * n_bands')

    i_wl = 1:2:ncol;
    i_resp = 2:2:ncol;
    % now length(wl) == length(resp) == default_n_bands
    
    % if some bands are missing
    i_wl = i_wl(i_srf);
    i_resp = i_resp(i_srf);
    
    srf.resp = num(:, i_resp);
    srf.wl = num(:, i_wl);
    
end

% split bands into non-intersectig groups => matrix multiplication refl * srf is faster
