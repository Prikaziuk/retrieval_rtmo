function Rin_ts = get_Rin_ts(Rin_path, Rin, n_spectra)    

    if isempty(Rin_path)
        Rin_ts = repmat(Rin, 1, n_spectra);
    else
        Rin_ts = io.read_dat(Rin_path);
        assert(size(Rin_ts, 2) == n_spectra, ['Number of columns in `%s` '... 
           ' and reflectance spectra (%d) mismatch'], Rin_path, n_spectra)
    end
    
end