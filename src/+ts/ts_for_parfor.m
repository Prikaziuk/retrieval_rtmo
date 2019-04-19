function [angles, Rin] = ts_for_parfor(j, sensor)
    
    angles.tts = sensor.angles_ts.tts(j);
    angles.tto = sensor.angles_ts.tto(j);
    angles.psi = sensor.angles_ts.psi(j);
    if isempty(sensor.Rin_ts)
        Rin = sensor.Rin;
    else
        Rin = sensor.Rin_ts(j);
    end
        
end