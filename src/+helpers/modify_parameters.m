function values = modify_parameters(values, varnames)
    
    assert(length(values) == length(varnames), 'different length of variables and values')
    
    % LAI from linear to exponential
    i_lai = strcmp('LAI', varnames);
    values(i_lai) = 1 - exp(-0.2 * values(i_lai));  % if i_lai is empty => no assignment
    
    % abs(LIDFa + LIDFb) <= 1
    i_lidfa = strcmp('LIDFa', varnames);
    i_lidfb = strcmp('LIDFb', varnames);
    lidfa = values(i_lidfa);
    lidfb = values(i_lidfb);
    values(i_lidfa) = lidfa + lidfb;
    values(i_lidfb) = lidfa - lidfb;
end