function tab = read_input_sheet(input_path)

    tab = readtable(input_path, 'sheet', 'Input');

    expected_cols = {'tune', 'variable', 'value', 'upper', 'lower', 'uncertainty', 'description', 'units'};
    colnames = tab.Properties.VariableNames;
    assert(all(ismember(expected_cols, colnames)), ...
           ['wrong column names in input data table; expected: ' sprintf('%s, ', expected_cols{:})])

    tab.include = (tab.tune == 1);

    %% to avoid fitting LIDFa without LIDFb
    i_lidfa = strcmp(tab.variable, 'LIDFa');
    i_lidfb = strcmp(tab.variable, 'LIDFb');
    if tab.include(i_lidfa) || tab.include(i_lidfb)
        tab.include(i_lidfa) = 1;
        tab.include(i_lidfb) = 1;
    end

    %% sif include in fit all 4 components
    i_sif = contains(tab.variable, 'SIF');  % >= 2016a
%     i_sif = ~cellfun(@isempty, strfind(tab.variable, 'SIF')); % <= 2015b
    if any(tab.include(i_sif))
        tab.include(i_sif) = 1;
    end

end