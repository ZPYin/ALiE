clc; close all;

%% parameter initialization
polCaliDataFile_704 = 'D:\Data\CMA_Lidar_Comparison\704\polarization-calibration\AMPLE02_001_Gainratio_20210922175011.txt';
polCaliPDataFile_zkgb = 'D:\Data\CMA_Lidar_Comparison\zkgb\polarization-calibration\AL01_L0102_54511_Lidar_20210917181500.bin';
polCaliNDataFile_zkgb = 'D:\Data\CMA_Lidar_Comparison\zkgb\polarization-calibration\AL01_L0102_54511_Lidar_20210917181600.bin';
polCaliDataFile_wxzk = 'D:\Data\CMA_Lidar_Comparison\wxzk\polarization-calibration\AL01_L0601_Lidar_20210922142507.bin';
polCaliPDataFile_sys = 'D:\Data\CMA_Lidar_Comparison\sys\polarization-calibration\AL02_L0103_54399_Lidar_20210923013955.bin';
polCaliNDataFile_sys = 'D:\Data\CMA_Lidar_Comparison\sys\polarization-calibration\AL02_L0103_54399_Lidar_20210923014102.bin';

caliRange_704 = [2000, 3500];
caliRange_sys = [3500, 4500];
caliRange_zkgb = [500, 1500];
caliRange_wxzk = [1100, 1700];

%% read data

% 704
fid = fopen(polCaliDataFile_704, 'r');
oData = textscan(fid, '%f%f%f%f%f', 'headerlines', 1, 'delimiter', '\t');
polCaliData_704.height = oData{1};
polCaliData_704.gainRatio = (oData{4} - nanmean(oData{4}(550:650))) ./ (oData{5} - nanmean(oData{5}(550:650)));

% zkgb
pData = readCmaLidarData(polCaliPDataFile_zkgb, 'nMaxBin', 2000);
nData = readCmaLidarData(polCaliNDataFile_zkgb, 'nMaxBin', 2000);
polCaliData_zkgb.height = pData.height;
polCaliData_zkgb.gainRatioP = (pData.rawSignal(1, :) - nanmean(pData.rawSignal(1, 1500:1700))) ./ (pData.rawSignal(2, :) - nanmean(pData.rawSignal(2, 1500:1700)));
polCaliData_zkgb.gainRatioN = (nData.rawSignal(1, :) - nanmean(nData.rawSignal(1, 1500:1700))) ./ (nData.rawSignal(2, :) - nanmean(nData.rawSignal(2, 1500:1700)));
polCaliData_zkgb.gainRatio = sqrt(polCaliData_zkgb.gainRatioP .* polCaliData_zkgb.gainRatioN);

% wxzk
oData = readCmaLidarData(polCaliDataFile_wxzk, 'nMaxBin', 950);
polCaliData_wxzk.height = oData.height;
polCaliData_wxzk.gainRatio = (oData.rawSignal(1, :) - nanmean(oData.rawSignal(1, 850:900))) ./ (oData.rawSignal(2, :) - nanmean(oData.rawSignal(2, 850:900)));

% sys
pData = readCmaLidarData(polCaliPDataFile_sys, 'nMaxBin', 1500);
nData = readCmaLidarData(polCaliNDataFile_sys, 'nMaxBin', 1500);
polCaliData_sys.height = pData.height;
polCaliData_sys.gainRatioP = (pData.rawSignal(1, :) - nanmean(pData.rawSignal(1, 1400:1480))) ./ (pData.rawSignal(2, :) - nanmean(pData.rawSignal(2, 1400:1480)));
polCaliData_sys.gainRatioN = (nData.rawSignal(1, :) - nanmean(nData.rawSignal(1, 1400:1480))) ./ (nData.rawSignal(2, :) - nanmean(nData.rawSignal(2, 1400:1480)));
polCaliData_sys.gainRatio = sqrt(polCaliData_sys.gainRatioP .* polCaliData_sys.gainRatioN);

%% data visualization

% 704
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_704.height >= caliRange_704(1)) & (polCaliData_704.height <= caliRange_704(2));
gainRatio_704 = nanmean(polCaliData_704.gainRatio(isHCali));
gainRatioStd_704 = nanstd(polCaliData_704.gainRatio(isHCali));
fprintf('Gainratio 704: %f+-%f\n', gainRatio_704, gainRatioStd_704);
p1 = plot(polCaliData_704.height(isHCali), polCaliData_704.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_704.height(1), polCaliData_704.height(end)], [1, 1] * gainRatio_704, '--k');
p3 = plot([polCaliData_704.height(1), polCaliData_704.height(end)], [1, 1] * gainRatioStd_704 + gainRatio_704, '-.k');
p4 = plot([polCaliData_704.height(1), polCaliData_704.height(end)], [-1, -1] * gainRatioStd_704 + gainRatio_704, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('L7');

xlim(caliRange_704);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');

% sys
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_sys.height >= caliRange_sys(1)) & (polCaliData_sys.height <= caliRange_sys(2));
gainRatio_sys = nanmean(polCaliData_sys.gainRatio(isHCali));
gainRatioStd_sys = nanstd(polCaliData_sys.gainRatio(isHCali));
fprintf('Gainratio sys: %f+-%f\n', gainRatio_sys, gainRatioStd_sys);
p1 = plot(polCaliData_sys.height(isHCali), polCaliData_sys.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_sys.height(1), polCaliData_sys.height(end)], [1, 1] * gainRatio_sys, '--k');
p3 = plot([polCaliData_sys.height(1), polCaliData_sys.height(end)], [1, 1] * gainRatioStd_sys + gainRatio_sys, '-.k');
p4 = plot([polCaliData_sys.height(1), polCaliData_sys.height(end)], [-1, -1] * gainRatioStd_sys + gainRatio_sys, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('SY');

xlim(caliRange_sys);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');

% zkgb
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_zkgb.height >= caliRange_zkgb(1)) & (polCaliData_zkgb.height <= caliRange_zkgb(2));
gainRatio_zkgb = nanmean(polCaliData_zkgb.gainRatio(isHCali));
gainRatioStd_zkgb = nanstd(polCaliData_zkgb.gainRatio(isHCali));
fprintf('Gainratio zkgb: %f+-%f\n', gainRatio_zkgb, gainRatioStd_zkgb);
p1 = plot(polCaliData_zkgb.height(isHCali), polCaliData_zkgb.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_zkgb.height(1), polCaliData_zkgb.height(end)], [1, 1] * gainRatio_zkgb, '--k');
p3 = plot([polCaliData_zkgb.height(1), polCaliData_zkgb.height(end)], [1, 1] * gainRatioStd_zkgb + gainRatio_zkgb, '-.k');
p4 = plot([polCaliData_zkgb.height(1), polCaliData_zkgb.height(end)], [-1, -1] * gainRatioStd_zkgb + gainRatio_zkgb, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('GB');

xlim(caliRange_zkgb);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');

% wxzk
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (polCaliData_wxzk.height >= caliRange_wxzk(1)) & (polCaliData_wxzk.height <= caliRange_wxzk(2));
gainRatio_wxzk = nanmean(polCaliData_wxzk.gainRatio(isHCali));
gainRatioStd_wxzk = nanstd(polCaliData_wxzk.gainRatio(isHCali));
fprintf('Gainratio wxzk: %f+-%f\n', gainRatio_wxzk, gainRatioStd_wxzk);
p1 = plot(polCaliData_wxzk.height(isHCali), polCaliData_wxzk.gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([polCaliData_wxzk.height(1), polCaliData_wxzk.height(end)], [1, 1] * gainRatio_wxzk, '--k');
p3 = plot([polCaliData_wxzk.height(1), polCaliData_wxzk.height(end)], [1, 1] * gainRatioStd_wxzk + gainRatio_wxzk, '-.k');
p4 = plot([polCaliData_wxzk.height(1), polCaliData_wxzk.height(end)], [-1, -1] * gainRatioStd_wxzk + gainRatio_wxzk, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('ZK');

xlim(caliRange_wxzk);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');