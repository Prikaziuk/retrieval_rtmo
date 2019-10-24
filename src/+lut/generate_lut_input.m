function params = generate_lut_input(tab, n_spectra)

    include = tab.include;
    lb = tab.lower(include)';
    ub = tab.upper(include)';
    varnames = tab.variable(include)';

    % one row - one set of parameters
    lh = lhsdesign(n_spectra, sum(include));

    params = (ub-lb) .* lh + lb;

    if any(strcmp('LIDFa' , varnames))
        % abs(LIDFa + LIDFb) <= 1
        i_lidfa = strcmp('LIDFa', varnames);
        i_lidfb = strcmp('LIDFb', varnames);
        lidfa = params(:, i_lidfa);
        lidfb = params(:, i_lidfb);
        params(:, i_lidfa) = (lidfa + lidfb) / 2;
        params(:, i_lidfb) = (lidfa - lidfb) / 2;
    end

    t = array2table(params);
    t.Properties.VariableNames = varnames;
    writetable(t, 'lut_in.csv')
   
end