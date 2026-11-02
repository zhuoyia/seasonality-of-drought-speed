%% -------------------------------------------------------------------------
% Calculate post-drought GPP legacy loss & Area (4 Regions, 2x4 Layout)
% Four columns: Tropical, Arid, Temperate, and Boreal
% -------------------------------------------------------------------------
clear; clc;

%% ======================= 1. Load data ===================================
% load('E:\100.doctoral\GPP_response_doctoral_260709.mat')
% load('E:\101\mask\area_600_1440.mat');
% area = area(:);
% 
% sm_dataset = {'ERA5_GOSIF', 'GLDAS_GOSIF', 'GLEAM_GOSIF'};
% n_models = 3;
% n_years = 23;

% load('E:\101\mask\koppen.mat')
% koppen = double(koppen);
% koppen(koppen == 0) = nan;
% 
% % Merge the original Koppen classes into four climate regions:
% % 1 = Tropical, 2 = Arid, 3 = Temperate, 4 = Boreal
% koppen(koppen <= 3)  = 101;
% koppen(koppen <= 7)  = 102;
% koppen(koppen <= 16) = 103;
% koppen(koppen <= 30) = 104;
% koppen = koppen - 100;
% koppen = reshape(koppen, [864000, 1]);
% 
% %% ======================= 2. Preallocate =================================
% % Timing_loss{Region, Metric}
% % Metric: 1 = Loss, 2 = Rate, 3 = Area
% Timing_loss = cell(4, 3);
% for i = 1:4
%     for j = 1:3
%         Timing_loss{i, j} = nan(3, 46, n_models + 2);
%     end
% end
% 
% %% ======================= 3. Pixel loss & region split ===================
% for k = 1:n_models
%     Evtnt_table = GPP_response.(sm_dataset{k});
%     Evtnt_table(isnan(Evtnt_table.gpp_loss), :) = [];
% 
%     % Event timing
%     Evtnt_table.pentad_timing = ceil(mean( ...
%         [Evtnt_table.pentad_start + 1, Evtnt_table.pentad_onset], 2));
%     Evtnt_table.pentad_timing = ...
%         mod(Evtnt_table.pentad_timing - 1, 46) + 1;
% 
%     % Align Southern Hemisphere seasonality by shifting 23 pentads
%     idx_shift = mod(Evtnt_table.pixel_id - 1, 600) + 1 > 360;
%     Evtnt_table.pentad_timing(idx_shift) = ...
%         Evtnt_table.pentad_timing(idx_shift) + 23;
%     Evtnt_table.pentad_timing = ...
%         mod(Evtnt_table.pentad_timing - 1, 46) + 1;
% 
%     % Divide events into four climate regions
%     events = cell(4, 3);
%     pixel_koppen = koppen(Evtnt_table.pixel_id);
%     events{1, 1} = Evtnt_table(pixel_koppen == 1, :); % Tropical
%     events{2, 1} = Evtnt_table(pixel_koppen == 2, :); % Arid
%     events{3, 1} = Evtnt_table(pixel_koppen == 3, :); % Temperate
%     events{4, 1} = Evtnt_table(pixel_koppen == 4, :); % Boreal
% 
%     for region = 1:4
%         events{region, 2} = ...
%             events{region, 1}(events{region, 1}.type == 1, :);
%         events{region, 3} = ...
%             events{region, 1}(events{region, 1}.type == 2, :);
% 
%         for cat = 1:3
%             Evtnt_table_cur = events{region, cat};
%             area_event = area(Evtnt_table_cur.pixel_id);
% 
%             % 1. Area-weighted onset rate
%             rate_area_sum = accumarray( ...
%                 Evtnt_table_cur.pentad_timing, ...
%                 Evtnt_table_cur.onset_rate .* area_event, ...
%                 [46, 1], @sum, 0);
%             area_sum = accumarray( ...
%                 Evtnt_table_cur.pentad_timing, area_event, ...
%                 [46, 1], @sum, 0);
% 
%             weighted_rate = rate_area_sum ./ area_sum;
%             weighted_rate(area_sum == 0) = nan;
%             Timing_loss{region, 2}(cat, :, k) = weighted_rate;
% 
%             % 2. Mean annual drought area (10^6 km^2)
%             A1 = accumarray( ...
%                 Evtnt_table_cur.pentad_timing, area_event, ...
%                 [46, 1], @sum, 0);
%             Timing_loss{region, 3}(cat, :, k) = ...
%                 A1 * 1e-6 / n_years;
% 
%             % 3. Area-weighted GPP loss
%             Evtnt_table_cur(Evtnt_table_cur.gpp_loss >= 0, :) = [];
%             area_event_loss = area(Evtnt_table_cur.pixel_id);
%             Timing_loss{region, 1}(cat, :, k) = ...
%                 -accumarray( ...
%                     Evtnt_table_cur.pentad_timing, ...
%                     Evtnt_table_cur.gpp_loss .* area_event_loss, ...
%                     [46, 1], @sum, nan) ...
%                 / n_years * 1e6 * 1e-12 / 8;
%         end
%     end
% end

%% ======================= 4. Ensemble statistics =========================
load('fig3.mat')
n_models = 3;
idx_mean = 4;
idx_std  = 5;

for i = 1:4
    for j = 1:3
        Timing_loss{i, j}(:, :, idx_mean) = ...
            mean(Timing_loss{i, j}(:, :, 1:n_models), 3, 'omitnan');
        Timing_loss{i, j}(:, :, idx_std) = ...
            std(Timing_loss{i, j}(:, :, 1:n_models), 0, 3, 'omitnan');
    end
end

% ======================= 5. Plot: 3 x 4 layout ===========================
cat = 1;              % Category 1: all events
w_span = -2:2;        % Five-pentad smoothing window


% Publication-style color palette
color_area    = [144, 196, 221] / 255;
color_loss    = [44, 123, 182] / 255;
color_time    = [135, 135, 135] / 255;
color_line    = [10, 10, 10] / 255;
color_high    = [253, 192, 134] / 255;
color_extreme = [215, 25, 28] / 255;

% Precompute the annual shares used in the third-row three-point plots.
share_duration = nan(4, 2);
share_area = nan(4, 2);
share_loss = nan(4, 2);

for region = 1:4
    R_onset = squeeze(Timing_loss{region, 2}(1, :, idx_mean));

    R_onset_smooth = nan(46, 1);
    for t = 1:46
        win_idx = mod((t + w_span) - 1, 46) + 1;
        R_onset_smooth(t) = mean(R_onset(win_idx), 'omitnan');
    end

    mu_onset = mean(R_onset_smooth, 'omitnan');
    sigma_onset = std(R_onset_smooth, 0, 'omitnan');
    accelerated_idx = { ...
        R_onset_smooth > mu_onset, ...
        R_onset_smooth > mu_onset + sigma_onset};

    area_series = squeeze(Timing_loss{region, 3}(cat, :, idx_mean));
    loss_series = squeeze(Timing_loss{region, 1}(cat, :, idx_mean));

    area_total = sum(area_series, 'omitnan');
    loss_total = sum(loss_series, 'omitnan');

    for speed_class = 1:2
        current_idx = accelerated_idx{speed_class};

        % Fraction of the 46 annual pentads occupied by this window.
        share_duration(region, speed_class) = ...
            sum(current_idx) / numel(current_idx) * 100;

        if area_total > 0 && ~isnan(area_total)
            share_area(region, speed_class) = ...
                sum(area_series(current_idx), 'omitnan') / area_total * 100;
        end

        if loss_total > 0 && ~isnan(loss_total)
            share_loss(region, speed_class) = ...
                sum(loss_series(current_idx), 'omitnan') / loss_total * 100;
        end
    end
end

%%
fig = figure;
set(fig, ...
    'Name', 'Drought Area and GPP Loss', ...
    'Color', 'w', ...
    'Units', 'centimeters', ...
    'Position', [-20, 3, 18, 13.5]);

RegionName = {'Tropical', 'Arid', 'Temperate', 'Boreal'};
panel_letters = {'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', ...
                 'i', 'j', 'k', 'l'};
sub2 = cell(1, 12);

% Layout parameters
left_margin   = 0.07;
right_margin  = 0.05;
bottom_margin = 0.09;
top_margin    = 0.06;
w_gap = 0.05;
h_gap_rows = 0.055;
h_gap_legend = 0.0975;
H_compare = 0.15;

W_block = (1 - left_margin - right_margin - 3 * w_gap) / 4;
H_block = (1 - bottom_margin - top_margin - H_compare - ...
    h_gap_rows - h_gap_legend) / 2;

for row = 1:2
    for col = 1:4
        region = col;
        plot_idx = (row - 1) * 4 + col;

        % Calculate axes position
        x_pos = left_margin + (col - 1) * (W_block + w_gap);
        y_pos = bottom_margin + H_compare + h_gap_legend + ...
            (2 - row) * (H_block + h_gap_rows);
        sub2{plot_idx} = axes( ...
            'Parent', fig, ...
            'Position', [x_pos, y_pos, W_block, H_block]);

        % Row 1: drought area; row 2: GPP loss
        if row == 1
            metric_idx = 3;
        else
            metric_idx = 1;
        end

        Data_Y = squeeze( ...
            Timing_loss{region, metric_idx}(cat, :, idx_mean));
        R_onset = squeeze( ...
            Timing_loss{region, 2}(1, :, idx_mean))/8;

        % Five-pentad cyclic smoothing of onset rate
        R_onset_smooth = nan(46, 1);
        for t = 1:46
            win_idx = mod((t + w_span) - 1, 46) + 1;
            R_onset_smooth(t) = mean(R_onset(win_idx), 'omitnan');
        end

        % Thresholds for high- and extreme-speed periods
        mu_onset = mean(R_onset_smooth, 'omitnan');
        sigma_onset = std(R_onset_smooth, 0, 'omitnan');
        thresh_high = mu_onset;
        thresh_extreme = mu_onset + sigma_onset;

        idx_high = R_onset_smooth > thresh_high;
        idx_extreme = R_onset_smooth > thresh_extreme;

        % Contributions and timing intervals
        total_annual = sum(Data_Y, 'omitnan');
        val_high = sum(Data_Y(idx_high), 'omitnan');
        val_extreme = sum(Data_Y(idx_extreme), 'omitnan');

        if total_annual == 0 || isnan(total_annual)
            ratio_high = nan;
            ratio_extreme = nan;
        else
            ratio_high = val_high / total_annual * 100;
            ratio_extreme = val_extreme / total_annual * 100;
        end

        time_strs = {'None', 'None'};
        idx_arrays = {idx_high, idx_extreme};

        for k_idx = 1:2
            curr_idx = idx_arrays{k_idx};

            if ~any(curr_idx)
                continue;
            elseif all(curr_idx)
                time_strs{k_idx} = 'P1-P46';
            else
                d = diff([curr_idx(end); curr_idx(:)]);
                starts = find(d == 1);
                ends = find(d == -1) - 1;
                ends(ends == 0) = 46;

                if starts(1) > ends(1)
                    ends = [ends(2:end); ends(1)];
                end

                dur = ends - starts;
                dur(dur < 0) = dur(dur < 0) + 46;
                [~, m_idx] = max(dur);

                time_strs{k_idx} = sprintf( ...
                    'D%d-D%d', ...
                    8 * (starts(m_idx) - 1) + 1, ...
                    8 * ends(m_idx));
            end
        end

        time_high = time_strs{1};
        time_ext = time_strs{2};

        %% -------------------- Draw left y-axis --------------------------
        yyaxis left

        valid_data = Data_Y(~isnan(Data_Y));
        if isempty(valid_data)
            y_max_left = 1;
        else
            y_max_left = max(valid_data) * 1.35;
            if y_max_left <= 0
                y_max_left = 1;
            end
        end

        hold on;

        % Background shading
        for t = 1:46
            if idx_extreme(t)
                patch( ...
                    [t - 0.5, t + 0.5, t + 0.5, t - 0.5], ...
                    [0, 0, y_max_left, y_max_left], ...
                    color_extreme, ...
                    'EdgeColor', 'none', ...
                    'FaceAlpha', 0.4);
            elseif idx_high(t)
                patch( ...
                    [t - 0.5, t + 0.5, t + 0.5, t - 0.5], ...
                    [0, 0, y_max_left, y_max_left], ...
                    color_high, ...
                    'EdgeColor', 'none', ...
                    'FaceAlpha', 0.5);
            end
        end

        if row == 1
            bar_color = color_area;
        else
            bar_color = color_loss;
        end

        bar(1:46, Data_Y, 0.8, ...
            'FaceColor', bar_color, ...
            'EdgeColor', 'none');

        plot(1:46, ones(1, 46) * mean(Data_Y, 'omitnan'), '--', ...
            'Color', bar_color, ...
            'LineWidth', 1.2);

        ylim([0, y_max_left]);
        xlim([0.5, 46.5]);
        set(gca, 'YColor', 'k');

        if col == 1
            if row == 1
                ylabel('Drought area (10^6 km^2)', ...
                    'FontName', 'Arial', ...
                    'FontSize', 7, ...
                    'Color', 'k');
            else
                ylabel('GPP loss (Tg day^{-1})', ...
                    'FontName', 'Arial', ...
                    'FontSize', 7, ...
                    'Color', 'k');
            end
        end

        %% -------------------- Draw right y-axis -------------------------
        yyaxis right

        plot(1:46, R_onset_smooth, '-', ...
            'Color', color_line, ...
            'LineWidth', 1.2);

        yline(thresh_high, '--', ...
            'Color', color_high, ...
            'LineWidth', 1);

        yline(thresh_extreme, ':', ...
            'Color', color_extreme, ...
            'LineWidth', 1.2);

        valid_rate = R_onset_smooth(~isnan(R_onset_smooth));
        if isempty(valid_rate)
            y_max_right = 0.01;
        else
            y_max_right = max(max(valid_rate) * 1.1, 0.01);
        end

        ylim([0, y_max_right]);
        set(gca, 'YColor', color_line);

        if col == 4
            ylabel('Onset rate', ...
                'FontName', 'Arial', ...
                'FontSize', 7, ...
                'Color', color_line);
        end

        %% -------------------- Axes formatting ---------------------------
        xticks([59, 151, 243, 334] / 8 + 0.5);

        if row == 2
            xticklabels({'59', '151', '243', '334'});
            xlabel('DOY', ...
                'FontName', 'Arial', ...
                'FontSize', 7);
        else
            xticklabels({});
        end

        set(gca, ...
            'FontName', 'Arial', ...
            'FontSize', 6, ...
            'Layer', 'top');
        box on;

        % Panel letter: shown in the upper-left corner of every panel
        text(0.03, 0.96, panel_letters{plot_idx}, ...
            'Units', 'normalized', ...
            'FontName', 'Arial', ...
            'FontSize', 8, ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', ...
            'Color', 'k');

        % Climate-region label: shown once above each column
        if row == 1
            title(RegionName{region}, ...
                'FontName', 'Arial', ...
                'FontSize', 8, ...
                'FontWeight', 'bold', ...
                'Units', 'normalized', ...
                'Position', [0.5, 1.04, 0], ...
                'HorizontalAlignment', 'center');
        end

        % Semi-transparent white background for the contribution annotation.
        % MATLAB text BackgroundColor does not support alpha, so a patch is
        % used behind the text instead.
        yyaxis right
        annotation_y_top = 0.20 * y_max_right;
        patch([0.5, 46.5, 46.5, 0.5], ...
            [0, 0, annotation_y_top, annotation_y_top], ...
            [1, 1, 1], ...
            'EdgeColor', 'none', ...
            'FaceAlpha', 0.5, ...
            'HandleVisibility', 'off');

        % Contribution annotation
        text_str = { ...
            sprintf('High-speed: %.1f%% (%s)', ratio_high, time_high), ...
            sprintf('Extreme-speed: %.1f%% (%s)', ratio_extreme, time_ext)};

        text(0.50, 0.15, text_str, ...
            'Units', 'normalized', ...
            'VerticalAlignment', 'top', ...
            'HorizontalAlignment', 'center', ...
            'FontName', 'Arial', ...
            'FontSize', 5.5, ...
            'BackgroundColor', 'none', ...
            'EdgeColor', 'none', ...
            'Color', 'k');
    end
end

%% ======================= 6. Third row: three-point comparison ===========

comparison_y = [1.40, 0.80];
comparison_labels = {'Extreme-speed', 'High-speed'};
point_legend_handles = gobjects(1, 3);

all_comparison_values = [share_duration(:); share_area(:); share_loss(:)];
all_comparison_values = all_comparison_values(isfinite(all_comparison_values));
comparison_min = min(all_comparison_values);
comparison_max = max(all_comparison_values);
comparison_xlim = [ ...
    floor((comparison_min - 5) / 5) * 5, ...
    ceil((comparison_max + 5) / 5) * 5];

for region = 1:4
    plot_idx = 8 + region;
    x_pos = left_margin + (region - 1) * (W_block + w_gap);

    sub2{plot_idx} = axes( ...
        'Parent', fig, ...
        'Position', [x_pos, bottom_margin, W_block, H_compare]);

    hold on;

    for speed_class = 1:2
        duration_value = share_duration(region, speed_class);
        area_value = share_area(region, speed_class);
        loss_value = share_loss(region, speed_class);
        y_value = comparison_y(speed_class);

        if isnan(duration_value) || isnan(area_value) || isnan(loss_value)
            text(54, y_value, 'No data', ...
                'Units', 'data', ...
                'FontName', 'Arial', ...
                'FontSize', 5.5, ...
                'Color', [0.45, 0.45, 0.45], ...
                'HorizontalAlignment', 'left', ...
                'VerticalAlignment', 'middle');
            continue;
        end

        % Separate segment colors make both concentration steps visible:
        % duration -> drought area and drought area -> GPP loss.
        plot([duration_value, area_value], [y_value, y_value], '-', ...
            'Color', color_time, ...
            'LineWidth', 2.0);
        plot([area_value, loss_value], [y_value, y_value], '-', ...
            'Color', color_area, ...
            'LineWidth', 2.0);

        % Point colors identify duration, drought area, and GPP loss.
        h_duration = scatter(duration_value, y_value, 32, ...
            'Marker', 'o', ...
            'MarkerFaceColor', color_time, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.45);

        h_area = scatter(area_value, y_value, 32, ...
            'Marker', 'o', ...
            'MarkerFaceColor', color_area, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.45);

        h_loss = scatter(loss_value, y_value, 32, ...
            'Marker', 'o', ...
            'MarkerFaceColor', color_loss, ...
            'MarkerEdgeColor', 'k', ...
            'LineWidth', 0.45);

        if region == 1 && speed_class == 1
            point_legend_handles = [h_duration, h_area, h_loss];
        end

        delta_area_time = area_value - duration_value;
        delta_loss_area = loss_value - area_value;

        % Above: duration -> drought-area change. The label begins at the
        % duration point, which is the start of this segment.
        text(duration_value, y_value + 0.18, ...
            sprintf('%+.1f pp', delta_area_time), ...
            'FontName', 'Arial', ...
            'FontSize', 4.7, ...
            'FontWeight', 'bold', ...
            'Color', color_time, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle');

        % Below: drought-area -> GPP-loss change. The label begins at the
        % drought-area point, which is the start of this segment.
        text(area_value, y_value - 0.18, ...
            sprintf('%+.1f pp', delta_loss_area), ...
            'FontName', 'Arial', ...
            'FontSize', 4.7, ...
            'FontWeight', 'bold', ...
            'Color', color_area, ...
            'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'middle');
    end

    xlim(comparison_xlim);
    ylim([0.40, 1.80]);
    xticks(comparison_xlim(1):15:comparison_xlim(2));
    xlabel('Annual share (%)', ...
        'FontName', 'Arial', ...
        'FontSize', 6.5);

    if region == 1
        yticks([0.80, 1.40]);
        yticklabels(comparison_labels);
        ytickangle(45);
    else
        yticks([]);
        yticklabels({});
    end

    set(gca, ...
        'FontName', 'Arial', ...
        'FontSize', 5.5, ...
        'TickDir', 'out', ...
        'YGrid', 'off', ...
        'XGrid', 'on', ...
        'GridColor', [0.88, 0.88, 0.88], ...
        'GridAlpha', 0.8, ...
        'Layer', 'top');
    box on;

    text(0.03, 0.94, panel_letters{plot_idx}, ...
        'Units', 'normalized', ...
        'FontName', 'Arial', ...
        'FontSize', 8, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'top', ...
        'Color', 'k');

    % The three-point encoding is defined once inside panel i.
    if region == 1
        point_legend = legend(sub2{plot_idx}, point_legend_handles, ...
            {'Duration', 'Drought area', 'GPP loss'}, ...
            'Location', 'southeast', ...
            'Orientation', 'vertical', ...
            'FontName', 'Arial', ...
            'FontSize', 4.6, ...
            'Box', 'off', ...
            'AutoUpdate', 'off');
        point_legend.ItemTokenSize = [12, 8];
    end
end

%% ======================= 7. Main-panel legend ===========================
% This legend belongs to panels a-h and sits between rows 2 and 3.
ax_legend = axes( ...
    'Parent', fig, ...
    'Position', [0.01, bottom_margin + H_compare + ...
        (h_gap_legend - 0.050) / 2, 0.97, 0.050], ...
    'Visible', 'off');

hold(ax_legend, 'on');
xlim(ax_legend, [0, 1]);
ylim(ax_legend, [0, 1]);

% Legend item 1: drought area
patch(ax_legend, ...
    [0.01, 0.035, 0.035, 0.01], [0.36, 0.36, 0.64, 0.64], ...
    color_area, 'EdgeColor', 'none');
text(ax_legend, 0.045, 0.50, 'Drought area', ...
    'FontName', 'Arial', 'FontSize', 5.2, ...
    'VerticalAlignment', 'middle');

% Legend item 2: GPP loss
patch(ax_legend, ...
    [0.16, 0.185, 0.185, 0.16], [0.36, 0.36, 0.64, 0.64], ...
    color_loss, 'EdgeColor', 'none');
text(ax_legend, 0.195, 0.50, 'GPP loss', ...
    'FontName', 'Arial', 'FontSize', 5.2, ...
    'VerticalAlignment', 'middle');

% Legend item 3: annual mean
plot(ax_legend, [0.29, 0.32], [0.50, 0.50], '--', ...
    'Color', 'k', 'LineWidth', 1.2);
text(ax_legend, 0.33, 0.50, 'Annual mean', ...
    'FontName', 'Arial', 'FontSize', 5.2, ...
    'VerticalAlignment', 'middle');

% Legend item 4: onset rate
plot(ax_legend, [0.43, 0.46], [0.50, 0.50], '-', ...
    'Color', color_line, 'LineWidth', 1.2);
text(ax_legend, 0.47, 0.50, 'Onset rate (smoothed)', ...
    'FontName', 'Arial', 'FontSize', 5.2, ...
    'VerticalAlignment', 'middle');

% Legend item 5: high-speed period
patch(ax_legend, ...
    [0.64, 0.67, 0.67, 0.64], [0.36, 0.36, 0.64, 0.64], ...
    color_high, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.5);
plot(ax_legend, [0.64, 0.67], [0.50, 0.50], '--', ...
    'Color', color_high, 'LineWidth', 1);
text(ax_legend, 0.68, 0.50, 'High-speed (> \mu)', ...
    'FontName', 'Arial', 'FontSize', 5.2, ...
    'VerticalAlignment', 'middle');

% Legend item 6: extreme-speed period
patch(ax_legend, ...
    [0.82, 0.85, 0.85, 0.82], [0.36, 0.36, 0.64, 0.64], ...
    color_extreme, ...
    'EdgeColor', 'none', ...
    'FaceAlpha', 0.4);
plot(ax_legend, [0.82, 0.85], [0.50, 0.50], ':', ...
    'Color', color_extreme, 'LineWidth', 1.2);
text(ax_legend, 0.86, 0.50, 'Extreme-speed (> \mu+1\sigma)', ...
    'FontName', 'Arial', 'FontSize', 5.2, ...
    'VerticalAlignment', 'middle');
