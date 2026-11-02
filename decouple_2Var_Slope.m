function [Result] = decouple_2Var_Slope(X1, X2, Y, numBins, minSamples)
% DECOUPLE_2VAR_BININDEX 基于分箱号的双变量数据解耦分析 (2D Bin Index)
%
% 输入参数:
%   X1, X2     : 1D 向量, 两个解释变量 (例如: SM, VPD)
%   Y          : 1D 向量, 目标响应变量 (例如: SIF, GPP)
%   numBins    : 标量, 分箱数量 (推荐 8 ~ 15)
%   minSamples : [可选] 单个 2D Bin 内最小样本数阈值, 默认 3
%
% 输出参数:
%   Result     : 结构体, 包含两变量的纯响应量(dY)、相对贡献率(%)及 2D 网格矩阵
%

    if nargin < 5 || isempty(minSamples)
        minSamples = max(50,0.001*length(Y)); % 过滤样本少于 3 的极端高噪分箱 [cite: 32, 35]
    end

    %% 1. 数据预处理
    X1 = X1(:); X2 = X2(:); Y = Y(:);
    validMask = ~isnan(X1) & ~isnan(X2) & ~isnan(Y) & ...
                ~isinf(X1) & ~isinf(X2) & ~isinf(Y);
    X1 = X1(validMask); X2 = X2(validMask); Y = Y(validMask);

    %% 2. 构建 2D 分位数分箱索引 (1 ~ numBins)
    edges1 = quantile(X1, linspace(0, 1, numBins + 1));
    edges2 = quantile(X2, linspace(0, 1, numBins + 1));
    
    [~, ~, bin1] = histcounts(X1, edges1);
    [~, ~, bin2] = histcounts(X2, edges2);

    %% 3. 构建 2D Y 响应矩阵 
    Y_grid = nan(numBins, numBins);
    for i = 1:numBins
        for j = 1:numBins
            mask = (bin1 == i) & (bin2 == j);
            if sum(mask) >= minSamples
                Y_grid(i, j) = mean(Y(mask));
            end
        end
    end

    %% 4. 基于分箱号 (1:numBins) 进行全箱切片回归 
    bin_axis = (1:numBins)'; % 自变量直接使用分箱号

    % --- 计算 X1 纯斜率 (固定 X2 的每一行) ---
    slopes_X1 = [];
    for j = 1:numBins
        y_slice = Y_grid(:, j); % 沿 X1 方向提取数据切片
        valid   = ~isnan(y_slice);
        if sum(valid) >= 3
            p = polyfit(bin_axis(valid), y_slice(valid), 1);
            slopes_X1(end+1) = p(1); 
        end
    end

    % --- 计算 X2 纯斜率 (固定 X1 的每一列) ---
    slopes_X2 = [];
    for i = 1:numBins
        y_slice = Y_grid(i, :)'; % 沿 X2 方向提取数据切片
        valid   = ~isnan(y_slice);
        if sum(valid) >= 3
            p = polyfit(bin_axis(valid), y_slice(valid), 1);
            slopes_X2(end+1) = p(1); 
        end
    end

    %% 5. 计算纯效应 (dY) 与 相对贡献率 (%) [cite: 24, 28, 45]
    delta_Bin = numBins - 1; % 全分箱跨度 [cite: 45]
    
    % 从最低分箱级到最高分箱级的总响应量 (单位与 Y 一致) [cite: 45]
    dY_X1 = mean(slopes_X1,'omitnan') * delta_Bin;
    dY_X2 = mean(slopes_X2,'omitnan') * delta_Bin;

    % 相对贡献率 (%) [cite: 24, 40]
    total_effect = abs(dY_X1) + abs(dY_X2);
    contrib_X1   = (abs(dY_X1) ./ total_effect) * 100;
    contrib_X2   = (abs(dY_X2) ./ total_effect) * 100;

    %% 6. 打包输出结果
    Result = struct();
    Result.slopes_X1  = slopes_X1 * delta_Bin;
    Result.slopes_X2  = slopes_X2 * delta_Bin;

    Result.dY_X1      = dY_X1;      % X1 剥离 X2 后的纯响应量 (同 Y 单位) [cite: 13, 14, 45]
    Result.dY_X2      = dY_X2;      % X2 剥离 X1 后的纯响应量 [cite: 14, 45]
    
    Result.Contrib_X1 = contrib_X1; % X1 相对贡献率 (%) [cite: 24, 45]
    Result.Contrib_X2 = contrib_X2; % X2 相对贡献率 (%) [cite: 24, 45]
    
    Result.Y_grid     = Y_grid;     % 2D 分箱响应矩阵 (numBins x numBins) [cite: 13, 45]
end