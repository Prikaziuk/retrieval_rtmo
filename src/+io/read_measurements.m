function measured = read_measurements(path)

    
    measured.refl = io.read_dat(path.reflectance);
    measured.wl = io.read_dat(path.reflectance_wl);

    assert(size(measured.refl, 1) == size(measured.wl, 1), ...
          'wavelength and reflectance number of rows do not match')

    measured.std = [];
    if ~isempty(path.reflectance_std)
        measured.std = io.read_dat(path.reflectance_std);
        assert(all(size(measured.refl) == size(measured.std)), ... 
           'sizes of measured reflectance and its uncertainty mismatch')
    end
    
    if ~isempty(path.validation)
        measured.val = readtable(path.validation, 'TreatAsEmpty',{'NA'});
        n_spectra = size(measured.refl, 2);
        n_validation = size(measured.val, 2) - 1;
        assert(n_spectra == n_validation, ['the number of measured spectra (%d) ' ... 
            'is not equal to the number of columns in validation file (%d)'], n_spectra, n_validation)
    end
end