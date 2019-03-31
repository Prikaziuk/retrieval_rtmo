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

tab = io.read_input_sheet(input_path);

tab_files = io.read_filenames_sheet(input_path, 'Satellite');
path = io.table_to_struct(tab_files, 'path', true);
sensor = io.table_to_struct(tab_files, 'sensor', true);
var_names = io.table_to_struct(tab_files, 'var_names', true);

[var_names.bands, band_wl, sensor.i_srf] = sat.read_bands_sheet(input_path);
path.input_path = input_path;

%% read reflectance
measured = sat.read_netcdf(path.image_path, var_names);
measured.wl = band_wl;

% for propagation of uncertainty we need the initial uncertainty
% n_bands = size(measured.refl, 3);
% measured.std = ones(n_bands, 1) * 0.01;
measured.std = ones(size(measured.refl)) * 0.01;

%% image subset or full image
[x, y, z] = size(measured.refl);
i_row = 1 : x;
i_col = 1 : y;

%% TODO check that pixels are not super far from the image (on the brink + 1km), otherwise suggest coordinates change
if sensor.K ~= 0 
    if all(isfield(measured, {'lat', 'lon'})) 
        [i_row, i_col] = sat.find_image_subset(sensor, measured);
    else
        warning(['You see this warning because N != 0 (N == %d) but coordiantes are unknown. \n' ...
            'I can not subset N x N pixels around [pix_lat, pix_lon] because '...
            'I do not know (was not able to read) latitude and/or longitude of your image.\n' ...
            'I will fit all pixels of the image.'], sensor.K)
    end
end

sat.estimate_time(measured.refl, i_row, i_col)

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
n_spectra = n_row * n_col;

n_params = length(tab.variable);
n_wl = length(measured.wl);
n_wlF = length(spectral.wlF);

[parameters, parameters_std] = deal(zeros(n_params, n_spectra));
rmse_all = zeros(n_spectra, 1);
[refl_mod, refl_soil] = deal(zeros(n_wl, n_spectra));
[sif_rad, sif_norm] = deal(zeros(n_wlF, n_spectra));
J_all = zeros(n_wl, n_params, n_spectra);  % we fit all wl we have

%% start saving
path = io.create_output_file(input_path, path, measured, tab.variable, spectral.wlF');

%% one netcdf
nc_path = fullfile(path.outdir_path, [path.time_string, '.nc']);

sat.initialize_nc_out(nc_path, tab, n_row, n_col, var_names.bands)

if all(isfield(measured, {'lat', 'lon'}))
    ncwrite(nc_path, 'lat', measured.lat(i_row, i_col))
    ncwrite(nc_path, 'lon', measured.lon(i_row, i_col))
end

%% safely writing data from (par)for loop
q = parallel.pool.DataQueue;
afterEach(q, @(x) io.save_output_j(x{1}, x{2}, x{3}, x{4}, path));
afterEach(q, @(x) sat.write_nc_j(x{1}, x{2}, x{3}, x{4}, tab, n_row, n_col, nc_path, var_names));
% it is not funny plotting all pixels!
% afterEach(q, @(x) plot.plot_j(x{1}, x{2}, x{3}, x{4}, tab));

%% parallel
% uncomment these lines, select N_proc you want, change for-loop to parfor-loop
% N_proc = 3;
% if isempty(gcp('nocreate'))
% %     prof = parallel.importProfile('local_Copy.settings');
% %     parallel.defaultClusterProfile(prof);
%     parpool(N_proc);
% end

%% fitting
%% change to parfor if you like
for j = 1 : n_spectra
    % remember that matlab counts column by column => second image pixel is below upper left corner
    % 1 3 5
    % 2 4 6
    % also note that netcdf in matlab is flipped: lat is row, lon in col
    fprintf('%d / %d', j, n_spectra)
    [r, c] = ind2sub([n_row, n_col], j);
    
    %% this part is done like it is to enable parfor loop
    measurement = struct();
    measurement.refl = squeeze(measured.refl(r, c, :));
    measurement.wl = measured.wl;
    if all(isnan(measurement.refl))
        continue
    end
    
    angles = struct();
    if all(isfield(measured, {'oza', 'sza', 'raa'}))
        angles.tto = measured.oza(r, c);
        angles.tts = measured.sza(r, c);
        angles.psi = measured.raa(r, c);
    else
        angles.tto = sensor.tto;
        angles.tts = sensor.tts;
        angles.psi = sensor.pis;
    end

    %% done, this is what comes out
    pixel_k_1_e3 = [0.5000   25.0000   45.0000   30.0000   37.0763   11.5951    1.0114    0.0089    0.0128    0.6000    2.3695    0.9816   -0.1144   -0.1392         0         0         0         0]';

    results_j = fit_spectra(measurement, tab, angles, irr_prospect, fixed, sensor);
    
    [pixel_k_1_e3, results_j.parameters]

    parameters(:, j) = results_j.parameters;
    rmse_all(j) = results_j.rmse;
    refl_mod(:,j) = results_j.refl_mod;
    refl_soil(:,j)  = results_j.soil_mod;
    sif_rad(:,j)  = results_j.sif;
    sif_norm(:,j) = results_j.sif_norm;

    %% uncertainty in parameters
    measurement.std = measured.std(:, j);
    measurement.i_fit = true(size(measured.wl));  % we are fitting all provided wl

    uncertainty_j = propagate_uncertainty(results_j.parameters, measurement, tab, angles, irr_prospect, fixed, sensor);

    parameters_std(:, j) = uncertainty_j.std_params;
    J_all(:,:,j) = uncertainty_j.J;

    %% send data to write and plot
    send(q, {j, results_j, uncertainty_j, measurement})

end
