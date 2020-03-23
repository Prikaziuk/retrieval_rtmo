function structure = table_to_struct(input_table, struct_name, is_satellite)
    
    if nargin == 2
        is_satellite = false;
    end

    % test that the fields we refer to exist
    assert(ismember(struct_name, {'soil', 'leafbio', 'canopy', 'sif', 'path', ... 
        'sensor', 'var_names', 'sun', 'path_ts'}), ...
        ['structure with name ' struct_name ' is not expected'])
    
    text2num  = {'tts', 'tto', 'psi', 'hot', 'pix_lat', 'pix_lon', 'K', ...
                 'lat', 'lon', 'tz', 'summertime', ...
                 'Rin', 'c', 'FWHM', 'wlmin', 'wlmax', 'skip_lines', 'timeseries', ...
                 'quality_flag_is',  'quality_flag_lt'};
                    
    optional = {'Rin', 'Esun', 'Esky', 'atmfile', 'lut_path', 'lut_input', 'ksi', 'Cv'};

    % expected names from inputdata sheet (all numerical by default)
    variable_names.soil =  {'B', 'BSMlat', 'BSMlon', 'SMC'};
    variable_names.leafbio = {'Cab', 'Cca', 'Cant', 'Cdm', 'Cw', 'Cs', 'N'};
    variable_names.canopy = {'LAI', 'LIDFa', 'LIDFb', 'ksi', 'Cv'};
    variable_names.sif = {'SIF_PC1', 'SIF_PC2', 'SIF_PC3', 'SIF_PC4'};
    
    common_path = {'output_path', 'simulation_name', 'Esun', 'Esky', 'atmfile', 'lut_path', 'lut_input'};
    common_sensor = {'instrument_name', 'tts', 'tto', 'psi', 'hot', 'Rin'};
    if is_satellite
        % expected names from satellite sheet
        optional = [optional, 'sza', 'oza', 'saa', 'oaa', 'latitude', 'longitude', ...
            'quality_flag_name', 'quality_flag_is',  'quality_flag_lt'];
        variable_names.path = [common_path, {'image_path'}];
        variable_names.var_names = {'sza', 'oza', 'saa', 'oaa', 'latitude', 'longitude', 'quality_flag_name'};
        variable_names.sensor = [common_sensor, {'pix_lat', 'pix_lon', 'K', 'quality_flag_is',  'quality_flag_lt'}];
    else    
        % expected names from filenames sheet
        optional = [optional,  'instrument_name',  'tts',  ...
                'reflectance_std', 'validation', 'soilfile', ...
                'tts_path', 'tto_path', 'psi_path', 'datetime_path', 'Rin_path'];
        variable_names.path = [common_path, {'reflectance', 'reflectance_std', 'reflectance_wl', 'soilfile', 'validation'}];                
        variable_names.sensor = [common_sensor, {'c', 'FWHM', 'wlmin', 'wlmax', 'timeseries'}];
        variable_names.sun = {'lat', 'lon', 'datetime', 'tz'};
    end
    
    variable_names.path_ts = {'tts_path', 'tto_path', 'psi_path', 'datetime_path', 'Rin_path'};
    
    % parsing: variable(name)-value matching => less errors
    table_param_names = input_table.variable;
    struct_param_names = variable_names.(struct_name);
    for i = 1:length(struct_param_names)
        name = struct_param_names{i};
        value = input_table.value(strcmp(table_param_names, name));
        if iscell(value) && ~isempty(value)
            value = value{1};
        end
        if any(strcmp(name, optional)) && isempty(value)
            structure.(name) = '';
            continue
        end
        assert(~isempty(value), 'variable `%s` was not provided',  name)
        if any(strcmp(name, text2num))
            [value, status] = str2num(value);
            assert(status == 1, '`%s` should be numerical, you provided `%s`', name, value)
        end
        if strcmp(name, 'datetime')
            structure.([name, '_str']) = value;
            value = datenum(value,'yyyy-mm-dd HH:MM:SS');
        end
        if isnan(value)
            value = '';
        end
        if isequal(struct_name, 'path')
            val_split = strsplit(value, {'/','\'});
            value = fullfile(val_split{:});
        end
        structure.(name) = value;
    end

end