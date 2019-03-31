function matrix = read_dat(file_path, skip_lines_custom)
    
    file_path = fullfile(file_path);
    
    if isempty(file_path)
        matrix = [];
        return
    end

    opt = detectImportOptions(file_path);
    sep = opt.Delimiter{1};
    skip_lines = opt.DataLine - 1;  % because we want to read starting from DataLine
    
    if nargin == 2
        if skip_lines ~= skip_lines_custom
            warning(['Matlab disagres with the number of lines to skip in `%s` file\n' ...
                'however I will do as you said and skip %d (provided) instead of %d (recommended)'], ...
                file_path, skip_lines, skip_lines_custom)
        end
        skip_lines = skip_lines_custom;
    end
    
    if skip_lines ~= 0
        warning(['We are skipping %d line(s) in your `%s` file '...
            'because matlab thinks they have headers'], skip_lines, file_path)
    end
    
    matrix = dlmread(file_path, sep, skip_lines, 0);
    
end
