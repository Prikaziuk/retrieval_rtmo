function generate_lut_spectra(measurement, tab, angles, irr_meas, fixed, sensor)

    t = readtable('lut_in.csv');
    varnames = t.Properties.VariableNames;
    ta = table2array(t);
    n_spectra = size(t, 1);

    assert(all(strcmp(varnames, tab.variable(tab.include)')), 'check input: extra or few input')

    % save prior (x0) values
    tab.x0 = tab.value;
    
    lut = zeros(n_spectra, length(measurement.wl));  % how to get n_wl?
    for i=1:size(t, 1)
        if mod(i, 100) == 0
            disp(i)
        end
        p = ta(i, :);
        p = helpers.modify_parameters(p, varnames);

        [~, ~, refl, ~, ~, ~] = COST_4SAIL_common(p, measurement, tab, angles, ...
                                                  irr_meas, fixed, sensor);
        lut(i, :) = refl;

    end
    save lut.mat lut

end