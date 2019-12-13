function [parameters, parameters_std, rmse_all, spec, spec_sd] = fit_spectra_lut(path, measured, tab)
 
    %% read lut
    assert(~isempty(path.lut_input), 'please, provide path to file with LUT input parameters')
    lut_in = readtable(path.lut_input);
    par_names = lut_in.Properties.VariableNames;
    lut_in = table2array(lut_in);
    
    lut_spec = load(path.lut_path);
    lut_spec = lut_spec.lut_spec;
    
    % hyplant trunc
    % lut_spec = lut_spec(:, 17:(size(lut_spec, 2) - 19));

    assert(size(lut_spec, 2) == length(measured.wl), '# of wavelength in LUT and measured differs')
    
    if size(measured.refl, 2) ~= length(measured.wl)
        measured.refl = measured.refl';
    end
    
    %% search in lut
    % will 500k fit or batch?
    ind_func = @(i) lut.top_indices(i, measured.refl, lut_spec);
    ind = arrayfun(ind_func, 1:size(measured.refl, 1), 'UniformOutput', false);  % [n_spec x n_wl]
    ind = cell2mat(ind');
    
    fprintf('finished LUT, started parameters\n')
    param_fun = @(i) median(lut_in(ind(i, :), :), 1)';
    pars = arrayfun(param_fun, 1:size(ind, 1), 'UniformOutput', false);
    pars = cell2mat(pars);
    param_sd_fun = @(i) std(lut_in(ind(i, :), :), 1)';
    pars_sd = arrayfun(param_sd_fun, 1:size(ind, 1), 'UniformOutput', false);
    pars_sd = cell2mat(pars_sd);
    
    param_mad_fun = @(i) mad(lut_in(ind(i, :), :), 0, 1)';
    pars_mad = arrayfun(param_mad_fun, 1:size(ind, 1), 'UniformOutput', false);
    pars_mad = cell2mat(pars_mad);
    
    [~, i_in, ~] = intersect(tab.variable, par_names, 'stable');
    parameters = repmat(tab.value, 1, size(pars, 2));
    parameters(i_in, :) = pars;  % loosing default constants
    parameters_std = zeros(size(parameters));
    if size(pars_sd, 1) ~= 1
        parameters_std(i_in, :) = pars_mad;
    end
    [~, i_sif, ~] = intersect(tab.variable, {'SIF_PC1', 'SIF_PC2', 'SIF_PC3', 'SIF_PC4'}, 'stable');
    parameters(i_sif, :) = 0;
    
    fprintf('finished parameters, started spectra\n')
    spec_fun = @(i) median(lut_spec(ind(i, :), :), 1)';
    spec = arrayfun(spec_fun, 1:size(ind, 1), 'UniformOutput', false);
    spec = cell2mat(spec);
    rmse_all = sqrt(mean((spec - measured.refl') .^ 2, 1));
    
    spec_sd_fun = @(i) std(lut_spec(ind(i, :), :), 1)';
    spec_sd = arrayfun(spec_sd_fun, 1:size(ind, 1), 'UniformOutput', false);
    spec_sd = cell2mat(spec_sd);
    if size(spec_sd, 1) == 1
        spec_sd = zeros(size(spec));
    end

end