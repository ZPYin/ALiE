clc; close all;

%% parameter initialization
polCaliDataFile_L7 = 'D:\Data\CMA_Lidar_Comparison\internalChk\L7\polarization-calibration\AMPLE02_001_Gainratio_20210922175011.txt';
polCaliPDataFile_GB = 'D:\Data\CMA_Lidar_Comparison\internalChk\GB\polarization-calibration\AL01_L0102_54511_Lidar_20210917181500.bin';
polCaliNDataFile_GB = 'D:\Data\CMA_Lidar_Comparison\internalChk\GB\polarization-calibration\AL01_L0102_54511_Lidar_20210917181600.bin';
polCaliDataFile_ZK = 'D:\Data\CMA_Lidar_Comparison\internalChk\ZK\polarization-calibration\AL01_L0601_Lidar_20210922142507.bin';
polCaliPDataFile_SY = 'D:\Data\CMA_Lidar_Comparison\internalChk\SY\polarization-calibration\AL02_L0103_54399_Lidar_20210923013955.bin';
polCaliNDataFile_SY = 'D:\Data\CMA_Lidar_Comparison\internalChk\SY\polarization-calibration\AL02_L0103_54399_Lidar_20210923014102.bin';

caliRange_L7 = [0, 15000];
caliRangeSlot_L7 = [3000, 5000];
caliRange_SY = [0, 15000];
caliRangeSlot_SY = [3000, 5000];
caliRange_GB = [0, 17000];
caliRangeSlot_GB = [3000, 5000];
caliRange_ZK = [0, 6000];
caliRangeSlot_ZK = [500, 1000];

%% read data

% L7
fid = fopen(polCaliDataFile_L7, 'r');
oData = textscan(fid, '%f%f%f%f%f', 'headerlines', 1, 'delimiter', '\t');
polCaliData_L7.height = oData{1};
polCaliData_L7.gainRatio = (oData{4} - nanmean(oData{4}(550:650))) ./ (oData{5} - nanmean(oData{5}(550:650)));

% GB
pData = readCmaLidarData(polCaliPDataFile_GB, 'nMaxBin', 2000);
nData = readCmaLidarData(polCaliNDataFile_GB, 'nMaxBin', 2000);
polCaliData_GB.height = pData.height;
polCaliData_GB.gainRatioP = (pData.rawSignal(1, :) - nanmean(pData.rawSignal(1, 1500:1700))) ./ (pData.rawSignal(2, :) - nanmean(pData.rawSignal(2, 1500:1700)));
polCaliData_GB.gainRatioN = (nData.rawSignal(1, :) - nanmean(nData.rawSignal(1, 1500:1700))) ./ (nData.rawSignal(2, :) - nanmean(nData.rawSignal(2, 1500:1700)));
ratioTmp = polCaliData_GB.gainRatioN .* polCaliData_GB.gainRatioP;
ratioTmp(ratioTmp < 0) = NaN;
polCaliData_GB.gainRatio = sqrt(ratioTmp);

% ZK
oData = readCmaLidarData(polCaliDataFile_ZK, 'nMaxBin', 950);
polCaliData_ZK.height = oData.height;
polCaliData_ZK.gainRatio = (oData.rawSignal(1, :) - nanmean(oData.rawSignal(1, 850:900))) ./ (oData.rawSignal(2, :) - nanmean(oData.rawSignal(2, 850:900)));

% SY
pData = readCmaLidarData(polCaliPDataFile_SY, 'nMaxBin', 1500);
nData = readCmaLidarData(polCaliNDataFile_SY, 'nMaxBin', 1500);
polCaliData_SY.height = pData.height;
polCaliData_SY.gainRatioP = (pData.rawSignal(1, :) - nanmean(pData.rawSignal(1, 1400:1480))) ./ (pData.rawSignal(2, :) - nanmean(pData.rawSignal(2, 1400:1480)));
polCaliData_SY.gainRatioN = (nData.rawSignal(1, :) - nanmean(nData.rawSignal(1, 1400:1480))) ./ (nData.rawSignal(2, :) - nanmean(nData.rawSignal(2, 1400:1480)));
ratioTmp = polCaliData_SY.gainRatioP .* polCaliData_SY.gainRatioN;
ratioTmp(ratioTmp < 0) = NaN;
polCaliData_SY.gainRatio = sqrt(ratioTmp);

%% data visualization

% L7
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_L7.height >= caliRange_L7(1)) & (polCaliData_L7.height <= caliRange_L7(2));
gainRatio_L7 = nanmean(polCaliData_L7.gainRatio(isHCali));
gainRatioStd_L7 = nanstd(polCaliData_L7.gainRatio(isHCali));
fprintf('Gainratio L7: %f+-%f\n', gainRatio_L7, gainRatioStd_L7);
p1 = plot(polCaliData_L7.height(isHCali), polCaliData_L7.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_L7.height(1), polCaliData_L7.height(end)], [1, 1] * gainRatio_L7, '--k');
p3 = plot([polCaliData_L7.height(1), polCaliData_L7.height(end)], [1, 1] * gainRatioStd_L7 + gainRatio_L7, '-.k');
p4 = plot([polCaliData_L7.height(1), polCaliData_L7.height(end)], [-1, -1] * gainRatioStd_L7 + gainRatio_L7, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('L7');

xlim(caliRange_L7);
ylim([0, 0.2]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('L7_gaintio_full.png'), '-r300');

% L7 (slot)
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_L7.height >= caliRangeSlot_L7(1)) & (polCaliData_L7.height <= caliRangeSlot_L7(2));
gainRatio_L7 = nanmean(polCaliData_L7.gainRatio(isHCali));
gainRatioStd_L7 = nanstd(polCaliData_L7.gainRatio(isHCali));
fprintf('Gainratio L7: %f+-%f\n', gainRatio_L7, gainRatioStd_L7);
p1 = plot(polCaliData_L7.height(isHCali), polCaliData_L7.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_L7.height(1), polCaliData_L7.height(end)], [1, 1] * gainRatio_L7, '--k');
p3 = plot([polCaliData_L7.height(1), polCaliData_L7.height(end)], [1, 1] * gainRatioStd_L7 + gainRatio_L7, '-.k');
p4 = plot([polCaliData_L7.height(1), polCaliData_L7.height(end)], [-1, -1] * gainRatioStd_L7 + gainRatio_L7, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('L7');

xlim(caliRangeSlot_L7);
ylim([0.04, 0.08]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('L7_gaintio_slot.png'), '-r300');

% SY
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_SY.height >= caliRange_SY(1)) & (polCaliData_SY.height <= caliRange_SY(2));
gainRatio_SY = nanmean(polCaliData_SY.gainRatio(isHCali));
gainRatioStd_SY = nanstd(polCaliData_SY.gainRatio(isHCali));
fprintf('Gainratio SY: %f+-%f\n', gainRatio_SY, gainRatioStd_SY);
p1 = plot(polCaliData_SY.height(isHCali), polCaliData_SY.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_SY.height(1), polCaliData_SY.height(end)], [1, 1] * gainRatio_SY, '--k');
p3 = plot([polCaliData_SY.height(1), polCaliData_SY.height(end)], [1, 1] * gainRatioStd_SY + gainRatio_SY, '-.k');
p4 = plot([polCaliData_SY.height(1), polCaliData_SY.height(end)], [-1, -1] * gainRatioStd_SY + gainRatio_SY, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('SY');

xlim(caliRange_SY);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('SY_gaintio_full.png'), '-r300');

% SY (slot)
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_SY.height >= caliRangeSlot_SY(1)) & (polCaliData_SY.height <= caliRangeSlot_SY(2));
gainRatio_SY = nanmean(polCaliData_SY.gainRatio(isHCali));
gainRatioStd_SY = nanstd(polCaliData_SY.gainRatio(isHCali));
fprintf('Gainratio SY: %f+-%f\n', gainRatio_SY, gainRatioStd_SY);
p1 = plot(polCaliData_SY.height(isHCali), polCaliData_SY.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_SY.height(1), polCaliData_SY.height(end)], [1, 1] * gainRatio_SY, '--k');
p3 = plot([polCaliData_SY.height(1), polCaliData_SY.height(end)], [1, 1] * gainRatioStd_SY + gainRatio_SY, '-.k');
p4 = plot([polCaliData_SY.height(1), polCaliData_SY.height(end)], [-1, -1] * gainRatioStd_SY + gainRatio_SY, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('SY');

xlim(caliRangeSlot_SY);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('SY_gaintio_slot.png'), '-r300');

% GB
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_GB.height >= caliRange_GB(1)) & (polCaliData_GB.height <= caliRange_GB(2));
gainRatio_GB = nanmean(polCaliData_GB.gainRatio(isHCali));
gainRatioStd_GB = nanstd(polCaliData_GB.gainRatio(isHCali));
fprintf('Gainratio GB: %f+-%f\n', gainRatio_GB, gainRatioStd_GB);
p1 = plot(polCaliData_GB.height(isHCali), polCaliData_GB.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_GB.height(1), polCaliData_GB.height(end)], [1, 1] * gainRatio_GB, '--k');
p3 = plot([polCaliData_GB.height(1), polCaliData_GB.height(end)], [1, 1] * gainRatioStd_GB + gainRatio_GB, '-.k');
p4 = plot([polCaliData_GB.height(1), polCaliData_GB.height(end)], [-1, -1] * gainRatioStd_GB + gainRatio_GB, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('GB');

xlim(caliRange_GB);
ylim([0, 0.6]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('GB_gaintio_full.png'), '-r300');

% GB (slot)
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_GB.height >= caliRangeSlot_GB(1)) & (polCaliData_GB.height <= caliRangeSlot_GB(2));
gainRatio_GB = nanmean(polCaliData_GB.gainRatio(isHCali));
gainRatioStd_GB = nanstd(polCaliData_GB.gainRatio(isHCali));
fprintf('Gainratio GB: %f+-%f\n', gainRatio_GB, gainRatioStd_GB);
p1 = plot(polCaliData_GB.height(isHCali), polCaliData_GB.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_GB.height(1), polCaliData_GB.height(end)], [1, 1] * gainRatio_GB, '--k');
p3 = plot([polCaliData_GB.height(1), polCaliData_GB.height(end)], [1, 1] * gainRatioStd_GB + gainRatio_GB, '-.k');
p4 = plot([polCaliData_GB.height(1), polCaliData_GB.height(end)], [-1, -1] * gainRatioStd_GB + gainRatio_GB, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('GB');

xlim(caliRangeSlot_GB);
ylim([0, 0.6]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('GB_gaintio_slot.png'), '-r300');

% ZK
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_ZK.height >= caliRange_ZK(1)) & (polCaliData_ZK.height <= caliRange_ZK(2));
gainRatio_ZK = nanmean(polCaliData_ZK.gainRatio(isHCali));
gainRatioStd_ZK = nanstd(polCaliData_ZK.gainRatio(isHCali));
fprintf('Gainratio ZK: %f+-%f\n', gainRatio_ZK, gainRatioStd_ZK);
p1 = plot(polCaliData_ZK.height(isHCali), polCaliData_ZK.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_ZK.height(1), polCaliData_ZK.height(end)], [1, 1] * gainRatio_ZK, '--k');
p3 = plot([polCaliData_ZK.height(1), polCaliData_ZK.height(end)], [1, 1] * gainRatioStd_ZK + gainRatio_ZK, '-.k');
p4 = plot([polCaliData_ZK.height(1), polCaliData_ZK.height(end)], [-1, -1] * gainRatioStd_ZK + gainRatio_ZK, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('ZK');

xlim(caliRange_ZK);
ylim([0, 100])

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('ZK_gaintio_full.png'), '-r300');

% ZK (slot)
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_ZK.height >= caliRangeSlot_ZK(1)) & (polCaliData_ZK.height <= caliRangeSlot_ZK(2));
gainRatio_ZK = nanmean(polCaliData_ZK.gainRatio(isHCali));
gainRatioStd_ZK = nanstd(polCaliData_ZK.gainRatio(isHCali));
fprintf('Gainratio ZK: %f+-%f\n', gainRatio_ZK, gainRatioStd_ZK);
p1 = plot(polCaliData_ZK.height(isHCali), polCaliData_ZK.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_ZK.height(1), polCaliData_ZK.height(end)], [1, 1] * gainRatio_ZK, '--k');
p3 = plot([polCaliData_ZK.height(1), polCaliData_ZK.height(end)], [1, 1] * gainRatioStd_ZK + gainRatio_ZK, '-.k');
p4 = plot([polCaliData_ZK.height(1), polCaliData_ZK.height(end)], [-1, -1] * gainRatioStd_ZK + gainRatio_ZK, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('ZK');

xlim(caliRangeSlot_ZK);
ylim([40, 80])

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('ZK_gaintio_slot.png'), '-r300');
