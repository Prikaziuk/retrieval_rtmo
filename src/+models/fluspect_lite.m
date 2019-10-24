 function leafopt = fluspect_B_CX_PSI_PSII_combined(spectral,leafbio,optipar)
%
% function [leafopt] = fluspect(spectral,leafbio,optipar)
% calculates reflectance and transmittance spectra of a leaf using FLUSPECT, 
% plus four excitation-fluorescence matrices
%
% Authors: Wout Verhoef, Christiaan van der Tol (tol@itc.nl), Joris Timmermans, 
% Date: 2007
% Update from PROSPECT to FLUSPECT: January 2011 (CvdT)
%
%      Nov 2012 (CvdT) Output EF-matrices separately for PSI and PSII
%   31 Jan 2013 (WV)   Adapt to SCOPE v_1.40, using structures for I/O
%   30 May 2013 (WV)   Repair bug in s for non-conservative scattering
%   24 Nov 2013 (WV)   Simplified doubling routine
%   25 Nov 2013 (WV)   Restored piece of code that takes final refl and
%                      tran outputs as a basis for the doubling routine
%   03 Dec 2013 (WV)   Major upgrade. Border interfaces are removed before 
%                      the fluorescence calculation and later added again
%   23 Dec 2013 (WV)   Correct a problem with N = 1 when calculating k 
%                      and s; a test on a = Inf was included
%   01 Apr 2014 (WV)   Add carotenoid concentration (Cca and Kca)
%   19 Jan 2015 (WV)   First beta version for simulation of PRI effect
%   17 Mar 2017 (CT)   Added Anthocyanins according to Prospect-D
%
% usage:
% [leafopt] = fluspect_b(spectral,leafbio,optipar)
% 
% inputs:
% Cab         = leafbio.Cab;
% Cca         = leafbio.Cca;
% V2Z         = leafbio.V2Z;  % Violaxanthin - Zeaxanthin transition status
%                               [0-1]
% Cw          = leafbio.Cw;
% Cdm         = leafbio.Cdm;
% Cs          = leafbio.Cs;
% Cant 	      = leafbio.Cant;
% N           = leafbio.N; 
% fqe         = leafbio.fqe;
% 
% nr          = optipar.nr;
% Kdm         = optipar.Kdm;
% Kab         = optipar.Kab;
% Kca         = optipar.Kca;
% KcaV        = optipar.KcaV;
% KcaZ        = optipar.KcaZ;
% Kw          = optipar.Kw;
% Ks          = optipar.Ks;
% phi         = optipar.phi;
% outputs:
% refl          reflectance
% tran          transmittance
% Mb            backward scattering fluorescence matrix, I for PSI and II for PSII
% Mf            forward scattering fluorescence matrix,  I for PSI and II for PSII

%% parameters
% fixed parameters for the fluorescence module
ndub        = 15;           % number of doublings applied

% Fluspect parameters
Cab         = leafbio.Cab;
Cca         = leafbio.Cca;
V2Z         = leafbio.V2Z;
Cw          = leafbio.Cw;
Cdm         = leafbio.Cdm;
Cs          = leafbio.Cs;
Cant 	    = leafbio.Cant;
N           = leafbio.N;
fqe         = leafbio.fqe;

nr          = optipar.nr;
Kdm         = optipar.Kdm;
Kab         = optipar.Kab;

if V2Z == -999 
    % Use old Kca spectrum if this is given as input
    Kca     = optipar.Kca;
else
    % Otherwise make linear combination based on V2Z
    % For V2Z going from 0 to 1 we go from Viola to Zea
    Kca     = (1-V2Z) * optipar.KcaV + V2Z * optipar.KcaZ;    
end

Kw          = optipar.Kw;
Ks          = optipar.Ks;
Kant        = optipar.Kant;
phi         = optipar.phi;

%% PROSPECT calculations
Kall        = (Cab*Kab + Cca*Kca + Cdm*Kdm + Cw*Kw  + Cs*Ks + Cant*Kant)/N;   % Compact leaf layer

j           = find(Kall>0);               % Non-conservative scattering (normal case)
t1          = (1-Kall).*exp(-Kall);
t2          = Kall.^2.*expint(Kall);
tau         = ones(size(t1));
tau(j)      = t1(j)+t2(j);
kChlrel     = zeros(size(t1));
kChlrel(j)  = Cab*Kab(j)./(Kall(j)*N);

talf        = calctav(59,nr);
ralf        = 1-talf;
t12         = calctav(90,nr);
r12         = 1-t12;
t21         = t12./(nr.^2);
r21         = 1-t21;

% top surface side
denom       = 1-r21.*r21.*tau.^2;
Ta          = talf.*tau.*t21./denom;
Ra          = ralf+r21.*tau.*Ta;

% bottom surface side
t           = t12.*tau.*t21./denom;
r           = r12+r21.*tau.*t;

% Stokes equations to compute properties of next N-1 layers (N real)
% Normal case

D           = sqrt((1+r+t).*(1+r-t).*(1-r+t).*(1-r-t));
rq          = r.^2;
tq          = t.^2;
a           = (1+rq-tq+D)./(2*r);
b           = (1-rq+tq+D)./(2*t);

bNm1        = b.^(N-1);                  %
bN2         = bNm1.^2;
a2          = a.^2;
denom       = a2.*bN2-1;
Rsub        = a.*(bN2-1)./denom;
Tsub        = bNm1.*(a2-1)./denom;

%			Case of zero absorption
j           = find(r+t >= 1);
Tsub(j)     = t(j)./(t(j)+(1-t(j))*(N-1));
Rsub(j)	    = 1-Tsub(j);

% Reflectance and transmittance of the leaf: combine top layer with next N-1 layers
denom       = 1-Rsub.*r;
tran        = Ta.*Tsub./denom;
refl        = Ra+Ta.*Rsub.*t./denom;

leafopt.refl = refl;
leafopt.tran = tran;
leafopt.kChlrel = kChlrel;
 end

function tav = calctav(alfa,nr)

    rd          = pi/180;
    n2          = nr.^2;
    np          = n2+1;
    nm          = n2-1;
    a           = (nr+1).*(nr+1)/2;
    k           = -(n2-1).*(n2-1)/4;
    sa          = sin(alfa.*rd);

    b1          = (alfa~=90)*sqrt((sa.^2-np/2).*(sa.^2-np/2)+k);
    b2          = sa.^2-np/2;
    b           = b1-b2;
    b3          = b.^3;
    a3          = a.^3;
    ts          = (k.^2./(6*b3)+k./b-b/2)-(k.^2./(6*a3)+k./a-a/2);

    tp1         = -2*n2.*(b-a)./(np.^2);
    tp2         = -2*n2.*np.*log(b./a)./(nm.^2);
    tp3         = n2.*(1./b-1./a)/2;
    tp4         = 16*n2.^2.*(n2.^2+1).*log((2*np.*b-nm.^2)./(2*np.*a-nm.^2))./(np.^3.*nm.^2);
    tp5         = 16*n2.^3.*(1./(2*np.*b-nm.^2)-1./(2*np.*a-nm.^2))./(np.^3);
    tp          = tp1+tp2+tp3+tp4+tp5;
    tav         = (ts+tp)./(2*sa.^2);
end