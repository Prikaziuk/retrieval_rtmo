function generate_synthetic(sensor_name, n_spectra, noise_times)
    
    if nargin == 2
        noise_times = 0;
    end

    sensor.instrument_name = sensor_name; % 'MSI', 'ASD', '' ...

    if isempty(sensor_name)
        sensor.FWHM = 10;
        measured.wl = (400:2400)';
        sensor_name = sprintf('FHWM%g', sensor.FWHM);
    end
    
    outdir = fullfile('..', 'measured', 'synthetic', sensor_name);
    mkdir(outdir);

    angles.tts = 45;  % 30
    angles.tto = 0;
    angles.psi = 0;

    %% read irradiance
    path.atmfile = '..\input\radiationdata\FLEX-S3_std.atm';
    irradiance = io.read_irradiance(path);

    %% subset irradiance to measurements (FWHM, SRF)
    fixed = io.read_fixed_input();
    spectral = fixed.spectral;
    sensors_path = fullfile('..', 'input', 'sensors.xlsx');

    if any(strcmp(sensor.instrument_name, fixed.srf_sensors))  % to srf
        instrument.wl = spectral.wlP';
        instrument.FWHM = ones(size(instrument.wl));
        instrument = struct2table(instrument);
        sensor.i_srf = 1: size(xlsread(sensors_path, sensor.instrument_name), 2) / 2;
        sensor.srf = sat.read_srf_1nm(sensors_path, sensor.instrument_name, sensor.i_srf); 
        irr_meas = to_sensor.irradiance2sensor_wl(irradiance, instrument,  spectral.wlP');
        measured.i_sif = ones(size(spectral.wlF'));
        measured.wl = nanmean(sensor.srf.wl)';
    else
        if isempty(sensor.instrument_name)                     % to custom FWHM
            instrument.wl = measured.wl;
            instrument.FWHM = repmat(sensor.FWHM, size(measured.wl));
            instrument = struct2table(instrument);
        else                                                   % to built-in FWHM      
            instrument_name = sensor.instrument_name;
            [~, sheets] = xlsfinfo(sensors_path);
            assert(any(strcmp(instrument_name, sheets)), ['instrument_name `%s` '...
                'does not correspond to any of sheet names in `%s`.\n' ...
                'If you want to use your FWHM - do not provide any value as instrument_name'], ...
                instrument_name, sensors_path)
            instrument = readtable(sensors_path, 'sheet', instrument_name);
            [wl, ~] = parse_instrument(instrument);
            measured.wl = wl';
        end
        irr_meas = to_sensor.irradiance2sensor_wl(irradiance, instrument,  measured.wl);
        measured.i_sif = (measured.wl >= spectral.wlF(1)) & (measured.wl <= spectral.wlF(end));
    end

    measured.refl = zeros(size(measured.wl));
    measured.i_fit = ones(size(measured.wl));
    sensor.hot = 0.05;
    sensor.Rin = '';

    %% read parameters 
    input_path = 'Input_data.xlsx';

    tab_ori = io.read_input_sheet(input_path);
    tab = helpers.modify_tab_parameters(tab_ori);
    tab.x0 = tab.value;
    iparams = tab.include;
    lb = tab.lower(iparams);
    ub = tab.upper(iparams);
    rng(0, 'twister')  % setting seed == 0
    params = (ub-lb) .* rand(sum(iparams), n_spectra) + lb;

    refls = zeros(length(measured.wl), n_spectra);
    for i=1:n_spectra
        disp(i)
        p = params(:, i);
        [er, rad, refl, rmse, soil, fluo] = COST_4SAIL_common(p, measured, tab, angles, ...
                                                                       irr_meas, fixed, sensor);
        refls(:, i) = refl;
    end
    
  
    % SNR noise (Synergy and OLCI)
%     snr_synergy = csvread("D:\PyCharm_projects\gsa_rtmo_6S\for_paper\retrievability\SNRs\SNRs_S3A.csv", 0, 1);
%     single_noise = refls ./ snr_synergy(1:size(refls, 1));
%     %noise = single_noise * noise_times; constant % of specific noise
%     noise = rand(size(refls)) .* single_noise * noise_times;
    % constant noise up to certain % from measured
    single_noise = (refls * noise_times / 100);
    noise = rand(size(refls)) .* single_noise * 2;  % *2 because mean(rand) = 0.5
    
    csvwrite(fullfile(outdir, 'synthetic_toa.csv'), refls)
    csvwrite(fullfile(outdir, 'synthetic_noise.csv'), noise)
    refls = refls + noise;
    
    figure()
    plot(measured.wl, refls, 'o-')
    
    params = helpers.demodify_parameters(params, tab.variable(iparams));
    validation = [tab.variable(iparams), array2table(params)];

    csvwrite(fullfile(outdir, 'synthetic.csv'), refls)
    csvwrite(fullfile(outdir, 'synthetic_wl.csv'), measured.wl)
    writetable(validation, fullfile(outdir, 'synthetic_val.csv'))
    writetable(tab_ori, fullfile(outdir, 'synthetic_input.csv'))
    fid = fopen(fullfile(outdir, 'synthetic_comment.txt'), 'w');
    fprintf(fid, 'sensor %s\n', sensor.instrument_name);
    fprintf(fid, 'angles tts=%.2g, tto=%.2g, psi=%.2g\n', angles.tts, angles.tto, angles.psi);
    fprintf(fid, 'n_spectra=%d\n', n_spectra);
    fclose(fid);
end


function [wl, fwhm] = parse_instrument(instrument)
    [nrow, ncol] = size(instrument);
    if ncol ~= 2
        wl = [];
        fwhm = [];
        for i=1:nrow
            domain = instrument(i,:);
            wl_domain = domain.start : domain.SSI : domain.stop;
            fwhm_domain = repmat(domain.FWHM, size(wl_domain));
            wl = [wl, wl_domain];
            fwhm = [fwhm, fwhm_domain];
        end
    else
        wl = instrument.wl;
        fwhm = instrument.FWHM;
    end
end