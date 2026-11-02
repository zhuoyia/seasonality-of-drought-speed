clear; clc;
% %% ======================= 1. Load data ===================================
% load('E:\100.doctoral\GPP_response_doctoral_260709.mat')
% load('E:\101\mask\area_600_1440.mat');
% area = area(:);
% sm_dataset = {'ERA5_GOSIF','GLDAS_GOSIF','GLEAM_GOSIF'};
% n_models = 3;
% nComb  = numel(sm_dataset);
% n_years = 23; 
% 
% load('E:\101\mask\koppen.mat')
% koppen=double(koppen);   koppen(koppen==0) = nan;
% koppen(koppen<=3)=101;   koppen(koppen<=7)=102;  
% koppen(koppen<=16)=103;  koppen(koppen<=30)=104; koppen(koppen<=30)=105;
% koppen = koppen-100;     koppen = reshape(koppen,[864000,1]);
% % （注：r_region 外部导入，已在此前准备好）
% load('E:\100.doctoral\34.timing_on_rate\seasonal_variation_WA')

%% ======================= 2. Pixel loss & Data Mapping ===================
% event_all=[];
% for k = 1:3
%     Evtnt_table = GPP_response.(sm_dataset{k});
%     % Evtnt_table(isnan(Evtnt_table.gpp_loss),:) = [];
% 
%     % 计算初始候
%     Evtnt_table.pentad_timing = ceil(mean([Evtnt_table.pentad_onset], 2));
%     Evtnt_table.pentad_timing = mod(Evtnt_table.pentad_timing-1 , 46) + 1;
%     Evtnt_table.koppen = koppen(Evtnt_table.pixel_id);
% 
%     % 避免多次重复执行二维寻址
%     linearIdx = sub2ind(size(VarStruct.LAC), ...
%         Evtnt_table.pixel_id, ...
%         Evtnt_table.pentad_timing);
% 
%     % 映射表：结构体字段名 -> Evtnt_table 目标列名
%     mapping = { ...
%         'ET_mean',  'ETmean'; ...
%         'Pre_std',  'Prestd' ...
%         };
% 
%     % 循环提取数据
%     for k2 = 1:size(mapping, 1)
%         srcField = mapping{k2, 1};
%         dstCol   = mapping{k2, 2};
%         data = VarStruct.(srcField);
%         Evtnt_table.(dstCol) = data(linearIdx);
%     end
%         % 添加土壤湿度数据集标识
%     Evtnt_table.SM_dataset = repmat( ...
%         string(sm_dataset{k}), height(Evtnt_table), 1);
% 
%     % 添加土壤湿度数据集标识
%     Evtnt_table.SM_dataset = repmat( ...
%         string(sm_dataset{k}), height(Evtnt_table), 1);
% 
%     % 纵向合并三种数据集
%     event_all = [event_all; Evtnt_table];
% end

%% ========================================================================
% 3. 画板初始化与参数定义 
% ========================================================================
load('fig2.mat')

fig = figure(1); clf;
set(fig, 'Name', 'Decoupling 2x4 Matrix (Horizontal Boxplot)', 'Units', 'centimeters', ...
         'Position', [2, 2, 18, 14], 'Color', 'w');
         
color_cmap = flipud(cbrewer2('div', 'Spectral'));
numBins = 10;

koppen_labels = {'Tropical', 'Arid', 'Temperate', 'Boreal'};
target_vars   = {'onset_rate', 'onset_time'};
row_titles    = {'Rate', 'Duration'};

% --- 自动网格排版参数设定 ---
left_margin   = 0.05;
right_margin  = 0.03;
bottom_margin = 0.05; 
top_margin    = 0.05;

w_gap = 0.04; % 列间距
h_gap = 0.12; % 两个大行（Rate 与 duration）之间的间距

W_block = (1 - left_margin - right_margin - 3 * w_gap) / 4; 
H_block = (1 - bottom_margin - top_margin - 1 * h_gap) / 2; 

h_inner_gap = 0.075;               % 热图和底部箱线图的内部间距
H_box  = H_block * 0.2;          % 横置后箱线图不需要太高，25% 足够
H_heat = H_block - H_box - h_inner_gap; 

w_cb   = 0.01;                    
w_cb_gap = 0.005;                 
w_heat = W_block - w_cb - w_cb_gap; 

res_cell = cell(2, 4);

% 预定义 a-h 的字母数组，用于自动打标签
panel_letters = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'};
% ========================================================================
% 4. 核心计算与绘图主循环
% ========================================================================
for row = 1:2
    target_var = target_vars{row};
    
    for col = 1:4
        % 数据筛选
        k = col; 
        mask = (event_all.koppen == k);
        sub_table = event_all(mask, :);
        
        % 解耦计算
        if row==1
            Res = decouple_2Var_Slope(sub_table.ETmean, sub_table.Prestd, sub_table.(target_var)/8, numBins);
        else
            Res = decouple_2Var_Slope(sub_table.ETmean, sub_table.Prestd, sub_table.(target_var)*8, numBins);
        end
        res_cell{row, col} = Res;
        
        % --- 计算当前大单元格坐标矩阵 ---
        x_base = left_margin + (col - 1) * (W_block + w_gap);
        y_base = bottom_margin + (2 - row) * (H_block + h_gap); 
        
        pos_box  = [x_base, y_base, w_heat, H_box];
        pos_heat = [x_base, y_base + H_box + h_inner_gap, w_heat, H_heat];
        pos_cb   = [x_base + w_heat + w_cb_gap, y_base + H_box + h_inner_gap, w_cb, H_heat];
        
        % -----------------------------------------------------------------
        % A. 绘制 Heatmap (位于单元格上方)
        % -----------------------------------------------------------------
        ax1 = axes('Parent', fig, 'Units', 'normalized', 'Position', pos_heat);
        panel_idx = (row - 1) * 4 + col;
        titleName = sprintf('%s %s (%s)', panel_letters{panel_idx}, koppen_labels{k}, row_titles{row});
        
        if ~isempty(Res) && isfield(Res, 'Y_grid') && any(~isnan(Res.Y_grid(:)))
            Z = flipud(Res.Y_grid);
            set(imagesc(ax1, Z), 'AlphaData', ~isnan(Z));
            
            % 设置对称 Colorbar
            cmax = max(abs(Z(:)));
           %  if cmax > 0, clim(ax1, [-cmax, cmax]); end
            colormap(ax1, color_cmap);
            
            axis(ax1, 'normal'); 
            set(ax1, 'Color', [0.85 0.85 0.85], 'XLim', [0.5 10.5], 'YLim', [0.5 10.5], ...
                     'XTick', (0:1:10)+0.5, 'YTick', (0:1:10)+0.5, ...
                     'XTickLabel', 0:10:100, 'YTickLabel', {}, ... 
                     'TickLength', [0 0], 'FontSize', 6, 'Box', 'on', 'LineWidth', 0.8, ...
                     'GridColor', 0.5*[1 1 1], 'GridAlpha', 0.35, 'Layer', 'top');
            grid(ax1, 'on');
            title(ax1, titleName, 'FontWeight', 'bold', 'FontSize', 8);
            
            xlabel(ax1, 'Pre_{std} (%)', 'FontSize', 6);
            if col == 1
                set(ax1, 'YTickLabel', 100:-10:0);
                ylabel(ax1, 'ET_{mean} (%)', 'FontSize', 7);
            end
            
            % Colorbar 配置
            cb = colorbar(ax1);
            cb.Units = 'normalized';
            cb.Position = pos_cb; 
            cb.FontSize = 5;
            cb.LineWidth = 0.6;
        else
            axis(ax1, 'off');
            text(ax1, 0.5, 0.5, 'No valid data', 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 8);
            title(ax1, titleName);
        end
        
        % -----------------------------------------------------------------
        % B. 绘制 Horizontal Boxplot (位于热图正下方)
        % -----------------------------------------------------------------
        ax2 = axes('Parent', fig, 'Units', 'normalized', 'Position', pos_box);
        if ~isempty(Res) && isfield(Res, 'slopes_X1') && isfield(Res, 'slopes_X2')
            ET  = Res.slopes_X1(~isnan(Res.slopes_X1));
            PRE = Res.slopes_X2(~isnan(Res.slopes_X2));
            
            if ~isempty(ET) && ~isempty(PRE)
                box_color = color_cmap(20 , :); 
                
                boxplot(ax2, [ET(:); PRE(:)], [repmat({'ET'}, length(ET), 1); repmat({'Pre'}, length(PRE), 1)], ...
                        'Widths', 0.45, 'PlotStyle', 'compact', 'Whisker', 1.5, 'Symbol', 'o',...
                        'Colors', box_color, 'Orientation', 'horizontal');
                hold(ax2, 'on');
                
                scatter([mean(ET), mean(PRE)], [1, 2], 'x', 'LineWidth', 1.2, 'MarkerEdgeColor', 'r');
                 yline(ax2, 1.5, '--k', 'LineWidth', 0.8);
                
                % 外观美化
                grid(ax2, 'on'); box(ax2, 'on');
                set(ax2, 'FontSize', 6, 'LineWidth', 0.8, 'Color', 0.95*[1 1 1]);  
                ylim(ax2, [0.5, 2.5]);
                
                % 视觉优化：仅在最左侧的子图显示 'ET', 'Pre' 标签
                if col == 1
                    yticks([1,2])
                    yticklabels(ax2, {'ET', 'Pre'});
                else
                    yticklabels(ax2, {});
                end

                % 动态缩放数值轴 (现在的 X 轴)
                x_max_bound = prctile([ET(:); PRE(:)],[3 97]);
                xlim(ax2, x_max_bound);
                xlabel(ax2, 'sensitivity', 'FontSize', 7);

            else
                axis(ax2, 'off');
            end
        else
            axis(ax2, 'off');
        end
        
    end
end

%% ---------------------------
% 导出图片
% ---------------------------
output_file = 'E:\100.doctoral\34.timing_on_rate\figure\F2_decouple_ET_PRE_4region_HorizontalBox.png';
print(output_file, fig, '-r600', '-dpng');