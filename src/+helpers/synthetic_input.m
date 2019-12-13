function [measured, tab, angles, irr_meas, fixed, sensor] = synthetic_input()

    input_path = 'Input_data.xlsx';
    
    fprintf('reading `Input` sheet for parameters and ranges\n')
    tab = io.read_input_sheet(input_path);
    
    fprintf('reading `Filenames` sheet for sensor data and angles\n')
    tab_files = io.read_filenames_sheet(input_path, 'Filenames');
    sensor = io.table_to_struct(tab_files, 'sensor');

    fprintf('`%s` sensor\n', sensor.instrument_name) 
    angles.tts = sensor.tts;
    angles.tto = sensor.tto;
    angles.psi = sensor.psi;

    %% read irradiance
    path.atmfile = fullfile('..', 'input', 'radiationdata', 'FLEX-S3_std.atm');
    irradiance = io.read_irradiance(path);

    %% subset irradiance to measurements (FWHM, SRF)
    fixed = io.read_fixed_input();
    spectral = fixed.spectral;
    sensors_path = fullfile('..', 'input', 'sensors.xlsx');

    if any(strcmp(sensor.instrument_name, fixed.srf_sensors))  % to srf
        instrument.wl = spectral.wlP';
        instrument.FWHM = ones(size(instrument.wl));
        instrument = struct2table(instrument);
        irr_meas = to_sensor.irradiance2sensor_wl(irradiance, instrument,  spectral.wlP'); % 1nm of PROSPECT
        [~, band_wl, sensor.i_srf] = sat.read_bands_sheet(input_path);
        sensor.srf = sat.read_srf_1nm(sensors_path, sensor.instrument_name, sensor.i_srf); 
        measured.i_sif = ones(size(spectral.wlF'));
        measured.wl = band_wl;
    else
        if isempty(sensor.instrument_name)                     % to custom FWHM
            measured.wl = sensor.wlmin : sensor.wlmax;
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
%             measured.wl = wl';
            measured.wl = wl;
        end
        irr_meas = to_sensor.irradiance2sensor_wl(irradiance, instrument,  measured.wl);
        measured.i_sif = (measured.wl >= spectral.wlF(1)) & (measured.wl <= spectral.wlF(end));
    end

    measured.refl = zeros(size(measured.wl));
    measured.i_fit = ones(size(measured.wl));
end


function [wl, fwhm] = parse_instrument(instrument)
    [nrow, ncol] = size(instrument);
    
%     if ncol ~= 2
    if any(strcmp(instrument.Properties.VariableNames, 'SSI'))
        wl = [];
        fwhm = [];
        for i=1:nrow
            domain = instrument(i,:);
            wl_domain = domain.start : domain.SSI : domain.stop;
            fwhm_domain = repmat(domain.FWHM, size(wl_domain));
            wl = [wl, wl_domain];
            fwhm = [fwhm, fwhm_domain];
        end
        wl = wl';
    else
        wl = instrument.wl;
        fwhm = instrument.FWHM;
    end
end
