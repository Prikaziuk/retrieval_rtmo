function datetime = read_datetime(file_path)

    pattern = '\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}';

    fid = fopen(fullfile(file_path));
    tline = fgetl(fid);
    while ischar(tline)
        match = regexp(tline, pattern, 'match');
        if ~isempty(match)
            break
        end
        tline = fgetl(fid);
    end
    fclose(fid);

    assert(~isempty(match), ['was not able to detect any string in %s file that matches '...
        '`yyyy-mm-dd HH:MM:SS` pattern'], file_path)
    
    datetime = datenum(match, 'yyyy-mm-dd HH:MM:SS')';
    
end