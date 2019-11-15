function lut_workflow(n_spectra)

    if nargin == 0
        n_spectra = 5000;
    end
    
    [measured, tab, angles, irr_meas, fixed, sensor] = helpers.synthetic_input();
    
    outdir = fullfile('..', 'lut', [sensor.instrument_name, '_', num2str(n_spectra)]);
    assert(~exist(outdir, 'dir'), ['directory with LUT already exists at %s\n'...
        'please, rename or delete it and rerun the function'], outdir)
    mkdir(outdir)
    
    params = lut.generate_lut_input(tab, n_spectra, outdir);
    lut_refl = lut.generate_lut_spectra(measured, tab, angles, irr_meas, fixed, sensor, outdir);
    
    fprintf('made LUT with %i spectra\n', n_spectra)
    
    fid = fopen(fullfile(outdir, 'lut_comment.txt'), 'w');
    fprintf(fid, 'sensor %s\n', sensor.instrument_name);
    fprintf(fid, 'angles tts=%.2g, tto=%.2g, psi=%.2g\n', angles.tts, angles.tto, angles.psi);
    fprintf(fid, 'n_spectra=%d\n', n_spectra);
    fclose(fid);

end


