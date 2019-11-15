function lut_spec = generate_lut_spectra(measurement, tab, angles, irr_meas, fixed, sensor, outdir)
    
    if nargin < 7
        outdir = '.';
    end

    lut_in = readtable(fullfile(outdir, 'lut_in.csv'));
    varnames = lut_in.Properties.VariableNames;
    lut_in = table2array(lut_in);
    n_spectra = size(lut_in, 1);

    assert(all(strcmp(varnames, tab.variable(tab.include)')), 'check input: extra or few input')

    % save prior (x0) values
    tab.x0 = tab.value;
    
    lut_spec = zeros(n_spectra, length(measurement.wl));
    fprintf('Started RTMo spectra simulation for LUT\n')
    for i=1:n_spectra
        if mod(i, 100) == 0
            fprintf('%i / %i\n', i, n_spectra)
        end
        p = lut_in(i, :);
        p = helpers.modify_parameters(p, varnames);

        [~, ~, refl, ~, ~, ~] = COST_4SAIL_common(p, measurement, tab, angles, ...
                                                  irr_meas, fixed, sensor);
        lut_spec(i, :) = refl;
    end
    
    save(fullfile(outdir, 'lut.mat'), 'lut_spec')
end
