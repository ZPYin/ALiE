% Test Fernald and Raman method based on EARLINET test dataset.
%
% Author: Zhenping Yin
% Date: 2026-03-15

global LEToolboxInfo
close all;

%% Parameter definition
testDatasetPath = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII');
dataFolder355 = fullfile(testDatasetPath, '355');
dataFolder532 = fullfile(testDatasetPath, '532');
dataFolder1064 = fullfile(testDatasetPath, '1064');
dataFolder387 = fullfile(testDatasetPath, 'Raman1');
dataFolder607 = fullfile(testDatasetPath, 'Raman2');
solution355 = fullfile(testDatasetPath, 'Solutions', 'aerowv1.000.txt');
solution532 = fullfile(testDatasetPath, 'Solutions', 'aerowv2.000.txt');
solution1064 = fullfile(testDatasetPath, 'Solutions', 'aerowv3.000.txt');

%% Read data
dataFiles355 = listfile(dataFolder355, '.*.txt', 1);
dataFiles387 = listfile(dataFolder387, '.*.txt', 1);
dataFiles532 = listfile(dataFolder532, '.*.txt', 1);
dataFiles607 = listfile(dataFolder607, '.*.txt', 1);
dataFiles1064 = listfile(dataFolder1064, '.*.txt', 1);

% 355 + 386 nm signal
height355 = zeros(1999, 1);
signal355 = zeros(1999, 1);
signal387 = zeros(1999, 1);

for iFile = 1:length(dataFiles355)
    fid = fopen(dataFiles355{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', ...
                     'MultipleDelimsAsOne', true, 'headerlines', 9);
    fclose(fid);

    height355 = data1{1};
    signal355 = signal355 + data1{2};

    fid = fopen(dataFiles387{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', ...
                     'MultipleDelimsAsOne', true, 'headerlines', 9);
    fclose(fid);

    signal387 = signal387 + data1{2};
end

% 532 + 607 nm signal
height532 = zeros(1999, 1);
signal532 = zeros(1999, 1);
signal607 = zeros(1999, 1);

for iFile = 1:length(dataFiles532)
    fid = fopen(dataFiles532{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', ...
                    'MultipleDelimsAsOne', true, 'headerlines', 9);
    fclose(fid);

    height532 = data1{1};
    signal532 = signal532 + data1{2};

    fid = fopen(dataFiles607{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
    fclose(fid);

    signal607 = signal607 + data1{2};
end

% 1064 nm signal
height1064 = zeros(1999, 1);
signal1064 = zeros(1999, 1);

for iFile = 1:length(dataFiles1064)
    fid = fopen(dataFiles1064{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);
    fclose(fid);

    height1064 = data1{1};
    signal1064 = signal1064 + data1{2};
end

% 355 nm aerosol optical properties
fid = fopen(solution355, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
fclose(fid);

% pressure = data3{2};
% temperature = data3{3};
aExtTrue355 = transpose(data3{4});
aLRTrue355 = transpose(data3{5});
aBscTrue355 = aExtTrue355 ./ aLRTrue355;

% 532 nm aerosol optical properties
fid = fopen(solution532, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
fclose(fid);

aExtTrue532 = transpose(data3{4});
aLRTrue532 = transpose(data3{5});
aBscTrue532 = aExtTrue532 ./ aLRTrue532;

% 1064 nm aerosol optical properties
fid = fopen(solution1064, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);
fclose(fid);

aExtTrue1064 = transpose(data3{4});
aLRTrue1064 = transpose(data3{5});
aBscTrue1064 = aExtTrue1064 ./ aLRTrue1064;

%% Remove background
bg355 = nanmean(signal355(1850:1950));
signal355NoBg = signal355 - bg355;
bg387 = nanmean(signal387(1850:1950));
signal387NoBg = signal387 - bg387;
bg532 = nanmean(signal532(1850:1950));
signal532NoBg = signal532 - bg532;
bg607 = nanmean(signal607(1850:1950));
signal607NoBg = signal607 - bg607;
bg1064 = nanmean(signal1064(1850:1950));
signal1064NoBg = signal1064 - bg1064;

%% Molecular scattering
[temperature, pressure, ~, ~] = read_meteordata(datenum(0, 1, 0, 0, 0, 0), height355, ...
                                                'meteor_data', 'standard_atmosphere');
[mBsc355, mExt355] = rayleigh_scattering(355, pressure, temperature + 273.14, 360, 80);
[mBsc532, mExt532] = rayleigh_scattering(532, pressure, temperature + 273.14, 360, 80);
[mBsc1064, mExt1064] = rayleigh_scattering(1064, pressure, temperature + 273.14, 360, 80);

%% Raman retrieval
aExt355R = LidarRamanExt(height355', signal387NoBg', 355, 387, 1, pressure', temperature' + 273.14, 20, 380, 70, 'movingslope');
aExt532R = LidarRamanExt(height532', signal607NoBg', 532, 607, 1, pressure', temperature' + 273.14, 20, 380, 70, 'movingslope');
[aBsc355R, aLR355] = LidarRamanBsc(height355', signal355NoBg', signal387NoBg', aExt355R, 1, mExt355', mBsc355', [7500, 8500], 355, 0, 5, true);
[aBsc532R, aLR532] = LidarRamanBsc(height532', signal532NoBg', signal607NoBg', aExt532R, 1, mExt532', mBsc532', [7500, 8500], 532, 0, 5, true);

%% Fernald retrieval
aBsc355F = CMAFernald(height355', signal355NoBg', bg355, 50, [9000, 10000], 0, mBsc355, 4);
aBsc532F = CMAFernald(height532', signal532NoBg', bg532, 50, [9000, 10000], 0, mBsc532, 4);
aBsc1064F = CMAFernald(height1064', signal1064NoBg', bg1064, 50, [9000, 10000], 0, mBsc1064, 4);

%% Error analysis

% 355 nm
bias355F = NaN(size(aBsc355F));
relBias355F = NaN(size(aBsc355F));
isInValRange = (aBsc355F > 1e-7);
bias355F(isInValRange) = aBsc355F(isInValRange) - aBscTrue355(isInValRange);
relBias355F(isInValRange) = (aBsc355F(isInValRange) - aBscTrue355(isInValRange)) ./ aBscTrue355(isInValRange);
meanBias355F = nanmean(aBsc355F(isInValRange) - aBscTrue355(isInValRange));
stdBias355F = nanstd(bias355F(isInValRange));

biasBsc355R = NaN(size(aBsc355R));
relBiasBsc355R = NaN(size(aBsc355R));
isInValRange = (aBsc355R > 1e-7);
biasBsc355R(isInValRange) = aBsc355R(isInValRange) - aBscTrue355(isInValRange);
relBiasBsc355R(isInValRange) = (aBsc355R(isInValRange) - aBscTrue355(isInValRange)) ./ aBscTrue355(isInValRange);
meanBiasBsc355R = nanmean(aBsc355R(isInValRange) - aBscTrue355(isInValRange));
stdBiasBsc355R = nanstd(biasBsc355R(isInValRange));

biasExt355R = aExt355R - aExtTrue355;
relBiasExt355R = (aExt355R - aExtTrue355) ./ aExtTrue355;
meanBiasExt355R = nanmean(biasExt355R);
stdBiasExt355R = nanstd(biasExt355R);
biasLR355R = aLR355 - aLRTrue355;
relBiasLR355R = (aLR355 - aLRTrue355) ./ aLRTrue355;
meanBiasLR355R = nanmean(biasLR355R);
stdBiasLR355R = nanstd(biasLR355R);

% 532 nm
bias532F = NaN(size(aBsc532F));
relBias532F = NaN(size(aBsc532F));
isInValRange = (aBsc532F > 1e-7);
bias532F(isInValRange) = aBsc532F(isInValRange) - aBscTrue532(isInValRange);
relBias532F(isInValRange) = (aBsc532F(isInValRange) - aBscTrue532(isInValRange)) ./ aBscTrue532(isInValRange);
meanBias532F = nanmean(aBsc532F(isInValRange) - aBscTrue532(isInValRange));
stdBias532F = nanstd(bias532F(isInValRange));

biasBsc532R = NaN(size(aBsc532R));
relBiasBsc532R = NaN(size(aBsc532R));
isInValRange = (aBsc532R > 1e-7);
biasBsc532R(isInValRange) = aBsc532R(isInValRange) - aBscTrue532(isInValRange);
relBiasBsc532R(isInValRange) = (aBsc532R(isInValRange) - aBscTrue532(isInValRange)) ./ aBscTrue532(isInValRange);
meanBiasBsc532R = nanmean(aBsc532R(isInValRange) - aBscTrue532(isInValRange));
stdBiasBsc532R = nanstd(biasBsc532R(isInValRange));

biasExt532R = aExt532R - aExtTrue532;
relBiasExt532R = (aExt532R - aExtTrue532) ./ aExtTrue532;
meanBiasExt532R = nanmean(biasExt532R);
stdBiasExt532R = nanstd(biasExt532R);
biasLR532R = aLR532 - aLRTrue532;
relBiasLR532R = (aLR532 - aLRTrue532) ./ aLRTrue532;
meanBiasLR532R = nanmean(biasLR532R);
stdBiasLR532R = nanstd(biasLR532R);

% 1064 nm
bias1064F = NaN(size(aBsc1064F));
relBias1064F = NaN(size(aBsc1064F));
isInValRange = (aBsc1064F > 1e-7);
bias1064F(isInValRange) = aBsc1064F(isInValRange) - aBscTrue1064(isInValRange);
relBias1064F(isInValRange) = (aBsc1064F(isInValRange) - aBscTrue1064(isInValRange)) ./ aBscTrue1064(isInValRange);
meanBias1064F = nanmean(aBsc1064F(isInValRange) - aBscTrue1064(isInValRange));
stdBias1064F = nanstd(bias1064F(isInValRange));

%% data visualization

% 355 Fernald retrieval
figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal355NoBg(signal355NoBg <= 0) = NaN;
p1 = semilogx(signal355NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '355 elastic'); 
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend(p1, 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aBsc355F * 1e6, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Fernald ret.');
p1 = plot(aExtTrue355 ./ aLRTrue355 * 1e6, height355 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBias355F, height355 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1sr-1\nStd: %4.2fMm-1sr-1', meanBias355F * 1e6, stdBias355F * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Fernald_355.png'), '-r300');

% 355 nm Raman retrieval 
figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal355NoBg(signal355NoBg <= 0) = NaN;
signal387NoBg(signal387NoBg <= 0) = NaN;
p1 = semilogx(signal355NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '355'); 
p2 = semilogx(signal387NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '387');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aBsc355R * 1e6, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
p1 = plot(aExtTrue355 ./ aLRTrue355 * 1e6, height355 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBiasBsc355R, height355 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1sr-1\nStd: %4.2fMm-1sr-1', meanBiasBsc355R * 1e6, stdBiasBsc355R * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Raman_bsc_355.png'), '-r300');

figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal387NoBg(signal387NoBg <= 0) = NaN;
p1 = semilogx(signal387NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '387');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend(p1, 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aExt355R * 1e6, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
p1 = plot(aExtTrue355 * 1e6, height355 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Extinction (Mm-1)');
ylabel('');

xlim([0, 200]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBiasExt355R, height355 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1\nStd: %4.2fMm-1', meanBiasExt355R * 1e6, stdBiasExt355R * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Raman_ext_355.png'), '-r300');

figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal355NoBg(signal355NoBg <= 0) = NaN;
signal387NoBg(signal387NoBg <= 0) = NaN;
p1 = semilogx(signal355NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '355'); 
p2 = semilogx(signal387NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '387');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aLR355, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
p1 = plot(aLRTrue355, height355 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Lidar ratio (sr)');
ylabel('');

xlim([0, 100]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBiasLR355R, height355 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fsr\nStd: %4.2fsr', meanBiasLR355R, stdBiasLR355R), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Raman_lr_355.png'), '-r300');

% 532 Fernald retrieval
figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal532NoBg(signal532NoBg <= 0) = NaN;
p1 = semilogx(signal532NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '532 elastic'); 
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend(p1, 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aBsc532F * 1e6, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Fernald ret.');
p1 = plot(aExtTrue532 ./ aLRTrue532 * 1e6, height532 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBias532F, height532 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1sr-1\nStd: %4.2fMm-1sr-1', meanBias532F * 1e6, stdBias532F * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Fernald_532.png'), '-r300');

% 532 nm Raman retrieval 
figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal532NoBg(signal532NoBg <= 0) = NaN;
signal607NoBg(signal607NoBg <= 0) = NaN;
p1 = semilogx(signal532NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '532'); 
p2 = semilogx(signal607NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '607');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aBsc532R * 1e6, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
p1 = plot(aExtTrue532 ./ aLRTrue532 * 1e6, height532 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBiasBsc532R, height532 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1sr-1\nStd: %4.2fMm-1sr-1', meanBiasBsc532R * 1e6, stdBiasBsc532R * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Raman_bsc_532.png'), '-r300');

figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal607NoBg(signal607NoBg <= 0) = NaN;
p1 = semilogx(signal607NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '607');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend(p1, 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aExt532R * 1e6, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
p1 = plot(aExtTrue532 * 1e6, height532 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Extinction (Mm-1)');
ylabel('');

xlim([0, 200]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBiasExt532R, height532 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1\nStd: %4.2fMm-1', meanBiasExt532R * 1e6, stdBiasExt532R * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Raman_ext_532.png'), '-r300');

figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal532NoBg(signal532NoBg <= 0) = NaN;
signal607NoBg(signal607NoBg <= 0) = NaN;
p1 = semilogx(signal532NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '532'); 
p2 = semilogx(signal607NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '607');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aLR532, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
p1 = plot(aLRTrue532, height532 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Lidar ratio (sr)');
ylabel('');

xlim([0, 100]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBiasLR532R, height532 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fsr\nStd: %4.2fsr', meanBiasLR532R, stdBiasLR532R), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Raman_lr_532.png'), '-r300');

% 1064 Fernald retrieval
figure('Position', [0, 10, 600, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal1064NoBg(signal1064NoBg <= 0) = NaN;
p1 = semilogx(signal1064NoBg / length(dataFiles1064) * 10 / 2400, height1064 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '1064 elastic'); 
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([1e-3, 1e2]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend(p1, 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p2 = plot(aBsc1064F * 1e6, height1064 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'Fernald ret.');
p1 = plot(aExtTrue1064 ./ aLRTrue1064 * 1e6, height1064 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', 'True');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(relBias1064F, height1064 * 1e-3, '-b', 'LineWidth', 1);
xline(0, '--k', 'LineWidth', 1);
xline(0.25, '-.r', 'LineWidth', 1);
xline(-0.25, '-.r', 'LineWidth', 1);
hold off;

xlabel('Rel. Bias');
ylabel('');

text(0.1, 0.8, sprintf('Mean: %4.2fMm-1sr-1\nStd: %4.2fMm-1sr-1', meanBias1064F * 1e6, stdBias1064F * 1e6), ...
    'Units', 'Normalized', 'FontSize', 11);

xlim([-0.5, 0.5]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_Fernald_1064.png'), '-r300');