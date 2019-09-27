function fixed = read_fixed_input()


    %% define spectral regions
    spectral.wlP = 400:1:2400;                      % PROSPECT data range
    spectral.wlE = 400:1:750;                       % excitation in E-F matrix
    spectral.wlF = 640:1:850;                       % chlorophyll fluorescence in E-F matrix

    %% fixed input for SIF simulation with PCA
    PCflu = xlsread(fullfile('..', 'input', 'PC_flu.xlsx'));
    pcf   = PCflu(2:end, 2:5);

    %% fixed input for FLUSPECT and BSM
    optipar = load(fullfile('..', 'input', 'fluspect_data', 'Optipar2017_ProspectD'));
    
    %% collect
    fixed.spectral = spectral;
    fixed.pcf = pcf;
    fixed.optipar = optipar.optipar;
    fixed.srf_sensors = {'S3A_OLCI', 'MSI', 'altum', 'altum_09', 'sensorh_a_m', 'SLSTR', 'Synergy'};
end