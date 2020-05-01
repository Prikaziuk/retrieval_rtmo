function lut_workflow(n_spectra, tts_classes)

    if nargin == 0
        n_spectra = 1000;
        tts_classes = 10:5:80;  % 10:10:80  % []
    end
    
    [measured, tab, angles, irr_meas, fixed, sensor] = helpers.synthetic_input();
    
    outdir = fullfile('..', 'lut', [sensor.instrument_name, '_', num2str(n_spectra)]);
%     assert(~exist(outdir, 'dir'), ['directory with LUT already exists at %s\n'...
%         'please, rename or delete it and rerun the function'], outdir)
    mkdir(outdir)
    
    params = lut.generate_lut_input(tab, n_spectra, outdir);
    if isempty(tts_classes)
        lut_refl = lut.generate_lut_spectra(measured, tab, angles, irr_meas, fixed, sensor, outdir);
    else
        n_angles = length(tts_classes);
        lut_spec = nan(n_spectra, length(measured.wl), n_angles);
        for i=1:n_angles
            angles.tts = tts_classes(i);
            fprintf('tts %.2f\n', tts_classes(i))
            lut_refl = lut.generate_lut_spectra(measured, tab, angles, irr_meas, fixed, sensor, outdir);
            lut_spec(:, :, i) = lut_refl;
        end
        save(fullfile(outdir, 'lut.mat'), 'lut_spec')
        
        
        angle_info.tts = tts_classes';
        angle_info.i = (1:length(tts_classes))';
        writetable(struct2table(angle_info), fullfile(outdir, 'angle_info.csv'))
%         figure
%         victim = squeeze(lut_spec(50, :, :));
%         plot(measured.wl, victim)
%         hleg = legend(arrayfun(@num2str, tts_classes, 'UniformOutput', false));
%         title(hleg, 'SZA')
%         
%         figure
%         r = 3;
%         c = 4;
%         wl = measured.wl;
%         for i=1:length(wl)
%             subplot(r, c, i)
%             plot(tts_classes, victim(i, :), 'x-')
%             title(sprintf('%d nm', wl(i)))
%             xlabel('SZA')
%             ylabel('refl')
%         end
    end
    
    fprintf('made LUT with %i spectra\n', n_spectra)
    
    fid = fopen(fullfile(outdir, 'lut_comment.txt'), 'w');
    fprintf(fid, 'sensor %s\n', sensor.instrument_name);
    fprintf(fid, 'angles tts=%.2g, tto=%.2g, psi=%.2g\n', angles.tts, angles.tto, angles.psi);
    fprintf(fid, 'n_spectra=%d\n', n_spectra);
    fclose(fid);

end


