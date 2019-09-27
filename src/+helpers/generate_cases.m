
sensor_name = 'Synergy';
sensor.instrument_name = sensor_name; % 'MSI', 'ASD', '' ...

if isempty(sensor_name)
    sensor.FWHM = 10;
    measured.wl = (400:2400)';
    sensor_name = sprintf('FHWM%g', sensor.FWHM);
end

outdir = fullfile('..', 'measured', 'synthetic', sensor_name);
mkdir(outdir);

angles = struct();
angles.tts = 30;
angles.tto = 0;
angles.psi = 0;

%% read irradiance
path.atmfile = '..\input\radiationdata\FLEX-S3_std.atm';
irradiance = io.read_irradiance(path);

%% subset irradiance to measurements (FWHM, SRF)
fixed = io.read_fixed_input();
spectral = fixed.spectral;
sensors_path = fullfile('..', 'input', 'sensors.xlsx');

instrument = struct();
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

doc = "D:\PyCharm_projects\demostrator\measured\synthetic\cases.csv";
cases = readtable(doc);
default = table2array(cases(1, :));
names = cases.Properties.VariableNames;
cases = table2array(cases);
n_spectra = size(cases, 1);

arr = zeros(size(cases));
for i=1:n_spectra
    par = cases(i, :);
    par(isnan(par)) = default(isnan(par));
    disp(i)
    arr(i, :) = par;
    p = helpers.modify_parameters(par, names);
    [er, rad, refl, rmse, soil, fluo] = COST_4SAIL_common(p, measured, tab, angles, ...
                                                                   irr_meas, fixed, sensor);
    refls(:, i) = refl;
end

figure()
plot(measured.wl, refls, 'o-')

% params = helpers.demodify_parameters(params, tab.variable(iparams));
validation = [names', array2table(arr')];
csvwrite(fullfile(outdir, 'synthetic.csv'), refls)
csvwrite(fullfile(outdir, 'synthetic_wl.csv'), measured.wl)
writetable(validation, fullfile(outdir, 'synthetic_val.csv'))
% writetable(tab_ori, fullfile(outdir, 'synthetic_input.csv'))
% fid = fopen(fullfile(outdir, 'synthetic_comment.txt'), 'w');
% fprintf(fid, 'sensor %s\n', sensor.instrument_name);
% fprintf(fid, 'angles tts=%.2g, tto=%.2g, psi=%.2g\n', angles.tts, angles.tto, angles.psi);
% fprintf(fid, 'n_spectra=%d\n', n_spectra);
% fclose(fid);

path = "D:\PyCharm_projects\demostrator\output\synergy\2019-08-22-211616.xlsx";
% path = "D:\PyCharm_projects\demostrator\output\synergy_prior\2019-08-22-220302.xlsx";
% path = "D:\PyCharm_projects\demostrator\output\synergy_limited\2019-08-22-221257.xlsx";
ret = xlsread(path, 'Output');
ret = ret(2:15, :);
val = readtable("D:\\PyCharm_projects\\demostrator\\measured\\synthetic\\Synergy\\synthetic_val.csv");
names = val.Var1_1;
val = table2array(removevars(val, 'Var1_1'));
n_cases = size(ret, 2);

figure
for i = 1:length(names)
    subplot(5, 3, i)
    plot(1:n_cases, ret(i, :), 'o')
    hold on
    plot(1:n_cases, val(i, :))
    rmse = sqrt(mean((ret(i, :) - val(i, :)) .^ 2));
    title(sprintf("%s, RMSE = %.2g", names{i}, rmse))
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