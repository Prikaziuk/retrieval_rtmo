function figures = replot_all(your_output_xlsx_file, your_validation_path)
    % your_output_xlsx_file = path.xlsx_path;
    % your_validation_path = path.validation;  % OPTIONAL

    [wl, meas, mod, rmse, params, params_std, tab] = io.read_output(your_output_xlsx_file);

    n_spectra = size(meas, 2);
    figures = gobjects(n_spectra,1);
    for j=1:n_spectra  % replace by the number of column you need
        meas_j = meas(:, j);
        mod_j = mod(:, j);
        rmse_j = rmse(:, j);
%         plot.reflectance(wl, meas_j, mod_j, j, rmse_j)
        figures(j) = plot.reflectance_hidden(wl, meas_j, mod_j, j, rmse_j);
    end


    if nargin == 2
        validation = readtable(your_validation_path, 'TreatAsEmpty',{'NA'});
%         plot.modelled2measured(params, tab, validation, 'validation', true)

    %     if you have Cab, Cab_sd in validation you might want to use this function
        plot.modelled2measured_sd(params, tab, validation, 'validation', params_std, true)
    end
end