function values = demodify_parameters(values, varnames)    
    
    assert(size(values, 1) == length(varnames), 'different length of variables and values')
    
    % LAI from exponential to linear
    i_lai = strcmp('LAI', varnames);
    values(i_lai, :) = -5 * log(1 - values(i_lai, :));  % if i_lai is empty => no assignment
    
    % abs(LIDFa + LIDFb) <= 1
    i_lidfa = strcmp('LIDFa', varnames);
    i_lidfb = strcmp('LIDFb', varnames);
    lidfa = values(i_lidfa, :);
    lidfb = values(i_lidfb, :);
    values(i_lidfa, :) = (lidfa + lidfb) / 2;
    values(i_lidfb, :) = (lidfa - lidfb) / 2;

end