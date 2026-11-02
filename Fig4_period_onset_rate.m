clear;
clc;
close all;

%% 1. 输入和输出文件
% 如文件位置发生变化，只需要修改这一部分。

matFile = 'fig4.mat';
regionShp = 'E:\100.doctoral\34.timing_on_rate\figure\shp\IPCC-WGI-reference-regions-v4_land.shp';
landShp = 'E:\100.doctoral\34.timing_on_rate\figure\shp\ne_110m_admin_0_sovereignty.shp';

outputPrefix = fullfile(pwd,'Fig4_period_onset_rate');

%% 2. 图形参数

figureWidthCm = 18;
figureHeightCm = 18;
exportResolution = 600;

fontName = 'Arial';
mapValueFontSize = 5;
outsideLabelFontSize = 8;

maskGrey = [0.90, 0.90, 0.90];
regionEdgeColour = [0.48, 0.48, 0.48];
coastlineColour = [0.72, 0.72, 0.72];

regionLineWidth = 0.45;
coastlineWidth = 0.35;

% 8 个地图面板的位置，单位为 figure 的归一化坐标。
panelX = [0.055, 0.480];
panelY = [0.755, 0.525, 0.295, 0.065];
panelWidth = 0.395;
panelHeight = 0.190;

panelLetters = 'abcdefgh';

columnLabels = { ...
    'High-speed (> mean)', ...
    'Extreme-speed (> mean + SD)'};

rowLabels = { ...
    'Start timing', ...
    'End timing', ...
    'Share of period', ...
    'Share of GPP loss'};


%% 3. 读取数据并构建 8 个面板

loadedData = load(matFile,'Period_Nodes_Matrix');

if ~isfield(loadedData,'Period_Nodes_Matrix')
    error('MAT file does not contain Period_Nodes_Matrix.');
end

rawMatrix = double(loadedData.Period_Nodes_Matrix);

if size(rawMatrix,2) < 6
    error('Period_Nodes_Matrix must contain at least six columns.');
end

numberOfRegions = size(rawMatrix,1);
panelValues = nan(numberOfRegions,8);

% 第 1–4 列：开始和结束周期。
panelValues(:,1:4) = rawMatrix(:,1:4);

% 第 5–6 列：持续周期数。mod 用于处理跨年情况。
panelValues(:,5) = mod(rawMatrix(:,3) - rawMatrix(:,1) - 1,46) + 1;
panelValues(:,6) = mod(rawMatrix(:,4) - rawMatrix(:,2) - 1,46) + 1;

% 第 7–8 列：GPP 损失占比。
panelValues(:,7:8) = rawMatrix(:,5:6);

%% 4. 应用缺失值掩膜
% NaN 在图中显示为灰色，并且不添加数字标记。

allColumnsRows = [4, 9, 16, 20, 23, 39, 43];
highColumnsRows = [1, 10, 33];
extremeColumnsRows = [26, 37];

panelValues(allColumnsRows,:) = NaN;
panelValues(highColumnsRows,1:2:8) = NaN;
panelValues(extremeColumnsRows,2:2:8) = NaN;


%% 5. 单位转换

% 开始时间：8 日周期编号转换为年积日。
panelValues(:,1:2) = 1 + (panelValues(:,1:2) - 1).*8;

% 结束时间：转换为年积日，最大值限制为 365。
panelValues(:,3:4) = panelValues(:,3:4) .*8;

% 时段长度：转换为百分比。
panelValues(:,5:6) = panelValues(:,5:6).*8./3.68;


%% 6. 配色

% 上四图：Spectral_r 中抽取的 12 个离散月份色。
timingColours = [
    0.30096117 0.39746251 0.67681661
    0.24006151 0.58239139 0.72087659
    0.42122261 0.76908881 0.64675125
    0.64405998 0.85628604 0.64352172
    0.83844675 0.93494810 0.60899654
    0.95963091 0.98385236 0.68604383
    0.99838524 0.94994233 0.66505190
    0.99500192 0.82460592 0.49988466
    0.98869666 0.65736255 0.36885813
    0.95963091 0.44744329 0.27197232
    0.86151480 0.28289120 0.29965398
    0.70419070 0.09773164 0.27881584];

monthEdges = [1,32,60,91,121,152,182,213,244,274,305,335,366];

% 下四图：RdBu_r 删除中间 20% 后得到的 10 个离散色。
% 第 1–5 个为蓝色，第 6–10 个为红色，不包含白色。
impactColours = [
    0.04975010 0.24636678 0.46113033
    0.15294118 0.43114187 0.69042676
    0.28704344 0.59184929 0.77301038
    0.56647443 0.76870434 0.86851211
    0.79054210 0.88327566 0.93287197
    0.98800461 0.83391003 0.74855825
    0.95455594 0.64175317 0.50572857
    0.84844291 0.39769319 0.31826221
    0.72295271 0.14394464 0.19215686
    0.48465975 0.02583622 0.13448674];


%% 7. 读取 IPCC 区域并计算数字中心

regions = shaperead(regionShp,'UseGeoCoords',false);

if numel(regions) ~= numberOfRegions
    error('Region count mismatch: shapefile=%d, matrix=%d.', ...
        numel(regions),numberOfRegions);
end

labelX = nan(numberOfRegions,1);
labelY = nan(numberOfRegions,1);

for regionIndex = 1:numberOfRegions
    % 按照要求，中心为所有边界坐标的算术均值。
    labelX(regionIndex) = mean(regions(regionIndex).X,'omitnan');
    labelY(regionIndex) = mean(regions(regionIndex).Y,'omitnan');
end


%% 8. 构建无国界线的陆地边界

landFeatures = shaperead(landShp,'UseGeoCoords',false);
mergedLand = polyshape();

for featureIndex = 1:numel(landFeatures)
    currentLand = polyshape( ...
        landFeatures(featureIndex).X, ...
        landFeatures(featureIndex).Y, ...
        'Simplify',true, ...
        'KeepCollinearPoints',false);

    if ~isempty(currentLand.Vertices)
        mergedLand = union(mergedLand,currentLand);
    end
end

[coastX,coastY] = boundary(mergedLand);


%% 9. 创建图窗

fig = figure( ...
    'Color','w', ...
    'Units','centimeters', ...
    'Position',[2,2,figureWidthCm,figureHeightCm], ...
    'PaperPositionMode','auto', ...
    'Name','Seasonal timing and impact');

panelAxes = gobjects(8,1);


%% 10. 绘制 8 个地图面板

for panelIndex = 1:8

    rowIndex = ceil(panelIndex/2);
    columnIndex = mod(panelIndex - 1,2) + 1;

    panelPosition = [ ...
        panelX(columnIndex), ...
        panelY(rowIndex), ...
        panelWidth, ...
        panelHeight];

    ax = axes(fig,'Position',panelPosition);
    panelAxes(panelIndex) = ax;
    hold(ax,'on');

    %% 10.1 绘制区域颜色
    for regionIndex = 1:numberOfRegions

        value = panelValues(regionIndex,panelIndex);

        if isnan(value)
            faceColour = maskGrey;

        elseif panelIndex <= 4
            colourIndex = discretize(value,monthEdges);
            colourIndex = max(1,min(12,colourIndex));
            faceColour = timingColours(colourIndex,:);

        else
            colourIndex = floor(value/10) + 1;
            colourIndex = max(1,min(10,colourIndex));
            faceColour = impactColours(colourIndex,:);
        end

        mapshow(ax,regions(regionIndex), ...
            'DisplayType','polygon', ...
            'FaceColor',faceColour, ...
            'EdgeColor',regionEdgeColour, ...
            'LineWidth',regionLineWidth);
    end

    %% 10.2 绘制陆地边界
    % mergedLand 已合并全部国家，因此这里只显示海岸线，不显示国界。
    plot(ax,coastX,coastY, ...
        'Color',coastlineColour, ...
        'LineWidth',coastlineWidth);

    %% 10.3 添加区域数字
    for regionIndex = 1:numberOfRegions

        value = panelValues(regionIndex,panelIndex);

        if isnan(value)
            continue;
        end

        % 前四幅图在日期前添加 D。
        if panelIndex <= 4
            labelText = sprintf('D%d',round(value));

            % 拥挤区域只进行换行，不旋转，也不移动中心位置。
            crowdedLeft = ismember(panelIndex,[1,3]) && ...
                ismember(regionIndex,[12,13,26,27,28]);
            crowdedRight = ismember(panelIndex,[2,4]) && ...
                ismember(regionIndex,[27,28]);

            if crowdedLeft || crowdedRight
                labelText = sprintf('D\n%d',round(value));
            end

            colourIndex = discretize(value,monthEdges);
            colourIndex = max(1,min(12,colourIndex));
            fillColour = timingColours(colourIndex,:);

        else
            labelText = sprintf('%d',round(value));

            colourIndex = floor(value/10) + 1;
            colourIndex = max(1,min(10,colourIndex));
            fillColour = impactColours(colourIndex,:);
        end

        % 根据底色亮度自动选择黑色或白色文字。
        luminance = 0.299*fillColour(1) + ...
                    0.587*fillColour(2) + ...
                    0.114*fillColour(3);

        if luminance < 0.43
            textColour = [1,1,1];
        else
            textColour = [0,0,0];
        end

        text(ax,labelX(regionIndex),labelY(regionIndex),labelText, ...
            'HorizontalAlignment','center', ...
            'VerticalAlignment','middle', ...
            'FontName',fontName, ...
            'FontSize',mapValueFontSize, ...
            'FontWeight','bold', ...
            'Color',textColour, ...
            'Interpreter','none', ...
            'Clipping','on');
    end

    %% 10.4 设置地图坐标轴
    xlim(ax,[-180,180]);
    ylim(ax,[-60,90]);

    set(ax, ...
        'XTick',-180:60:180, ...
        'XTickLabel',{}, ...
        'YTick',-60:30:90, ...
        'YTickLabel',{}, ...
        'TickDir','in', ...
        'TickLength',[0.015,0.015], ...
        'LineWidth',0.7, ...
        'Box','on', ...
        'Layer','top', ...
        'FontName',fontName, ...
        'FontSize',outsideLabelFontSize, ...
        'XColor','k', ...
        'YColor','k');

    %% 10.5 添加面板字母
    text(ax,0,1.02,panelLetters(panelIndex), ...
        'Units','normalized', ...
        'HorizontalAlignment','left', ...
        'VerticalAlignment','bottom', ...
        'FontName',fontName, ...
        'FontSize',outsideLabelFontSize, ...
        'FontWeight','bold', ...
        'Color','k', ...
        'Clipping','off');
end


%% 11. 添加列标题

for columnIndex = 1:2
    annotation(fig,'textbox', ...
        [panelX(columnIndex),0.955,panelWidth,0.030], ...
        'String',columnLabels{columnIndex}, ...
        'EdgeColor','none', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'FontName',fontName, ...
        'FontSize',outsideLabelFontSize, ...
        'FontWeight','bold');
end


%% 12. 添加行标题

for rowIndex = 1:4
    leftPanelIndex = (rowIndex - 1)*2 + 1;
    leftAx = panelAxes(leftPanelIndex);

    text(leftAx,-0.095,0.50,rowLabels{rowIndex}, ...
        'Units','normalized', ...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', ...
        'Rotation',90, ...
        'FontName',fontName, ...
        'FontSize',outsideLabelFontSize, ...
        'FontWeight','bold', ...
        'Color','k', ...
        'Clipping','off');
end


%% 13. 添加上四幅图共用的月份色标

timingColorbarAxes = axes(fig, ...
    'Position',[0.905,0.535,0.001,0.410], ...
    'Visible','off');

colormap(timingColorbarAxes,timingColours);
clim(timingColorbarAxes,[0.5,12.5]);

timingColorbar = colorbar(timingColorbarAxes,'eastoutside');
timingColorbar.Position = [0.915,0.535,0.018,0.410];
timingColorbar.Ticks = 1:12;
timingColorbar.TickLabels = { ...
    'Jan','Feb','Mar','Apr','May','Jun', ...
    'Jul','Aug','Sep','Oct','Nov','Dec'};
timingColorbar.FontName = fontName;
timingColorbar.FontSize = outsideLabelFontSize;
timingColorbar.LineWidth = 0.7;
timingColorbar.Label.String = 'Timing';
timingColorbar.Label.FontName = fontName;
timingColorbar.Label.FontSize = outsideLabelFontSize;
timingColorbar.Label.FontWeight = 'bold';


%% 14. 添加下四幅图共用的百分比色标

impactColorbarAxes = axes(fig, ...
    'Position',[0.905,0.065,0.001,0.410], ...
    'Visible','off');

colormap(impactColorbarAxes,impactColours);
clim(impactColorbarAxes,[0,100]);

impactColorbar = colorbar(impactColorbarAxes,'eastoutside');
impactColorbar.Position = [0.915,0.065,0.018,0.410];
impactColorbar.Ticks = 0:10:100;
impactColorbar.FontName = fontName;
impactColorbar.FontSize = outsideLabelFontSize;
impactColorbar.LineWidth = 0.7;
impactColorbar.Label.String = 'Share (%)';
impactColorbar.Label.FontName = fontName;
impactColorbar.Label.FontSize = outsideLabelFontSize;
impactColorbar.Label.FontWeight = 'bold';


%% 15. 导出图件

% outputFolder = fileparts(outputPrefix);
% 
% if ~isempty(outputFolder) && ~exist(outputFolder,'dir')
%     mkdir(outputFolder);
% end
% 
% exportgraphics(fig,[outputPrefix '.png'], ...
%     'Resolution',exportResolution, ...
%     'BackgroundColor','white');
% 
% savefig(fig,[outputPrefix '.fig']);
% 
% fprintf('Saved: %s.[png|fig]\n',outputPrefix);
