function jacobian_svd(J2, tab, fit_wl, j)
    
    figure(j*100)

    iparams = tab.include;
    UB = tab.upper(iparams)';
    LB = tab.lower(iparams)';
    parnames = tab.variable(iparams);
    n_fit_params = length(parnames);
    nrow = 3;
    ncol = ceil(n_fit_params / nrow);

    coeff = repmat(UB - LB, size(J2, 1), 1);
    J_norm = J2(:, iparams) .* coeff;

    [U,S,V] = svd(J_norm, 0);
    diagS = diag(S);

    for k = 1:n_fit_params
        subplot(nrow, ncol, k);
        plot(fit_wl, U(:,k), 'k')

        xlim([min(fit_wl), max(fit_wl)])

        str1 = sprintf('U %s', parnames{k});
        str2 = sprintf('S=%0.2f', diagS(k));
        title({str1, str2},'FontSize',9) 
    end
    sgtitle(sprintf('SVD of Jacobian for spectra # %d', j))
end