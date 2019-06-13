function [angles,projection] = solarPosition(datetime,latitude,longitude,time_zone,rotation,dst)
%SOLARPOSITION Calculate solar position using most basic algorithm
%   This is the most basic algorithm. It is documented in Seinfeld &
%   Pandis, Duffie & Beckman and Wikipedia.
%
% [ANGLES,PROJECTION] = SOLARPOSITION(DATE,TIME,LATITUDE,LONGITUDE,TIME_ZONE)
% returns ZENITH & AZIMUTH for all DATE & TIME pairs at LATITUDE, LONGITUDE.
% ANGLES = [ZENITH,AZIMUTH] and PROJECTION = [PHI_X, PHI_Y]
% PHI_X is projection on x-z plane & PHI_Y is projection on y-z plane.
% DATETIME can be string, vector [YEAR, MONTH, DAY, HOURS, MINUTES, SECONDS],
%   cellstring or matrix N x [YEAR, MONTH, DAY, HOURS, MINUTES, SECONDS] for N
%   times.
% LATITUDE [degrees] and LONGITUDE [degrees] are the coordinates of the site.
% TIME_ZONE [hours] of the site.
% ROTATION [degrees] clockwise rotation of system relative to north.
% DST [logical] flag for daylight savings time, typ. from March to November
%   in the northern hemisphere.
%
% References:
% http://en.wikipedia.org/wiki/Solar_azimuth_angle
% http://en.wikipedia.org/wiki/Solar_elevation_angle
%
% Mark A. Mikofski
% Copyright (c) 2013
%

%% datetime
    if iscellstr(datetime) || ~isvector(datetime)
        datetime = datenum(datetime); % [days] dates & times
    else
        datetime = datetime(:); % convert datenums to row
    end
    date = floor(datetime); % [days]
    [year,~,~] = datevec(date);
    time = datetime - date; % [days]
    %% constants
    toRadians = @(x)x*pi/180; % convert degrees to radians
    toDegrees = @(x)x*180/pi; % convert radians to degrees
    %% Equation of time
    d_n = mod(date-datenum(year,1,1)+1,365); % day number
    B = 2*pi*(d_n-81)/365; % ET parameter
    ET = 9.87*sin(2*B)-7.53*cos(B)-1.5*sin(B); % [minutes] equation of time
    % approximate solar time
    solarTime = ((time*24-double(dst))*60+4*(longitude-time_zone*15)+ET)/60/24;
    latitude_rad = toRadians(latitude); % [radians] latitude
    rotation_rad = toRadians(rotation); % [radians] field rotation
    t_h = (solarTime*24-12)*15; % [degrees] hour angle
    t_h_rad = toRadians(t_h); % [radians]
    delta = -23.45 * cos(2*pi*(d_n+10)/365); % [degrees] declination
    delta_rad = toRadians(delta); % [radians]
    theta_rad = acos(sin(latitude_rad)*sin(delta_rad)+ ...
        cos(latitude_rad)*cos(delta_rad).*cos(t_h_rad)); % [radians] zenith
    theta = toDegrees(theta_rad); % [degrees] zenith
    elevation = 90 - theta; % elevation
    day = elevation>0; % day or night?
    cos_phi = (cos(theta_rad)*sin(latitude_rad)- ...
        sin(delta_rad))./(sin(theta_rad)*cos(latitude_rad)); % cosine(azimuth)
    % azimuth [0, 180], absolute value measured from due south, so east = west = 90,
    % south = 0, north = 180
    phi_south = acos(min(1,max(-1,cos_phi)));
    % azimuth [0, 360], measured clockwise from due north, so east = 90,
    % south = 180, and west = 270 degrees
    phi_rad = NaN(size(phi_south)); % night azimuth is NaN
    % shift from ATAN to ATAN2, IE: use domain from 0 to 360 degrees instead of
    % from -180 to 180
    phi_rad(day) = pi + sign(t_h(day)).*phi_south(day); % Shift domain to 0-360 deg
    % projection of sun angle on x-z plane, measured from z-direction (up)
    phi_x = toDegrees(atan2(sin(phi_rad-rotation_rad).*sin(theta_rad), ...
        cos(theta_rad))); % [degrees]
    % projection of sun angle on y-z plane, measured from z-direction (up)
    phi_y = toDegrees(atan2(cos(phi_rad-rotation_rad).*sin(theta_rad), ...
        cos(theta_rad))); % [degrees]
    phi = toDegrees(phi_rad); % [degrees] azimuth
    angles = [theta, phi]; % [degrees] zenith, azimuth
    projection = [phi_x,phi_y]; % [degrees] x-z plane, y-z plane
end