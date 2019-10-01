function [band_names, band_wl, i_srf] = read_bands_sheet(input_path)

    if verLessThan('matlab', '9.1')  % R2016b
        bands = readtable(input_path, 'sheet', 'Bands', 'TreatAsEmpty', {'', 'NA', 'N/A'});
        bands(1, :) = [];  % hope for the best - unchanged .xlsx
    else
        opt = detectImportOptions(input_path, 'sheet', 'Bands');
        bands = readtable(input_path, opt);
    end

    expected_cols = {'i_srf', 'your_names', 'your_wl'};
    colnames = bands.Properties.VariableNames;
    assert(all(ismember(expected_cols, colnames)), ...
           ['wrong column names in `bands` table. ' ...
           'Required at least: ' sprintf('`%s`, ', expected_cols{:})])
    
    i_absent_bands = cellfun(@(x) isempty(x), bands.your_names);
    bands(i_absent_bands, :) = [];
    
    band_names = bands.your_names;
    band_wl = bands.your_wl;
    i_srf = bands.i_srf;
    if iscell(i_srf)
        i_srf = cellfun(@str2num, i_srf);
    end
    
end