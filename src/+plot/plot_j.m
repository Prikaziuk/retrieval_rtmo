function plot_j(j, results_j, uncertainty_j, measurement, tab)



    plot.reflectance(measurement.wl, results_j.refl_mod,  measurement.refl, j, results_j.rmse)
%         plot.jacobian(uncertainty_j.J, tab, measurement.wl(measurement.i_fit), j)
    %     plot.jacobian_svd(uncertainty_j.J, tab, measurement.wl(measurement.i_fit), j)

end