function angles = get_angles_ts(sensor, sun, path_ts, n_spectra)
    
    angles.tts = sensor.tts;
    angles.tto = sensor.tto;
    angles.psi = sensor.psi;

    if ~isempty(path_ts.datetime_path)
        datetime = io.read_datetime(path_ts.datetime_path);
        assert_equal_length(datetime, n_spectra, path_ts.datetime_path)
        angs = helpers.solarPosition(datetime, sun.lat, sun.lon, sun.tz, 0, sun.summertime);
        angles.tts = angs(:, 1)';
        angles.tto = 0;
        angles.psi = 0;
    end
    if ~isempty(path_ts.tts_path)
        angles.tts = io.read_dat(path_ts.tts_path);
        assert_equal_length(angles.tts, n_spectra, path_ts.tts_path)
        angles.tto = sensor.tto;
        angles.psi = sensor.psi;
    end
    if ~isempty(path_ts.tto_path)
        angles.tto = io.read_dat(path_ts.tto_path);
        assert_equal_length(angles.tto, n_spectra, path_ts.tto_path)
    end
    if ~isempty(path_ts.psi_path)
        angles.psi = io.read_dat(path_ts.psi_path);
        assert_equal_length(angles.psi, n_spectra, path_ts.psi_path)
    end
    
    names = fieldnames(angles);
    for i = 1 : length(names)
        field_i = angles.(names{i});
        if length(field_i) ~= n_spectra
            angles.(names{i}) = repmat(field_i, 1, n_spectra);
        end
    end
    
end

function assert_equal_length(matrix, n_spectra, file_path)
    assert(size(matrix, 2) == n_spectra, ['number of columns in `%s` is not equal to the number '...
        'of spectra you asked to fit (%d)'], file_path, n_spectra)
end