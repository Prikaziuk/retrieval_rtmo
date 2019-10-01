function srf = read_srf_1nm(sensors_path, instrument_name, i_srf)
    
    [~, sheets] = xlsfinfo(sensors_path);
    assert(any(strcmp(instrument_name, sheets)), ['instrument_name `%s` '...
        'does not correspond to any of sheet names in `%s`.'], instrument_name, sensors_path)

    [num, ~, ~] = xlsread(sensors_path, instrument_name);

    ncol = size(num, 2);
    assert(mod(ncol, 2) == 0, 'odd number of columns in SRFs. Expected even: (wl, response) * n_bands')
    n_bands = ncol / 2;
    assert(n_bands >= length(i_srf), ['The number of spectral response functions in `%s` file is '...
        'less then the number of bands you provided on `Bands` sheet of `Input_data.xslx`.\n'... 
        'Did you set `Bands` sheet correctly? Is `instrument_name` correct?'], sensors_path)
    if n_bands > length(i_srf)
        omitted_bands = setdiff(1:n_bands, i_srf);
        warning(['%d bands (# %s) from `%s` were excluded.\n' ...
            'Ignore this warning if it is the desired behaviour'], ...
            length(omitted_bands), num2str(omitted_bands), instrument_name)
    end
    
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
