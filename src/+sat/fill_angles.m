function measured = fill_angles(measured, sensor)

    [x, y, t, ~] = size(measured.refl);
    
    if ~isfield(measured, 'sza')
        fprintf('sza is taken %.02f everywhere\n', sensor.tts)
        sza = zeros(x, y, t);
        sza(:) = sensor.tts;
        measured.sza = sza;
    end
    
    if ~isfield(measured, 'oza')
        fprintf('oza is taken %.02f everywhere\n', sensor.tto)
        oza = zeros(x, y, t);
        oza(:) = sensor.tto;
        measured.oza = oza;
    end
       
    if ~isfield(measured, 'raa')
        fprintf('psi is taken %.02f everywhere\n', sensor.psi)
        raa = zeros(x, y, t);
        raa(:) = sensor.psi;
        measured.raa = raa;
    end

end