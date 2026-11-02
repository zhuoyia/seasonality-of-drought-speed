%% Seasonal variation of drought-onset speed across four climate regions

clear; clc; close all;
%% ======================= 1. Style settings ===============================
fontName = 'Arial';
fsTick   = 6;
fsLabel  = 8.0;
fsNote   = 8;
fsPanel  = 8;

colorRate = [0.0000, 0.4470, 0.7410]; % onset rate: blue
colorTime = [0.8500, 0.3250, 0.0980]; % onset time: orange
colorGrey = [0.45, 0.45, 0.45];

% %% ======================= 2. Load data ====================================
% % Only datasets needed by the four regional time-series panels are loaded.
% load('E:\100.doctoral\GPP_response_doctoral_260709.mat');
% load('E:\101\mask\area_600_1440.mat');
% load('E:\101\mask\koppen.mat');
% 
% area = area(:);
% koppenRaw = double(koppen(:));
% 
% % Aggregate the original Koeppen classes into four climate regions.
% koppenGroup = nan(size(koppenRaw));
% koppenGroup(koppenRaw >= 1  & koppenRaw <= 3)  = 1; % Tropical
% koppenGroup(koppenRaw >= 4  & koppenRaw <= 7)  = 2; % Arid
% koppenGroup(koppenRaw >= 8  & koppenRaw <= 16) = 3; % Temperate
% koppenGroup(koppenRaw >= 17 & koppenRaw <= 30) = 4; % Boreal
% 
% smDataset = {'ERA5_GOSIF', 'GLDAS_GOSIF', 'GLEAM_GOSIF'};
% nModels = numel(smDataset);
% 
% %% ======================= 3. Regional aggregation =========================
% % Dimension 3 stores the three products followed by ensemble mean and SD.
% nRegions = 4;
% nPentads = 46;
% idxMean = nModels + 1;
% idxStd  = nModels + 2;
% TimingRate = cell(nRegions, 3);
% 
% for region = 1:nRegions
%     for metric = 1:3
%         TimingRate{region, metric} = nan(3, nPentads, nModels + 2);
%     end
% end
% 
% for k = 1:nModels
%     eventTable = GPP_response.(smDataset{k});
%     eventTable(isnan(eventTable.gpp_loss), :) = [];
% 
%     eventTable.pentad_timing = ceil(eventTable.pentad_onset);
%     eventTable.pentad_timing = mod(eventTable.pentad_timing - 1, nPentads) + 1;
% 
%     % Shift Southern Hemisphere timing by half a year.
%     idxShift = mod(eventTable.pixel_id - 1, 600) + 1 > 360;
%     eventTable.pentad_timing(idxShift) = eventTable.pentad_timing(idxShift) + 23;
%     eventTable.pentad_timing = mod(eventTable.pentad_timing - 1, nPentads) + 1;
% 
%     pixelRegion = koppenGroup(eventTable.pixel_id);
%     events = cell(nRegions, 3);
%     for region = 1:nRegions
%         events{region, 1} = eventTable(pixelRegion == region, :);
%         events{region, 2} = events{region, 1}(events{region, 1}.type == 1, :);
%         events{region, 3} = events{region, 1}(events{region, 1}.type == 2, :);
% 
%         % cat = 1 retains all drought events, matching the original script.
%         cat = 1;
%         currentEvents = events{region, cat};
%         eventArea = area(currentEvents.pixel_id);
% 
%         rateSum = accumarray(currentEvents.pentad_timing, ...
%             currentEvents.onset_rate .* eventArea, [nPentads 1], @sum, 0);
%         areaSum = accumarray(currentEvents.pentad_timing, ...
%             eventArea, [nPentads 1], @sum, 0);
%         weightedRate = rateSum ./ areaSum;
%         weightedRate(areaSum == 0) = nan;
%         TimingRate{region, 1}(cat, :, k) = weightedRate;
% 
%         timeSum = accumarray(currentEvents.pentad_timing, ...
%             currentEvents.onset_time .* eventArea, [nPentads 1], @sum, 0);
%         weightedTime = timeSum ./ areaSum;
%         weightedTime(areaSum == 0) = nan;
%         TimingRate{region, 2}(cat, :, k) = weightedTime;
% 
%         type1 = currentEvents.type == 1;
%         type1Area = accumarray(currentEvents.pentad_timing(type1), ...
%             eventArea(type1), [nPentads 1], @sum, 0);
%         type1Fraction = type1Area ./ areaSum;
%         type1Fraction(areaSum == 0) = nan;
%         TimingRate{region, 3}(cat, :, k) = type1Fraction;
%     end
% end
% 
% % Ensemble mean and inter-product standard deviation.
% for region = 1:nRegions
%     for metric = 1:3
%         TimingRate{region, metric}(:, :, idxMean) = ...
%             mean(TimingRate{region, metric}(:, :, 1:nModels), 3, 'omitnan');
%         TimingRate{region, metric}(:, :, idxStd) = ...
%             std(TimingRate{region, metric}(:, :, 1:nModels), 0, 3, 'omitnan');
%     end
% end

%% ======================= 4. Figure =======================================
fig = figure('Color', 'w', 'Units', 'centimeters', ...
    'Position', [2, 2, 12, 18], 'Renderer', 'painters');

load('TimingRate2')
layout = tiledlayout(fig, 3, 2, ...
    'TileSpacing', 'compact', 'Padding', 'compact');

% ---- Panel a: conceptual definition of drought-onset speed ---------------
axConcept = nexttile(layout, 1, [1 2]);
drawOnsetConcept(axConcept, colorRate, colorTime, colorGrey, ...
    fontName, fsTick, fsLabel, fsNote, fsPanel);

% ---- Panels b-e: regional seasonal variations ----------------------------
xAxis = 1:nPentads;
regionNames = {'Tropical', 'Arid', 'Temperate', 'Boreal'};
panelLetters = {'b', 'c', 'd', 'e'};
rateYLim = [1.4 2.6; 1.1 1.9; 1.4 2.1; 1.0 2.2];
timeYLim = [14 28; 18 34; 16 28; 15 40];
regionalAxes = gobjects(nRegions, 1);
cat = 1;

for region = 1:nRegions
    ax = nexttile(layout, region + 2);
    regionalAxes(region) = ax;

    dataRate = squeeze(TimingRate{region, 1}(cat, :, idxMean));
    stdRate  = squeeze(TimingRate{region, 1}(cat, :, idxStd));
    dataTime = squeeze(TimingRate{region, 2}(cat, :, idxMean));
    stdTime  = squeeze(TimingRate{region, 2}(cat, :, idxStd));

    % Left axis: onset rate.
    yyaxis(ax, 'left');
    hold(ax, 'on');
    rateMean = movmean(dataRate, 5, 'omitnan') / 8;
    rateSD   = movmean(stdRate,  5, 'omitnan') / 8;
    validRate = ~isnan(rateMean) & ~isnan(rateSD);
    xRate = xAxis(validRate);
    yRate = rateMean(validRate);
    sRate = rateSD(validRate);

    if ~isempty(xRate)
        fill(ax, [xRate, fliplr(xRate)], ...
            [yRate + sRate, fliplr(yRate - sRate)], colorRate, ...
            'FaceAlpha', 0.25, 'EdgeColor', 'none');
        plot(ax, xRate, yRate, 'Color', colorRate, 'LineWidth', 1.5);
        rateReference = mean(dataRate, 'omitnan') / 8;
        plot(ax, [1 nPentads], [rateReference rateReference], '--', ...
            'Color', colorRate, 'LineWidth', 1.0);
        displayRateMean = mean(yRate, 'omitnan');
        displayRateSD = std(yRate, 0, 'omitnan');
    else
        displayRateMean = nan;
        displayRateSD = nan;
    end

    ax.YColor = colorRate;
    ylim(ax, rateYLim(region, :));
    yticks(ax, 'auto');
    if mod(region, 2) == 1
        ylabel(ax, 'Onset rate (% day^{-1})', ...
            'FontName', fontName, 'FontSize', fsLabel, 'Color', colorRate);
    end

    % Right axis: onset time.
    yyaxis(ax, 'right');
    hold(ax, 'on');
    timeMean = movmean(dataTime, 5, 'omitnan') * 8;
    timeSD   = movmean(stdTime,  5, 'omitnan') * 8;
    validTime = ~isnan(timeMean) & ~isnan(timeSD);
    xTime = xAxis(validTime);
    yTime = timeMean(validTime);
    sTime = timeSD(validTime);

    if ~isempty(xTime)
        fill(ax, [xTime, fliplr(xTime)], ...
            [yTime + sTime, fliplr(yTime - sTime)], colorTime, ...
            'FaceAlpha', 0.25, 'EdgeColor', 'none');
        plot(ax, xTime, yTime, 'Color', colorTime, 'LineWidth', 1.5);
        timeReference = mean(dataTime, 'omitnan') * 8;
        plot(ax, [1 nPentads], [timeReference timeReference], '--', ...
            'Color', colorTime, 'LineWidth', 1.0);
        displayTimeMean = mean(yTime, 'omitnan');
        displayTimeSD = std(yTime, 0, 'omitnan');
    else
        displayTimeMean = nan;
        displayTimeSD = nan;
    end

    ax.YColor = colorTime;
    ylim(ax, timeYLim(region, :));
    yticks(ax, 'auto');
    if mod(region, 2) == 0
        ylabel(ax, 'Onset time (days)', ...
            'FontName', fontName, 'FontSize', fsLabel, 'Color', colorTime);
    end

    % Direct statistical summary.
    summaryText = sprintf(['\\color[rgb]{0,0.447,0.741}{Rate}: %.2f \\pm %.2f\n' ...
        '\\color[rgb]{0.85,0.325,0.098}{Time}: %.2f \\pm %.2f'], ...
        displayRateMean, displayRateSD, displayTimeMean, displayTimeSD);
    text(ax, 0.065, 0.94, summaryText, 'Units', 'normalized', ...
        'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
        'FontName', fontName, 'FontSize', fsNote, 'FontWeight', 'bold', ...
        'Interpreter', 'tex', 'Color', [0 0 0]);

    xlim(ax, [1 nPentads]);
    xticks(ax, [59 151 243 334] / 8 + 0.5);
    xticklabels(ax, {'59', '151', '243', '334'});
    xlabel(ax, 'Drought-onset timing (DOY)', ...
        'FontName', fontName, 'FontSize', fsLabel);
    title(ax, sprintf('%s  %s', panelLetters{region}, regionNames{region}), ...
        'FontName', fontName, 'FontSize', fsPanel, 'FontWeight', 'normal');

    set(ax, 'FontName', fontName, 'FontSize', fsTick, ...
        'LineWidth', 0.8, 'TickDir', 'out', 'Box', 'on', 'Layer', 'top');
    hold(ax, 'off');
end

%% ======================= 5. Export =======================================
%% ---------------------------
% 导出图片
% ---------------------------
output_file = 'E:\100.doctoral\34.timing_on_rate\figure\F1_seasonal_variation_onset_speed_concept.png';
print(output_file, fig, '-r600', '-dpng');

%% ======================= Local function ==================================
function drawOnsetConcept(ax, colorCurve, colorOnset, colorGrey, ...
    fontName, fsTick, fsLabel, fsNote, fsPanel)
% Draw a compact conceptual definition without implying observed values.

hold(ax, 'on');
xlim(ax, [0 74]);
ylim(ax, [0 78]);

eventFill = [0.82, 0.88, 0.94];
intenseFill = [0.99, 0.91, 0.78];

tNode = [0 7 14 19 26 34 42 50 58 66 74];
pNode = [50 49 46 43 31 19 11 15 25 41 47];
t = linspace(0, 74, 800);
p = interp1(tNode, pNode, t, 'pchip');

i40Down = find(p(1:end-1) >= 40 & p(2:end) < 40, 1, 'first');
i20Down = find(p(1:end-1) >= 20 & p(2:end) < 20, 1, 'first');
i40UpAll = find(p(1:end-1) < 40 & p(2:end) >= 40);
i40Up = i40UpAll(find(i40UpAll > i20Down, 1, 'first'));

t40 = interp1(p(i40Down:i40Down+1), t(i40Down:i40Down+1), 40);
t20 = interp1(p(i20Down:i20Down+1), t(i20Down:i20Down+1), 20);
tEnd = interp1(p(i40Up:i40Up+1), t(i40Up:i40Up+1), 40);

patch(ax, [t40 tEnd tEnd t40], [0 0 40 40], eventFill, ...
    'EdgeColor', 'none', 'FaceAlpha', 0.48);
patch(ax, [t20 tEnd tEnd t20], [0 0 20 20], intenseFill, ...
    'EdgeColor', 'none', 'FaceAlpha', 0.62);

% Threshold lines are retained without explanatory grey labels.
yline(ax, 40, '--', 'Color', colorGrey, 'LineWidth', 1.0);
yline(ax, 20, '--', 'Color', colorGrey, 'LineWidth', 1.0);

plot(ax, t, p, '-', 'Color', colorCurve, 'LineWidth', 2.2);
onsetMask = t >= t40 & t <= t20;
plot(ax, t(onsetMask), p(onsetMask), '-', ...
    'Color', colorOnset, 'LineWidth', 4.0);

plot(ax, t40, 40, 'o', 'MarkerSize', 5.5, 'MarkerFaceColor', 'w', ...
    'MarkerEdgeColor', colorOnset, 'LineWidth', 1.4);
plot(ax, t20, 20, 'o', 'MarkerSize', 5.5, 'MarkerFaceColor', 'w', ...
    'MarkerEdgeColor', colorOnset, 'LineWidth', 1.4);

plot(ax, [t40 t40], [5 40], ':', 'Color', colorOnset, 'LineWidth', 1.0);
plot(ax, [t20 t20], [5 20], ':', 'Color', colorOnset, 'LineWidth', 1.0);

yArrow = 6.5;
quiver(ax, t40, yArrow, t20 - t40, 0, 0, 'Color', colorOnset, ...
    'LineWidth', 1.3, 'MaxHeadSize', 0.35);
quiver(ax, t20, yArrow, t40 - t20, 0, 0, 'Color', colorOnset, ...
    'LineWidth', 1.3, 'MaxHeadSize', 0.35);
text(ax, mean([t40 t20]), yArrow + 2.2, 'Onset time = t_{20} - t_{40}', ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
    'FontName', fontName, 'FontSize', fsNote, 'FontWeight', 'bold', ...
    'Color', colorOnset, 'Interpreter', 'tex');

tMid = mean([t40 t20]);
pMid = interp1(t, p, tMid);
text(ax, 39.5, 48.0, {'Onset rate (mean decline)', ...
    '= (P_{40} - P_{20}) / (t_{20} - t_{40})', ...
    'Higher rate = faster onset'}, ...
    'FontName', fontName, 'FontSize', fsNote, 'Color', colorOnset, ...
    'Interpreter', 'tex', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'middle');
quiver(ax, 39.0, 53.5, tMid - 39.0, pMid - 53.5, 0, ...
    'Color', colorOnset, 'LineWidth', 1.1, 'MaxHeadSize', 0.35);
text(ax, t40, 43.7, 't_{40}', 'FontName', fontName, ...
    'FontSize', fsNote, 'Color', colorOnset, ...
    'HorizontalAlignment', 'center', 'Interpreter', 'tex');
text(ax, t20, 23.7, 't_{20}', 'FontName', fontName, ...
    'FontSize', fsNote, 'Color', colorOnset, ...
    'HorizontalAlignment', 'center', 'Interpreter', 'tex');

% Compact in-panel legend.
plot(ax, [51 55], [72 72], '-', 'Color', colorCurve, 'LineWidth', 2.2);
text(ax, 56, 72, 'SM percentile', 'FontName', fontName, ...
    'FontSize', fsNote, 'VerticalAlignment', 'middle', 'Color', colorCurve);
plot(ax, [51 55], [67 67], '-', 'Color', colorOnset, 'LineWidth', 4.0);
text(ax, 56, 67, 'Onset phase', 'FontName', fontName, ...
    'FontSize', fsNote, 'VerticalAlignment', 'middle', 'Color', colorOnset);

xlabel(ax, 'Time (days)', 'FontName', fontName, 'FontSize', fsLabel);
ylabel(ax, 'Soil-moisture percentile', ...
    'FontName', fontName, 'FontSize', fsLabel);
set(ax, 'FontName', fontName, 'FontSize', fsTick, 'LineWidth', 0.8, ...
    'TickDir', 'out', 'Box', 'on', 'Layer', 'top', ...
    'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
yticks(ax, [0 20 40 60]);
xticks(ax, 0:10:70);

text(ax, -0.020, 1.020, 'a', 'Units', 'normalized', ...
    'FontName', fontName, 'FontSize', fsPanel, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'bottom', ...
    'Clipping', 'off', 'Color', [0.05 0.05 0.05]);
text(ax, 0.012, 1.020, 'Schematic diagram', ...
    'Units', 'normalized', 'FontName', fontName, 'FontSize', fsPanel, ...
    'FontWeight', 'normal', 'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'bottom', 'Clipping', 'off', ...
    'Color', [0.05 0.05 0.05]);

hold(ax, 'off');
end
