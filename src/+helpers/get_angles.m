function angles = get_angles(sensor, sun)

    angles.tts = sensor.tts;
    angles.tto = sensor.tto;
    angles.psi = sensor.psi;
    
    if isempty(sensor.tts)
        warning('Solar zenith angle will be calculated based on lat, lon, datetime, other angles keep nadir')
        solar_angles = helpers.solarPosition(sun.datetime, sun.lat, sun.lon, sun.tz, 0, sun.summertime);
        angles.tts = solar_angles(1);
        angles.tto = 0;
        angles.psi = 0;
    end
    
end
