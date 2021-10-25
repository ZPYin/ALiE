clc; close all;

%% parameter initialization
polCaliPDataFile_SY = 'D:\Data\CMA_Lidar_Comparison\internalChk\SY\偏振自标定_山仪所_1012(1)_new\AL02_L0103_54399_Lidar_20211012222838.bin';
polCaliNDataFile_SY = 'D:\Data\CMA_Lidar_Comparison\internalChk\SY\偏振自标定_山仪所_1012(1)_new\AL02_L0103_54399_Lidar_20211012222945.bin';

caliRange_SY = [0, 17000];
caliRangeSlot_SY = [3000, 5000];

%% read data

% SY
pData = readCmaLidarData(polCaliPDataFile_SY, 'nMaxBin', 1666);
nData = readCmaLidarData(polCaliNDataFile_SY, 'nMaxBin', 1666);
polCaliData_SY.height = pData.height;
polCaliData_SY.gainRatioP = (pData.rawSignal(1, :) - nanmean(pData.rawSignal(1, 1550:1650))) ./ (pData.rawSignal(2, :) - nanmean(pData.rawSignal(2, 1550:1650)));
polCaliData_SY.gainRatioN = (nData.rawSignal(1, :) - nanmean(nData.rawSignal(1, 1550:1650))) ./ (nData.rawSignal(2, :) - nanmean(nData.rawSignal(2, 1550:1650)));
ratioTmp = polCaliData_SY.gainRatioN .* polCaliData_SY.gainRatioP;
ratioTmp(ratioTmp < 0) = NaN;
polCaliData_SY.gainRatio = sqrt(ratioTmp);

%% data visualization

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
ylim([0, 2]);

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
ylim([0, 2]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('SY_gaintio_slot.png'), '-r300');