function synthetic_val()

    % 5k
    % output_path = "D:\PyCharm_projects\demostrator\output\global_vegetation\synthetic\2019-12-24-124346.xlsx";
    % 10k
    % output_path = "D:\PyCharm_projects\demostrator\output\global_vegetation\synthetic\2019-12-24-135921.xlsx";
    % 50k
    output_path = "D:\PyCharm_projects\demostrator\output\global_vegetation\synthetic\2019-12-24-145649.xlsx";

    ret = xlsread(output_path, 'Output');
    rmse_spec = ret(1, :);
    ret = ret(2:15, :);
    tab_files = io.read_filenames_sheet(output_path, 'Filenames');
    path = io.table_to_struct(tab_files, 'path');
    val = readtable(path.validation);
    names = val.Var1;
    val = table2array(removevars(val, 'Var1'));
    
    tab = io.read_input_sheet(output_path);
    

    %% X - spectrum number, y - value
%     figure
%     n_cases = size(ret, 2);
%     for i = 1:length(names)
%         subplot(5, 3, i)
%         plot(1:n_cases, ret(i, :), 'o')
%         hold on
%         plot(1:n_cases, val(i, :))
%         rmse = sqrt(mean((ret(i, :) - val(i, :)) .^ 2));
%         title(sprintf("%s, RMSE = %.2g", names{i}, rmse))
%     end
    %% X - measured, y - modelled
    figure
    r = 4;
    c = 4;
    p_ind = {'LAI', 'LIDFa', 'LIDFb', 'gap', ...
             'Cab', 'Cca', 'Cant', 'Cdm', ...
             'Cw', 'Cs', 'N', 'legend',...
             'B', 'BSMlat', 'BSMlon', 'SMC'
            };
    % color by rmse
%     c_id = rmse_spec > 0.03;
    for i = 1:length(names)
        name_i = names{i};
        meas = val(i, :);
        mod = ret(i, :);
        subplot(r, c, find(strcmp(p_ind, name_i)))
        plot(meas, mod, 'ro')
%         scatter(meas, mod, 30, c_id, 'filled')
        hold on
        v_min = tab.lower(strcmp(tab.variable, name_i));
        v_max = tab.upper(strcmp(tab.variable, name_i));
        axis([v_min v_max v_min v_max])
        refline
        refline(1, 0)
        % metrics
        rmse = sqrt(mean((meas - mod) .^ 2));
        rrmse = rmse / mean(meas) * 100;
        % https://stats.stackexchange.com/questions/260615/what-is-the-difference-between-rrmse-and-rmsre
        i_nans = isnan(mod);
        lm_full = fitlm(meas(~i_nans), mod(~i_nans)); 
        title(sprintf("%s\nRMSE = %.2g (%.3g%%), \nR^2=%.2f", name_i, rmse, rrmse, lm_full.Rsquared.Adjusted))
    end
end