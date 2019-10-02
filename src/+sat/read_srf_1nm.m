function srf = read_srf_1nm(sensors_path, instrument_name, i_srf)
    
    [~, sheets] = xlsfinfo(sensors_path);
    assert(any(strcmp(instrument_name, sheets)), ['instrument_name `%s` '...
        'does not correspond to any of sheet names in `%s`.'], instrument_name, sensors_path)

    [num, txt, ~] = xlsread(sensors_path, instrument_name);

    ncol = size(num, 2);
    assert(mod(ncol, 2) == 0, 'odd number of columns in SRFs. Expected even: (wl, response) * n_bands')
    n_bands = ncol / 2;
    assert(n_bands >= length(i_srf), ['The number of spectral response functions in `%s` file is '...
        'less then the number of bands you provided on `Bands` sheet of `Input_data.xslx`.\n'... 
        'Did you set `Bands` sheet correctly? Is `instrument_name` correct?'], sensors_path)
    
    i_wl = 1:2:ncol;
    i_resp = 2:2:ncol;
    % now length(wl) == length(resp) == default_n_bands
    
    if n_bands > length(i_srf)
        omitted_bands_i = setdiff(1:n_bands, i_srf);
        omitted_bands = txt(1, i_wl(omitted_bands_i));
        warning(['%d band(s) (named %s in `../input/sensors.xlsx`) from `%s` were excluded.\n' ...
            'Ignore this warning if this is the desired behaviour'], ...
            length(omitted_bands), strjoin(omitted_bands, ', '), instrument_name)
    end
    
    
    % if some bands are missing
    i_wl = i_wl(i_srf);
    i_resp = i_resp(i_srf);
    
    srf.resp = num(:, i_resp);
    srf.wl = num(:, i_wl);
    
end

% split bands into non-intersectig groups => matrix multiplication refl * srf is faster
