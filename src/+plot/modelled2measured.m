function modelled2measured(modelled, measured_tab, tab, graph_name)
    
    %% measured data from table to matrix, keep names 
    measured_names = table2array(measured_tab(:, 1));
    measured_tab(:, 1) = [];
    names = measured_tab.Properties.VariableNames;
    measured = table2array(measured_tab);
    
    %% modelled names and ranges
    modelled_names = tab.variable;
    include_i = tab.include;
    lower = tab.lower;
    upper = tab.upper;

    %% find groups based on column names
    names_spl = split(names, '_');                      % split column headers by '_'
    [groups, ~, group_id] = unique(names_spl(:,:, 1));  % see if there is any logic behind colnames
    n_spectra = size(measured, 2);
    if length(groups) < n_spectra
        n_colors = length(groups);
        color_names = groups;
        scatter_my = @(meas, mod) scatter(meas, mod, 100, group_id, 'filled');
    else
        n_colors = n_spectra;
        group_id = 1:n_colors;
        scatter_my = @(meas, mod) scatter(meas, mod, 100, group_id);
        color_names = cellstr(num2str(group_id'));
    end
    
    %% find which validation variables where provided
    [vars, i_meas, i_mod] = intersect(measured_names, modelled_names, 'stable');
    
    %% define subplot parameters
    n_plots = length(vars) + 1;  % +1 for legend
    n_row = 1;
    if n_plots > 4
        n_row = 2;
    end
    n_col = round(n_plots / n_row);
    
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
        rmse = sqrt(nanmean((meas-mod) .^ 2));
        lm = fitlm(meas, mod);
        bias = nanmean(mod - meas);
        title(sprintf('%s\n%.2f (rmse), %.2f (bias), \\color{red}%.2f (r^2adj)',...
            vars{i}, rmse, bias, lm.Rsquared.Adjusted))
        xlabel('measured')
        ylabel('modelled')
        hold on
        refline(1, 0)
        axis([lower(i_mod(i)), upper(i_mod(i)), lower(i_mod(i)), upper(i_mod(i))])
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
    n_fit = length(modelled_names(include_i));
    x = ones(n_fit, 1);
    y = 1:n_fit;
    % plotting off axis to produce legend
    scatter(-1, -1, 10, 'filled')
    refline(0, -1)
    text(x, flip(y), modelled_names(include_i), 'HorizontalAlignment', 'center')
    legend('data', '1:1', 'Location', 'bestoutside')
    % axis limits does not allow to show scatter and refline
    axis([0 2 0 n_fit + 1])
    title('These variables where tuned')
    
    colormap(jet(n_colors))
    caxis([1, n_colors])
    colorbar('YTick', 1 + 0.5*(n_colors-1)/n_colors:(n_colors-1)/n_colors:n_colors, ...
             'YTickLabel', color_names)

end