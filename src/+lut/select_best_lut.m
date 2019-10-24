function [params, params_std] = select_best_lut(threshold)

rmses = load('rmses.mat');
rmses = rmses.rmses;

params_in = readtable('lut_in.csv');
par_names = params_in.Properties.VariableNames;
par_vals = table2array(params_in);

n_params = size(params_in, 2);
n_spectra = size(rmses, 2);

params = zeros(n_params, n_spectra);
params_std = zeros(n_params, n_spectra);

for i=1:n_spectra
    rmse_i = rmses(:, i);
    i_best = rmse_i < threshold;
    par_best = par_vals(i_best, :);
    
    for j=1:n_params
        par_j = par_best(:, j);
        q1 = quantile(par_j, 0.25);
        q3 = quantile(par_j, 0.75);
        iqr = q3 - q1;
        outliers = par_j < (q1 - 1.5 * iqr) | par_j > (q3 + 1.5 * iqr);
        params(j, i) = mean(par_j(~outliers));
        params_std(j, i) = std(par_j(~outliers));
    end
%     params(:, i) = mean(par_best)';
%     params_std(:, i) = std(par_best)';
end

% writetable([tab.variable(tab.include), array2table(params)], 'params.csv')
% writetable([tab.variable(tab.include), array2table(params_std)], 'params_std.csv')


% lut_params = parameters;
% lut_params_std = parameters_std;
% 
% lut_params(tab.include, :) = params;
% lut_params_std(tab.include, :) = params_std;

end