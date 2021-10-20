clc; close all;

%% parameter initialization
polCaliDataFile_AW = 'D:\Data\CMA_Lidar_Comparison\internalChk\AW\polarization-calibration\AL01_L0110_54424_Lidar_20211013123318.bin';
caliRangeAW = [0, 15000];
caliRangeSlotAW = [3000, 5000];

%% read data

% AW
oData = readCmaLidarData(polCaliDataFile_AW, 'nMaxBin', 2000);
polCaliData_AW.height = oData.height;
polCaliData_AW.gainRatio = (oData.rawSignal(1, :) - nanmean(oData.rawSignal(1, 1200:1400))) ./ (oData.rawSignal(2, :) - nanmean(oData.rawSignal(2, 1200:1400)));

%% data visualization

% AW
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_AW.height >= caliRangeAW(1)) & (polCaliData_AW.height <= caliRangeAW(2));
gainRatioAW = nanmean(polCaliData_AW.gainRatio(isHCali));
gainRatioStdAW = nanstd(polCaliData_AW.gainRatio(isHCali));
fprintf('Gainratio AW: %f+-%f\n', gainRatioAW, gainRatioStdAW);
p1 = plot(polCaliData_AW.height(isHCali), polCaliData_AW.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_AW.height(1), polCaliData_AW.height(end)], [1, 1] * gainRatioAW, '--k');
p3 = plot([polCaliData_AW.height(1), polCaliData_AW.height(end)], [1, 1] * gainRatioStdAW + gainRatioAW, '-.k');
p4 = plot([polCaliData_AW.height(1), polCaliData_AW.height(end)], [-1, -1] * gainRatioStdAW + gainRatioAW, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('AW');

xlim(caliRangeAW);
ylim([0, 2]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('AW_gaintio_full.png'), '-r300');

% AW (slot)
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_AW.height >= caliRangeSlotAW(1)) & (polCaliData_AW.height <= caliRangeSlotAW(2));
gainRatioAW = nanmean(polCaliData_AW.gainRatio(isHCali));
gainRatioStdAW = nanstd(polCaliData_AW.gainRatio(isHCali));
fprintf('Gainratio AW: %f+-%f\n', gainRatioAW, gainRatioStdAW);
p1 = plot(polCaliData_AW.height(isHCali), polCaliData_AW.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_AW.height(1), polCaliData_AW.height(end)], [1, 1] * gainRatioAW, '--k');
p3 = plot([polCaliData_AW.height(1), polCaliData_AW.height(end)], [1, 1] * gainRatioStdAW + gainRatioAW, '-.k');
p4 = plot([polCaliData_AW.height(1), polCaliData_AW.height(end)], [-1, -1] * gainRatioStdAW + gainRatioAW, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('AW');

xlim(caliRangeSlotAW);
ylim([0.04, 0.08]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('AW_gaintio_slot.png'), '-r300');
