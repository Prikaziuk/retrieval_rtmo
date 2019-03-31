function jacobian(J2, tab, fit_wl, j)

    figure(j*10)

    iparams = tab.include;
    UB = tab.upper(iparams)';
    LB = tab.lower(iparams)';
    parnames = tab.variable(iparams);
    n_fit_params = length(parnames);
    nrow = 3;
    ncol = ceil(n_fit_params / nrow);

    coeff = repmat(UB - LB, size(J2, 1), 1);
    J_norm = J2(:, iparams) .* coeff;

    for k = 1:n_fit_params
        subplot(nrow, ncol, k)
        plot(fit_wl, J_norm(:,k))
        title(parnames(k))
        xlim([min(fit_wl), max(fit_wl)])
    end
    suptitle(sprintf('Jacobian values for spectra # %d', j))
end