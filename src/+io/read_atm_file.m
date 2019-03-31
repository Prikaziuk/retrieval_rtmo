function T = read_atm_file(atmfile, wl, FWHM)

    s       = importdata(atmfile);
    wlMODT  = s.data(:,2);
    T0      = s.data(:,3:14);
    T1      = T0(:,[1,3,4,5,12]);
    HFWHM   = FWHM/2;

    T       = zeros(length(wl),5);
    for k = 1:length(wl)
        T(k,:)  = mean(T1(wlMODT > (wl(k)-HFWHM) & wlMODT < (wl(k) + HFWHM), :));
    end

end