function srf2target_wl(sheet_name, wl_target, paired)

    hi_res_sensors_path = fullfile('../input/custom_sensors.xlsx');
    hi_res = xlsread(hi_res_sensors_path, sheet_name);
    % wl_target = 400:1:2400;

    if paired
        % expected structure of sheet [repmat([wl, response], 1, n_bands)]. See details in the follwing.
        % hi_res = xlsread(hi_res_sensors_path, 'OLCI_paired_hi');
        ncol = size(hi_res, 2);
        assert(mod(ncol, 2) == 0, 'odd number of columns in SRFs. Expected even: [(wl, response) * n_bands]')
        wl = hi_res(:, 1:2:ncol);
        resp = hi_res(:, 2:2:ncol);
        n_bands = size(resp, 2);
    else
        % expected structure of sheet [wl, repmat(response, 1, n_bands)]. See details in the follwing.
        % hi_res = xlsread(hi_res_sensors_path, 'SLSTR_not_paired_hi');
        ncol = size(hi_res, 2);
        assert(mod(ncol, 2) == 1, 'even number of columns in SRFs. Expected odd: [wl, (response) * n_bands]')
        wl = hi_res(:, 1);
        resp = hi_res(:, 2:end);
        n_bands = size(resp, 2);
        wl = repmat(wl, 1, n_bands);
    end

    %% subset to target wavelength

    out_str = repmat(struct('srf',1), n_bands, 1);
    for i = 1:n_bands
        c_wl = wl(:, i);
        c_resp = resp(:, i);
        i_nan = isnan(c_wl) | isnan(c_resp);
        c_wl = c_wl(~i_nan);
        c_resp = c_resp(~i_nan);
        i_wlP_min = find(wl_target >= floor(c_wl(1)), 1);
        i_wlP_max = find(wl_target <= ceil(c_wl(end)), 1, 'last');
        c_wlP = wl_target(i_wlP_min:i_wlP_max);
        resp_prospect = interp1(c_wl, c_resp, c_wlP, 'splines', NaN);
%         sprintf('%d / %d', length(resp_prospect(~isnan(resp_prospect))), length(resp_prospect))

        out_str(i).srf = [c_wlP; resp_prospect]';
    end

    n_max = max(arrayfun(@(x) length(x.srf), out_str));
    
    %% plot results
    figure(100)
    clf
    for i = 1 : n_bands
        srf = out_str(i).srf;
        srf(end+1:n_max, :) = nan;
        out_str(i).srf = srf;
        h1 = plot(out_str(i).srf(:, 1), out_str(i).srf(:, 2), 'x');
        hold on
    end

    h2 = plot(wl, resp);
    legend([h1(1), h2(1)], 'target resolution', 'original resolution')
    title(sprintf('results of bands from sheet `%s` interpolation', sheet_name), 'Interpreter', 'none')
    
    %% make output
    % prepare a table that looks like repmat([wl, response], 1, n_bands) with which we work further.
    % i_srf parameter in main_sat.m is the band_number (column number) 
    to_write = struct2array(out_str);
    
    to_w_cell = num2cell(to_write);
    names = repmat({'wl', 'resp'}, 1, n_bands);
    band_names = repelem(arrayfun(@(n) sprintf('band_%d', n), 1:n_bands, 'UniformOutput', false), 2);
    list = [band_names; names; to_w_cell];
    
    %% to save or not to save
    new_sheet = [sheet_name, '_int'];
    [~,sheets] = xlsfinfo(hi_res_sensors_path);
    assert(~any(strcmp(new_sheet, sheets)), ['There is already a sheet named `%s` in `%s`. '...
        'Solve (rename, delete) it!\nThe results of interpolation were not saved.\n' ...
        'If you are happy with the results copy them to `../input/sensors.xlsx` and use.'], ...
        new_sheet, hi_res_sensors_path)
    xlswrite(hi_res_sensors_path, list, [sheet_name, '_int'])

end

