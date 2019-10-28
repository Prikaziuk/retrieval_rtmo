% files = dir('../cubes/*.nc');

sites = readtable('sites.csv');
n_sites = size(sites, 1);

% sites.site_name = strrep(sites.site_code, '-', '_');

for i=1:n_sites
    nc_name = [sites.site_name{i} '.nc'];
    lat = sites.lat(i);
    lon = sites.lon(i);
    main_sat_fun(nc_name, lat, lon)
    disp('done')
end
