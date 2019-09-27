%function [er,params0,params1,spectral,leafbio,canopy,rad,reflSAIL_all,J,fluorescence]= master
%% start fresh
close all
clear all

%% fixed input (constants)

fixed = io.read_fixed_input();

spectral = fixed.spectral;

%% read input file
sensors_path = fullfile('../input/sensors.xlsx');
input_path = fullfile('Input_data.xlsx');
% input_path = 'Input_data-default (synthetic).xlsx';

tab = io.read_input_sheet(input_path);

tab_files = io.read_filenames_sheet(input_path, 'Satellite');
path = io.table_to_struct(tab_files, 'path', true);
sensor = io.table_to_struct(tab_files, 'sensor', true);
var_names = io.table_to_struct(tab_files, 'var_names', true);

[var_names.bands, band_wl, sensor.i_srf] = sat.read_bands_sheet(input_path);
path.input_path = input_path;

%% read reflectance
% measured = sat.read_netcdf(path.image_path, var_names);
measured = sat.read_netcdf_4d(path.image_path, var_names);
measured.wl = band_wl;

% for propagation of uncertainty we need the initial uncertainty
% n_bands = size(measured.refl, 3);
% measured.std = ones(n_bands, 1) * 0.01;
measured.std = ones(size(measured.refl)) * 0.01;

%% image subset or full image
[x, y, t, b] = size(measured.refl);
i_row = 1 : x;
i_col = 1 : y;

%% TODO check that pixels are not super far from the image (on the brink + 1km), otherwise suggest coordinates change
if sensor.K ~= 0 
    if all(isfield(measured, {'lat', 'lon'})) 
        [i_row, i_col] = sat.find_image_subset(sensor, measured, x, y);
    else
        warning(['You see this warning because N != 0 (N == %d) but coordiantes are unknown. \n' ...
            'I can not subset N x N pixels around [pix_lat, pix_lon] because '...
            'I do not know (was not able to read) latitude and/or longitude of your image.\n' ...
            'I will fit all pixels of the image.'], sensor.K)
    end
end

% sat.estimate_time(measured.refl, i_row, i_col)

%% read SRF for satellites
sensor.srf = sat.read_srf_1nm(sensors_path, sensor.instrument_name, sensor.i_srf);

%% read irradiance
irradiance = io.read_irradiance(path);

% we do our best => take wlP and FWHM == 1
instrument.wl = spectral.wlP';
instrument.FWHM = ones(size(instrument.wl));
instrument = struct2table(instrument);
% TODO check that we have irradiance in bands or 400-2400
irr_prospect = to_sensor.irradiance2sensor_wl(irradiance, instrument, spectral.wlP');


%% preallocate output structures
% note, here linear indexing is used => column by column [r, c] = ind2sub([n_row, n_col], j);
n_row = length(i_row);
n_col = length(i_col);
n_times = size(measured.refl, 3);
n_spectra = n_row * n_col * n_times;

n_params = length(tab.variable);
n_wl = length(measured.wl);
n_wlF = length(spectral.wlF);

[parameters, parameters_std] = deal(zeros(n_params, n_spectra));
rmse_all = zeros(n_spectra, 1);
[refl_mod, refl_soil] = deal(zeros(n_wl, n_spectra));
[sif_rad, sif_norm] = deal(zeros(n_wlF, n_spectra));
J_all = zeros(n_wl, n_params, n_spectra);  % we fit all wl we have
figures = gobjects(n_spectra,1);

%% start saving
path = io.create_output_file(input_path, path, measured, tab.variable, spectral.wlF', n_spectra);

%% one netcdf
nc_path = fullfile(path.outdir_path, [path.time_string, '.nc']);

sat.initialize_nc_out(nc_path, tab, n_row, n_col, n_times, var_names.bands)

% TODO: possible inversion: lon is x and lat is y
if all(isfield(measured, {'lat', 'lon'}))
    if size(measured.lat, 2) == 1
        nccreate(nc_path, 'lat', 'Dimensions', {'x', n_row})
        ncwrite(nc_path, 'lat', measured.lat(i_row))
        nccreate(nc_path, 'lon', 'Dimensions', {'y', n_col})
        ncwrite(nc_path, 'lon', measured.lon(i_col))
    else
        nccreate(nc_path, 'lat', 'Dimensions', {'x', n_row, 'y', n_col})
        ncwrite(nc_path, 'lat', measured.lat(i_row, i_col))
        nccreate(nc_path, 'lon', 'Dimensions', {'x', n_row, 'y', n_col})
        ncwrite(nc_path, 'lon', measured.lon(i_row, i_col))
    end
end

%% safely writing and plotting data from (par)for loop
q = parallel.pool.DataQueue;
afterEach(q, @(x) io.save_output_j(x{1}, x{2}, x{3}, x{4}, path));
afterEach(q, @(x) sat.write_nc_j(x{1}, x{2}, x{3}, x{4}, tab, n_row, n_col, n_times, nc_path, var_names));
% it is not funny plotting all pixels!
% afterEach(q, @(x) plot.plot_j(x{1}, x{2}, x{3}, x{4}, tab));

%% parallel
% uncomment these lines, select N_proc you want, change for-loop to parfor-loop
N_proc = 3;
if isempty(gcp('nocreate'))
%     prof = parallel.importProfile('local_Copy.settings');
%     parallel.defaultClusterProfile(prof);
    parpool(N_proc);
end

%% time estimation
if ~exist('N_proc', 'var')
    N_proc = 1;
end
eta = n_spectra * 5 / (N_proc * 60);
warning(['You have %d pixels (%d pixels x %d times) and asked for %d CPU(s). '...
    'Fitting will take about %.2f min (~5 s / pixel / CPU)'], ...
    n_spectra, n_row * n_col, n_times, N_proc, eta)

%% fitting
%% change to parfor if you like
parfor j = 1 : n_spectra
    % remember that matlab counts column by column => second image pixel is below upper left corner
    % 1 3 5
    % 2 4 6
    fprintf('%d / %d', j, n_spectra)
    [plane_r, plane_c, t] = ind2sub([n_row, n_col, n_times], j);
    r = i_row(plane_r);
    c = i_col(plane_c);
    
    %% this part is done like it is to enable parfor loop
    measurement = struct();
    measurement.refl = double(squeeze(measured.refl(r, c, t, :)));
    measurement.wl = measured.wl;
    if all(isnan(measurement.refl))
        continue
    end
    
    if all(measurement.refl > 1000)
        warning('skipping spectra %d because > 1000', j)
        continue
    end
    
    angles = struct();
    % TODO: cubes without viewing angles
    if all(isfield(measured, {'oza', 'sza', 'raa'}))
        angles.tto = measured.oza(r, c, t);
        angles.tts = measured.sza(r, c, t);
        angles.psi = measured.raa(r, c, t);
    else
        angles.tto = sensor.tto;
        angles.tts = sensor.tts;
        angles.psi = sensor.pis;
    end

    %% done, this is what comes out
    results_j = fit_spectra(measurement, tab, angles, irr_prospect, fixed, sensor);

    parameters(:, j) = results_j.parameters;
    rmse_all(j) = results_j.rmse;
    refl_mod(:,j) = results_j.refl_mod;
    refl_soil(:,j)  = results_j.soil_mod;
    sif_rad(:,j)  = results_j.sif;
    sif_norm(:,j) = results_j.sif_norm;

    %% uncertainty in parameters
    measurement.std = squeeze(measured.std(r, c, t, :)); %(:, j);
    measurement.i_fit = true(size(measured.wl));  % we are fitting all provided wl

    uncertainty_j = propagate_uncertainty(results_j.parameters, measurement, tab, angles, irr_prospect, fixed, sensor);

    parameters_std(:, j) = uncertainty_j.std_params;
    J_all(:,:,j) = uncertainty_j.J;

    %% send data to write and plot
    send(q, {j, results_j, uncertainty_j, measurement})
    figures(j) = plot.reflectance_hidden(measurement.wl, results_j.refl_mod, measurement.refl, j, results_j.rmse);

end

set(figures(1), 'Visible', 'on')
