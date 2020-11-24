
%%
path2.lut_input = '..\lut\MSI_99\lut_in.csv';
path2.lut_path = '..\lut\MSI_99\lut.mat';

% path2.lut_input = '..\lut\MSI_100\lut_in.csv';
% path2.lut_path = '..\lut\MSI_100\lut.mat';

lut_in = readtable(path2.lut_input);
par_names = lut_in.Properties.VariableNames;
lut_in = table2array(lut_in);


lut_spec = load(path2.lut_path);
lut_spec = lut_spec.lut_spec;


%%

rmse_full = sqrt(mean((lut_spec-measured.refl(:,10)').^2, 2));
figure
plot(lut_in(:, strcmp(par_names, 'LAI')), rmse_full, '.')


diff = lut_spec-measured.refl(:,1)';
for i=1:12
    subplot(3, 4, i)
    plot(lut_in(:, strcmp(par_names, 'LAI')), diff(:, i), '.')
    title(sprintf('cost function for B%d', i))
end

%% cost function
refl = readtable("D:\PyCharm_projects\demostrator\measured\synthetic\MSI\synthetic.csv");
refl = table2array(refl);
retrieved = parameters(12, :);
figure
for i=1:10
    subplot(2, 5, i)
    rmse_full2 = sqrt(mean((lut_spec-refl(:, i)').^2, 2));
    plot(lut_in(:, strcmp(par_names, 'LAI')), rmse_full2, '.')
    ylim([0, 0.25])
    yL = get(gca,'YLim');
    line([retrieved(i) retrieved(i)],yL,'Color','r');
    title(sprintf('%d', i))
    xlabel('LAI')
    ylabel('RMSE')
%     legend('cost function', 'NO mininum')
end

set(findall(gcf,'-property','FontSize'),'FontSize',12)
legend('cost function', 'NO mininum', 'FontSize', 20)
sgtitle({'Shape of cost functions for spectra from "synthetic.csv"', ...
    'only LAI was tuned'},'FontSize',20)

%% 2d cost

cab = lut_in(:, strcmp(par_names, 'Cab'));
lai = lut_in(:, strcmp(par_names, 'LAI'));
cost = sqrt(mean((lut_spec-refl(:, 7)').^2, 2));

figure
[X,Y] = meshgrid(cab,lai);
f = scatteredInterpolant(cab,lai,cost);
Z = f(X, Y);

% mesh(cab, lai, cost)
surf(X,Y,Z)
view(2)

%%
selection = 1:3;
% lut_in = lut_in(selection, :);
% lut_spec = lut_spec(selection, :);

%%

figure
subplot(2, 2, 1)
plot(measured.wl, lut_spec, 'o-')
title(sprintf('"lut.mat" content [n=%d]', size(lut_spec, 1)))
xlabel('Wavelength, nm')
ylabel('Reflectance')

subplot(2, 2, 2)
plot(measured.wl, measured.refl, 'kx-')
title('Measured (spectra to fit)')
xlabel('Wavelength, nm')
ylabel('Reflectance')

subplot(2, 2, [3, 4])
x = lut_spec(selection, :);
y = measured.refl(:,1);

rmse = sqrt(mean((x-y').^2, 2));

h1 = plot(measured.wl, x, 'o-', 'LineWidth', 3);
hold on
plot(measured.wl, y, 'kx-', 'LineWidth',5)

l = legend(arrayfun(@(x) num2str(round(x, 2)), rmse, 'UniformOutput', false));
title(l,'RMSE')
xlabel('Wavelength, nm')
ylabel('Reflectance')

title(sprintf('One measured in %d LUT', length(selection)))
set(findall(gcf,'-property','FontSize'),'FontSize',12)
%%

%% plot input parameters (without sif - 14)

c = 5;
r = 3;

b = cell2mat(get(h1, 'color'));
% selection = 1:99;
figure
var_names = tab.variable(~contains(tab.variable, 'SIF'));
for i = 1:length(var_names)
    name_i = var_names{i};
    subplot(r, c, i)
    col_i = strcmp(par_names, name_i);
    if any(col_i)
        for j=selection
            plot(1, lut_in(j, col_i)', 'o', 'MarkerFaceColor', b(j,:), 'MarkerSize',15, 'MarkerEdgeColor', 'k')
            hold on
        end
%         h1 = plot(1, lut_in(:, col_i)', 'o');
%         set(h1, 'markerfacecolor', get(h1, 'color'))
    else
        plot(tab.value(i), 'o')
    end
    title(name_i)
    ylim([tab.lower(i), tab.upper(i)])
%     xticklabels([])
    set(gca(), 'xtick',[])
end
set(findall(gcf,'-property','FontSize'),'FontSize',12)
sgtitle('parameters from "lut_in.csv"', 'interpreter', 'none', 'fontSize', 20)

% set(findall(gcf,'-property','FontSize'),'FontSize',18)
%% loss function

