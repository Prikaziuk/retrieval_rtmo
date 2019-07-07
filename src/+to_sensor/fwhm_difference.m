load asd.mat  % asd = [measurement.wl, Esun_, Esky_, piL_, refl]
load fwhm_one.mat

subplot(1, 2, 1)
plot(fwhm_one(:, 1), fwhm_one(:, 4), 'r')
hold on
plot(asd(:, 1), asd(:, 4), 'bx') 
title('Reflected radiance')
xlim([400 2400])
legend('FWHM = 1', 'FWHM SWIR = 10 (ASD)')

subplot(1, 2, 2)
plot(fwhm_one(:, 1), fwhm_one(:, 5), 'r')
hold on
plot(asd(:, 1), asd(:, 5), 'bx') 
title('Reflectance')
xlim([400 2400])
legend('FWHM = 1', 'FWHM SWIR = 10 (ASD)')

set(findall(gcf, '-property', 'FontSize'), 'FontSize', 30)