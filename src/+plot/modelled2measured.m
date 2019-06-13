function modelled2measured(modelled, tab, measured_tab, graph_name, filled)

    %% to fill or not to fill (to make number visible)
    if nargin < 5
        filled = false;
    end
    
    %% measured data from table to matrix, keep names 
    measured_names = table2array(measured_tab(:, 1));
    measured_tab(:, 1) = [];
    names = measured_tab.Properties.VariableNames;
    measured = table2array(measured_tab);
    
    %% modelled names and ranges
%     modelled_names = tab.variable;
%     include_i = tab.include;
%     lower = tab.lower;
%     upper = tab.upper;

    %% find groups based on column names
    names_spl = split(names, '_');                      % split column headers by '_'
    [groups, ~, group_id] = unique(names_spl(:,:, 1));  % see if there is any logic behind colnames
    n_spectra = size(measured, 2);
    if length(groups) < n_spectra % filled
        n_colors = length(groups);
        color_names = groups;
        if filled
            scatter_my = @(meas, mod) scatter(meas, mod, 100, group_id, 'filled');
        else
            scatter_my = @(meas, mod) scatter(meas, mod, 100, group_id);
        end
    else
        n_colors = n_spectra;
        group_id = 1:n_colors;
        scatter_my = @(meas, mod) scatter(meas, mod, 100, group_id);
        color_names = cellstr(num2str(group_id'));
    end
    
    %% find which validation variables where provided
    [vars, i_meas, i_mod] = intersect(measured_names, tab.variable, 'stable');
    
    %% define subplot parameters
    n_plots = length(vars) + 1;  % +1 for legend
    n_row = 1;
    if n_plots > 4
        n_row = 2;
    end
    n_col = round(n_plots / n_row);
    min_val = tab.lower(i_mod);
    max_val = tab.upper(i_mod);
    
    figure(1e9)  % to prevent overlapping with any other figures
    for i = 1:length(vars)
        subplot(n_row, n_col, i)
        mod = modelled(i_mod(i), :);
        meas = measured(i_meas(i), :);
        scatter_my(meas, mod)
        for j = 1:n_spectra
            text(meas(j), mod(j), num2str(j), 'HorizontalAlignment', 'center')
            hold on
        end
        % liner model
        i_nans = isnan(meas);
        lm_full = fitlm(meas(~i_nans), mod(~i_nans));   
        lm = polyfit(meas(~i_nans), mod(~i_nans), 1);
        fit = polyval(lm, meas);
        plot(meas, fit, 'r:')  % refline(lm(1), lm(2))
        % metrics
        rmse = sqrt(nanmean((meas-mod) .^ 2));
        bias = nanmean(mod - meas);
        title(sprintf('%s\n%.2f (rmse), %.2f (bias), \\color{red}%.2f (r^2adj)',...
            vars{i}, rmse, bias, lm_full.Rsquared.Adjusted))
        xlabel('measured')
        ylabel('modelled')
        hold on
        refline(1, 0)
        axis([min_val(i), max_val(i), min_val(i), max_val(i)])
    end
    
    if verLessThan('matlab', '9.5')
        V = ver;
        if any(strcmp({V.Name}, 'Bioinformatics Toolbox'))
            suptitle(graph_name)
        end
    else
        sgtitle(graph_name)
    end
    
    %% final plot with simulation parameters, legend and colorbar
    subplot(n_row, n_col, i + 1)
    fitted_varnames = tab.variable(tab.include);
    n_fit = length(fitted_varnames);
    x = ones(n_fit, 1);
    y = 1:n_fit;
    % plotting off axis to produce legend
    scatter(-1, -1, 10, 'filled')
    refline(0, -1)
    text(x, flip(y), fitted_varnames, 'HorizontalAlignment', 'center', 'Interpreter', 'none')
    legend('data', '1:1', 'Location', 'bestoutside')
    % axis limits does not allow to show scatter and refline
    axis([0 2 0 n_fit + 1])
    title('These variables where tuned')
    
    if n_colors > 1
        colormap(jet(n_colors))
        caxis([1, n_colors])
        colorbar('YTick', 1 + 0.5*(n_colors-1)/n_colors:(n_colors-1)/n_colors:n_colors, ...
                 'YTickLabel', color_names)
    end
         

end