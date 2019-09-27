% function [er,params0,params1,spectral,leafbio,canopy,rad,reflSAIL_all,J,fluorescence]= master
%% start fresh
close all
clear all

%% read fixed input

fixed = io.read_fixed_input();

spectral = fixed.spectral;

%% read input file
sensors_path = fullfile('..', 'input', 'sensors.xlsx');
input_path = 'Input_data.xlsx';

tab = io.read_input_sheet(input_path);

tab_files = io.read_filenames_sheet(input_path, 'Filenames');
path = io.table_to_struct(tab_files, 'path');
sensor = io.table_to_struct(tab_files, 'sensor');
sun = io.table_to_struct(tab_files, 'sun');

path.input_path = input_path;


%% read reflectance
measured = io.read_measurements(path);

if ~isempty(path.soilfile)
    warning('Reading soil spectra from `%s` file', path.soilfile)
    measured.soil_refl = load(path.soilfile);
end

% mask atmospheric window
% ASD
% i_noise = (measured.wl > 1350 & measured.wl < 1430) | (measured.wl > 1805 & measured.wl < 1975) | measured.wl > 2400;
% i_noise = measured.wl > 1800;
% measured.refl(i_noise, :) = nan;

% HyPlant
% i_noise = (measured.wl > 907 & measured.wl < 938) | (measured.wl > 1988 & measured.wl < 2037);
% measured.refl(i_noise, :) = nan;

% for propagation of uncertainty we need the initial uncertainty
if isempty(measured.std)
    measured.std = ones(size(measured.refl)) * 0.01;  % there was stdP but no point yet
end


%% read irradiance
irradiance = io.read_irradiance(path);

%% subset irradiance to measurements (FWHM, SRF)

if any(strcmp(sensor.instrument_name, fixed.srf_sensors))  % to srf
    instrument.wl = spectral.wlP';
    instrument.FWHM = ones(size(instrument.wl));
    instrument = struct2table(instrument);
    [~, ~, sensor.i_srf] = sat.read_bands_sheet(input_path);
    assert(length(measured.wl) == length(sensor.i_srf), ['Wrong `instrument_name` or '... 
        'wrong number of bands (`your_names`) at `Bands` sheet.\n'... 
        '[different number of measured wavelength and srf]'], '')
    sensor.srf = sat.read_srf_1nm(sensors_path, sensor.instrument_name, sensor.i_srf); 
    irr_meas = to_sensor.irradiance2sensor_wl(irradiance, instrument,  spectral.wlP');
    measured.i_sif = ones(size(spectral.wlF'));
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
    end
    irr_meas = to_sensor.irradiance2sensor_wl(irradiance, instrument,  measured.wl);
    measured.i_sif = (measured.wl >= spectral.wlF(1)) & (measured.wl <= spectral.wlF(end));
end

%% other sensor-related input
measured.i_fit = (measured.wl >= sensor.wlmin) & (measured.wl <= sensor.wlmax);

c = sensor.c;
if c == -999
    c = 1:size(measured.refl, 2);
end

angles_single = helpers.get_angles(sensor, sun);
if sensor.timeseries
    warning(['You have activated `time_series` mode.\n'... 
        'Parameters will be read from `TimeSeries` sheet. ' ... 
        'If you did not provide anything there fixed values from `Filenames` will be used.'], '')
    tab_ts = io.read_filenames_sheet(input_path, 'TimeSeries');
    path_ts = io.table_to_struct(tab_ts, 'path_ts');
    n_spectra = size(measured.refl, 2);
    sensor.angles_ts = ts.get_angles_ts(sensor, sun, path_ts, n_spectra);
    sensor.Rin_ts = ts.get_Rin_ts(path_ts.Rin_path, sensor.Rin, n_spectra);
end
%% preallocate output structures

n_params = length(tab.variable);
n_spectra = length(c);
n_wl = length(measured.wl);
n_wlF = sum(measured.i_sif);
n_fit_wl = sum(measured.i_fit);

[parameters, parameters_std] = deal(zeros(n_params, n_spectra));
rmse_all = zeros(1, n_spectra);
figures = gobjects(n_spectra,1);
[refl_mod, refl_soil] = deal(zeros(n_wl, n_spectra));
[sif_rad, sif_norm] = deal(zeros(n_wlF, n_spectra));  % n_wlF
J_all = zeros(n_fit_wl, n_params, n_spectra);

%% start saving
q = parallel.pool.DataQueue;
if isunix
    path = io.create_output_folder(input_path, path, tab.variable);

    tmp_zeros_res.rmse = rmse_all;
    tmp_zeros_res.parameters = parameters;
    tmp_zeros_unc.std_params = parameters_std;

    tmp_zeros_res.refl_mod = refl_mod;
    tmp_zeros_res.soil_mod = refl_soil;
    tmp_zeros_res.sif = sif_rad;
    tmp_zeros_res.sif_norm = sif_norm;

    tmp_zeros_meas.refl = refl_mod;
    tmp_zeros_meas.wl = measured.wl;
    tmp_zeros_meas.i_sif = measured.i_sif;

    io.save_output_csv(0, tmp_zeros_res, tmp_zeros_unc, tmp_zeros_meas, path)
    afterEach(q, @(x) io.save_output_csv(x{1}, x{2}, x{3}, x{4}, path));
else
    path = io.create_output_file(input_path, path, measured, tab.variable, n_spectra);
    afterEach(q, @(x) io.save_output_j(x{1}, x{2}, x{3}, x{4}, path));
end
%% safely writing data from (par)for loop
% afterEach(q, @(x) plot.plot_j(x{1}, x{2}, x{3}, x{4}, tab));

%% parallel
%% uncomment these lines, select N_proc you want, change for-loop to parfor-loop
N_proc = 3;
if isempty(gcp('nocreate'))
%     prof = parallel.importProfile('local_Copy.settings');
%     parallel.defaultClusterProfile(prof);
    parpool(N_proc, 'IdleTimeout', Inf);
end

%% time estimation
if ~exist('N_proc', 'var')
    N_proc = 1;
end
eta = n_spectra * 10 / (N_proc * 60);
warning(['You have %d spectra and asked for %d CPU(s). '...
    'Fitting will take about %.2f min (~10 s / spectra / CPU)'], n_spectra, N_proc, eta)

%% fitting
%% change to parfor if you like
parfor j = c
     fprintf('%d / %d', j, length(c))
    %% this part is done like it is to enable parfor loop
    measurement = struct();
    measurement.refl = measured.refl(:,j);
    measurement.i_fit = measured.i_fit;
    measurement.wl = measured.wl;
    measurement.i_sif = measured.i_sif;
    if isfield(measured, 'soil_refl')
%         measurement.soil_refl = measured.soil_refl;
        measurement.soil_refl = interp1(measurement.wl, measured.soil_refl, spectral.wlP, 'splines', 1E-4);
    end
    
    angles = angles_single;
    sensor_in = sensor;
    if sensor_in.timeseries
        [angles, sensor_in.Rin] = ts.ts_for_parfor(j, sensor_in);
    end

    results_j = fit_spectra(measurement, tab, angles, irr_meas, fixed, sensor_in);

    %% record to keep in the workspace

    parameters(:, j) = results_j.parameters;
    rmse_all(j) = results_j.rmse;
    refl_mod(:,j) = results_j.refl_mod;
    refl_soil(:,j)  = results_j.soil_mod;
    sif_rad(:,j)  = results_j.sif;
    sif_norm(:,j) = results_j.sif_norm;

    %% uncertainty in parameters
    measurement.std = measured.std(:, j);
    
    uncertainty_j = propagate_uncertainty(results_j.parameters, measurement, tab, angles,  irr_meas, fixed, sensor_in);
    
    parameters_std(:, j) = uncertainty_j.std_params;
    J_all(:,:,j) = uncertainty_j.J;
    
    figures(j) = plot.reflectance_hidden(measurement.wl, results_j.refl_mod, measurement.refl, j, results_j.rmse);
    
    %% send data to write and plot
%     send(q, {j, results_j, uncertainty_j, measurement})  
%     send(q, {j, results_j.rmse, results_j.parameters, uncertainty_j})
%     io.save_output_csv(rmse_all, parameters, parameters_std, path)

end

%% if your parfor does not fail try disabling send
io.save_output(path, rmse_all, parameters, parameters_std, measured.refl, refl_mod, refl_soil, sif_norm, sif_rad)


if ~isempty(path.validation)
    graph_name = [path.simulation_name, ' ', sensor.instrument_name];
    n_val = size(measured.val, 2) - 1;
    if length(c) < n_val
        % this ploting is not designed for one value but we hack
        % it to do so for you
        measured.val = measured.val(1, [1 c + 1]);
        parameters = parameters(:, c);    
    end
    plot.modelled2measured(parameters, tab, measured.val, graph_name)
end

%% see figures you want (replace c(1) with the spectrum number)
set(figures(c(1)), 'Visible', 'on')

%% plot from the output xlsx file

% plot.replot_all(your_output_xlsx_file, your_validation_path)

