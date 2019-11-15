function params = generate_lut_input(tab, n_spectra, outdir)
    
    if nargin < 3
        outdir = '.';
    end

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
    writetable(t, fullfile(outdir, 'lut_in.csv'))
    
    if verLessThan('matlab', '9.1')  % < 2016b
        varnames_in = '';
    else
        varnames_in = strjoin(varnames, ', ');
    end
    fprintf('Sampled %i parameters: %s\n', length(varnames), varnames_in)
   
end