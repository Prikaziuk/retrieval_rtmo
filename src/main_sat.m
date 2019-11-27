%function [er,params0,params1,spectral,leafbio,canopy,rad,reflSAIL_all,J,fluorescence]= master
%% start fresh
close all
clear all

%% check compatibility
data_queue_present = helpers.check_compatibility();
write_after_loop = true;

%% fixed input (constants)
fixed = io.read_fixed_input();
spectral = fixed.spectral;

%% read input file
sensors_path = fullfile('..', 'input', 'sensors.xlsx');
input_path = 'Input_data.xlsx';
% input_path = 'Input_data-default (synthetic).xlsx';
% input_path = 'Input_data_S3.xlsx';

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
if isa(measured.refl, 'single')  % lsqnonlin requirement
    measured.refl = double(measured.refl);
end
measured.wl = band_wl;

% sixs coefficients for S3
% measured = read_sixs(path.image_path, sensor.i_srf, measured);

measured = sat.fill_angles(measured, sensor);

% for propagation of uncertainty we need the initial uncertainty
% n_bands = size(measured.refl, 3);
% measured.std = ones(n_bands, 1) * 0.01;
measured.std = ones(size(measured.refl)) * 0.01;

%% image subset or full image
[x, y, t, b] = size(measured.refl);
i_row = 1 : x;
i_col = 1 : y;

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
if any(strcmp(sensor.instrument_name, fixed.srf_sensors))
    sensor.srf = sat.read_srf_1nm(sensors_path, sensor.instrument_name, sensor.i_srf);
end

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

%% start saving
path = io.create_output_folder(path);
path = sat.initialize_nc_out(path, tab, n_row, n_col, n_times, var_names.bands, measured, i_row, i_col);

%% fitting
if ~isempty(path.lut_path)
    warning('Fitting with look-up table')

    % TODO: with 3d nc will fail: for t=1:n_times...
    qc_i = true([n_row, n_col, n_times]);
    if isfield(measured, 'qc')
        fprintf('Filtering with quality flag\n')
        qc = measured.qc(i_row, i_col, :);
        qc_good_is = true(size(qc));
        if ~isempty(sensor.quality_flag_is)
            qc_good_is = (qc == sensor.quality_flag_is);
        end
        qc_good_lt = true(size(qc));
        if ~isempty(sensor.quality_flag_lt)
            qc_good_lt = (qc < sensor.quality_flag_lt);
        end
        qc_i = qc_good_is & qc_good_lt;
    end
    
    if sum(~qc_i(:)) == n_spectra
        warning('All pixels were filtered out by quality flag, nothing left to fit')
        return
    end
    
%     measured.refl = measured.refl * 0.0001;  % GEE
    qc_is_nan = all(isnan(measured.refl), 4);
    qc_i = qc_i & (~qc_is_nan);
    
    fprintf(['You have %d pixels. '...
        'Fitting will take about %.2f min (~0.0000175 s / pixel / CPU)\n'], ...
        sum(qc_i(:)), sum(qc_i(:)) * 0.0000175)
    
    %% slicing into bathces
    batch_size = 500 * 500;
    n_batches = ceil(n_spectra / batch_size);
    n_cols_in_batch = floor(batch_size / n_row);  % n_row_batch == n_row
    n_cols = ceil(n_col / n_cols_in_batch);  % with ceil n > than needed
%     batch_c_ends = [(1:n_cols) * n_cols_in_batch, length(i_col)];
    i_c_start = 1;
    for i = 1:n_cols
        i_c_end = i * n_cols_in_batch;
        if i_c_end > n_col
            i_c_end = n_col;
        end
        fprintf('batch %d / %d\n', i, n_batches)
        
        i_col_batch = i_col(i_c_start:i_c_end);
        n_col_batch = length(i_col_batch);
        
        n_spectra_batch = n_row * n_col_batch;
        qc_i_batch = reshape(qc_i(i_row, i_col_batch, n_times), [n_spectra_batch, 1]);
        if sum(qc_i_batch(:)) == 0
            i_c_start = i_c_end + 1;
            continue
        end
        batch.refl = reshape(measured.refl(i_row, i_col_batch, n_times, :), [n_spectra_batch, n_wl]);
        batch.refl = batch.refl(qc_i_batch, :);
        batch.wl = measured.wl;
        
        
        % preallocation of structures
        [parameters, parameters_std] = deal(nan(n_params, n_spectra_batch));
        [rmse_all, exitflags] = deal(nan(n_spectra_batch, 1));
        [refl_mod, refl_soil] = deal(nan(n_wl, n_spectra_batch));
        [sif_rad, sif_norm] = deal(nan(n_wlF, n_spectra_batch));
        
        tic
        [params, params_std, rmse_lut, spec, spec_sd] = fit_spectra_lut(path, batch, tab);
        toc
        
        parameters(:, qc_i_batch) = params;
        parameters_std(:, qc_i_batch) = params_std;
        rmse_all(qc_i_batch) = rmse_lut;
        refl_mod(:, qc_i_batch) = spec;
        
        sat.save_output_nc_batch(path, parameters, rmse_all, refl_mod, sif_rad, exitflags, n_row, ...
            n_col_batch, n_times, tab.include, i_c_start)
        fprintf('batch # %d successfully saved\n', i)
        
        i_c_start = i_c_end + 1;
    end
    return 
    
    measured.refl = measured.refl(qc_i, :);
    tic
    [params, params_std, rmse_lut, spec, spec_sd] = fit_spectra_lut(path, measured, tab);
    toc
    parameters(:, qc_i) = params;
    parameters_std(:, qc_i) = params_std;
    rmse_all(qc_i) = rmse_lut;
    refl_mod(:, qc_i) = spec;  % better to run forward again but on 500k no way
%     angles_single.tts = sensor.tts;
%     angles_single.tto = 0; % sensor.tto;
%     angles_single.psi = 0; % sensor.psi;
else
    warning('Fitting with numerical optimization')
    
    %% preallocate structures
    [parameters, parameters_std] = deal(nan(n_params, n_spectra));
    [rmse_all, exitflags] = deal(nan(n_spectra, 1));
    [refl_mod, refl_soil] = deal(nan(n_wl, n_spectra));
    [sif_rad, sif_norm] = deal(nan(n_wlF, n_spectra));
    J_all = nan(n_wl, n_params, n_spectra);  % we fit all wl we have
%     figures = gobjects(n_spectra,1);
    
    %% safely writing and plotting data from (par)for loop
    if write_after_loop
        fprintf(['Writing of the output will occur after (par)for loop\n' ...
            'In case of errors no output will be saved to output files.\n' ... 
            'However it will be available in the workspace.\n'])
    elseif data_queue_present
        q = parallel.pool.DataQueue;
        if isunix
            fprintf('not yet writing to .csv on UNIX, only .nc will be written')
            % path = io.initialize_csv(path, tab.variable);
        else
            path = io.initialize_xlsx_out(path, measured, tab.variable, n_spectra, spectral.wlF');
            % afterEach(q, @(x) io.save_output_j(x{1}, x{2}, x{3}, x{4}, path));
        end
        afterEach(q, @(x) sat.save_output_nc_j(x{1}, x{2}, x{3}, x{4}, tab, n_row, n_col, n_times, path));
        % it is not funny plotting all pixels!
        % afterEach(q, @(x) plot.plot_j(x{1}, x{2}, x{3}, x{4}, tab));
    else
        fprintf(['You do not have parallel.pool.DataQueue, so\n'...
            'Writing of the output will occur after (par)for loop\n' ...
            'In case of errors no output will be saved to output files.\n' ... 
            'However it will be available in the workspace.\n'])
    end

    %% time estimation
    if ~exist('N_proc', 'var')
        N_proc = 1;
    end
    eta = n_spectra * 7 / (N_proc * 60);
    fprintf(['You have %d pixels (%d pixels x %d times) and asked for %d CPU(s). '...
        'Fitting will take about %.2f min (~7 s / pixel / CPU)\n'], ...
        n_spectra, n_row * n_col, n_times, N_proc, eta)
    
    %% change to parfor if you can
    % NumOpt fitting
    for j = 1 : n_spectra
        % remember that matlab counts column by column => second image pixel is below upper left corner
        % 1 3 5
        % 2 4 6
        fprintf('%d / %d\n', j, n_spectra)
        [plane_r, plane_c, t] = ind2sub([n_row, n_col, n_times], j);
        r = i_row(plane_r);
        c = i_col(plane_c);

        %% this part is done like it is to enable parfor loop
        measurement = struct();
        measurement.refl = squeeze(measured.refl(r, c, t, :));
        measurement.wl = measured.wl;

        if all(isnan(measurement.refl))
            continue
        end

        if isfield(measured, 'qc')
            if ~isempty(sensor.quality_flag_is)
                if measured.qc(r, c, t) ~= sensor.quality_flag_is
                    fprintf('pixel %d did not pass quality flag is\n', j)
                    continue
                end
            end
            if ~isempty(sensor.quality_flag_lt)
                if measured.qc(r, c, t) >= sensor.quality_flag_lt
                    fprintf('pixel %d did not pass quality flag lt\n', j)
                    continue
                end
            end
        end

        if isfield(measured, 'xa')
            measurement.xa = squeeze(measured.xa(r, c, t, :));
            measurement.xb = squeeze(measured.xb(r, c, t, :));
            measurement.xc = squeeze(measured.xc(r, c, t, :));
            measurement.rad = squeeze(measured.rad(r, c, t, :));
        end

        angles = struct();
        angles.tto = measured.oza(r, c, t);
        angles.tts = measured.sza(r, c, t);
        angles.psi = measured.raa(r, c, t);

        %% done, this is what comes out
        results_j = fit_spectra(measurement, tab, angles, irr_prospect, fixed, sensor);

        parameters(:, j) = results_j.parameters;
        rmse_all(j) = results_j.rmse;
        exitflags(j) = results_j.exitflag;
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
    %     uncertainty_j = 'does not matter if only .nc is written';

        %% send data to write and plot
%         if data_queue_present && ~write_after_loop
%             send(q, {j, results_j, uncertainty_j, measurement})
%         end
%         figures(j) = plot.reflectance_hidden(measurement.wl, results_j.refl_mod, measurement.refl, j, results_j.rmse);

    end
end

%% writing for users with Matlab < 2017a => without parallel.pool.DataQueue;
% writing at the end is faster than send() for j > 100, but less safe to errors

if write_after_loop
    fprintf('writing .nc to %s\n', path.nc_path)
    sat.save_output_nc(path, parameters, rmse_all, refl_mod, sif_rad, exitflags, n_row, n_col, n_times, tab.include)
%     if isunix
%         warning('not yet writing to .csv on UNIX, only .nc will be written')
%         path = io.initialize_csv(path, tab.variable);
%     else
%         disp('started writing to .xlsx')
%         io.save_output(path, rmse_all, parameters, parameters_std, refl_meas, refl_mod, refl_soil, sif_norm, sif_rad)
%     end
end

% set(figures(1), 'Visible', 'on')
