global LEToolboxInfo
close all;

%% Parameter definition
dataFolder355 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', '355');
dataFolder532 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', '532');
dataFolder1064 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', '1064');
dataFolder387 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', 'Raman1');
dataFolder607 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', 'Raman2');
solution355 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', 'Solutions', 'aerowv1.000.txt');
solution532 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', 'Solutions', 'aerowv2.000.txt');
solution1064 = fullfile(LEToolboxInfo.projectDir, 'data', 'EARLINET_test_dataset', 'ASCII', 'Solutions', 'aerowv3.000.txt');;  

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
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
    fclose(fid);

    height355 = data1{1};
    signal355 = signal355 + data1{2};

    fid = fopen(dataFiles387{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
    fclose(fid);

    signal387 = signal387 + data1{2};
end

% 532 + 607 nm signal
height532 = zeros(1999, 1);
signal532 = zeros(1999, 1);
signal607 = zeros(1999, 1);

for iFile = 1:length(dataFiles532)
    fid = fopen(dataFiles532{iFile}, 'r');
    data1 = textscan(fid, '%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
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
aExtTrue355 = data3{4};
aLRTrue355 = data3{5};

% 532 nm aerosol optical properties
fid = fopen(solution532, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
fclose(fid);

aExtTrue532 = data3{4};
aLRTrue532 = data3{5};

% 1064 nm aerosol optical properties
fid = fopen(solution1064, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);
fclose(fid);

aExtTrue1064 = data3{4};
aLRTrue1064 = data3{5};

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
aExt355R = LidarRamanExt(height355', signal387NoBg', 355, 387, 1, pressure', temperature' + 273.14, 40, 380, 70, 'moving');
aExt532R = LidarRamanExt(height532', signal607NoBg', 532, 607, 1, pressure', temperature' + 273.14, 40, 380, 70, 'moving');
[aBsc355R, aLR355] = LidarRamanBsc(height355', signal355NoBg', signal387NoBg', aExt355R, 1, mExt355', mBsc355', [7500, 8500], 355, 0, 5, true);
[aBsc532R, aLR532] = LidarRamanBsc(height532', signal532NoBg', signal607NoBg', aExt532R, 1, mExt532', mBsc532', [7500, 8500], 532, 0, 5, true);

%% Fernald retrieval
aBsc355F = CMAFernald(height355', signal355NoBg', bg355, 50, [9000, 10000], 0, mBsc355, 4);
aBsc532F = CMAFernald(height532', signal532NoBg', bg532, 50, [9000, 10000], 0, mBsc532, 4);
aBsc1064F = CMAFernald(height1064', signal1064NoBg', bg1064, 50, [9000, 10000], 0, mBsc1064, 4);

%% data visualization

% 355
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

xlim([0, 50]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p1 = plot(aExtTrue355 ./ aLRTrue355 * 1e6, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'True');
p2 = plot(aBsc355R * 1e6, height355 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 3]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(aExtTrue355 * 1e6, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'True');
plot(aExt355R * 1e6, height355 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
hold off;

xlabel('Extinction (Mm-1)');
ylabel('');

xlim([0, 200]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_raman_355.png'), '-r300');

% 532
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

xlim([0, 50]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p1 = plot(aExtTrue532 ./ aLRTrue532 * 1e6, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'True');
p2 = plot(aBsc532R * 1e6, height532 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 3]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
plot(aExtTrue532 * 1e6, height532 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', 'True');
plot(aExt532R * 1e6, height532 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', 'Raman ret.');
hold off;

xlabel('Extinction (Mm-1)');
ylabel('');

xlim([0, 200]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_raman_532.png'), '-r300');

% Fernald retrieval
figure('Position', [0, 10, 800, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 4, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
hold on;
signal355NoBg(signal355NoBg <= 0) = NaN;
signal532NoBg(signal532NoBg <= 0) = NaN;
signal1064NoBg(signal1064NoBg <= 0) = NaN;
p1 = semilogx(signal355NoBg / length(dataFiles355) * 10 / 2400, height355 * 1e-3, '-b', 'LineWidth', 1, 'DisplayName', '355'); 
p2 = semilogx(signal532NoBg / length(dataFiles532) * 10 / 2400, height532 * 1e-3, '-g', 'LineWidth', 1, 'DisplayName', '532'); 
p3 = semilogx(signal1064NoBg / length(dataFiles1064) * 10 / 2400, height1064 * 1e-3, '-r', 'LineWidth', 1, 'DisplayName', '1064');
hold off;

xlabel('Signal');
ylabel('Height (km)');

xlim([0, 50]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'XTick', 10.^(-3:2:2), 'XScale', 'log', 'YMinorTick', 'on', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2, p3], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(2, :), 'Units', 'Normalized');
hold on;
p1 = plot(aExtTrue355 ./ aLRTrue355 * 1e6, height355 * 1e-3, '-', 'Color', [76, 182, 184] / 255, 'LineWidth', 1, 'DisplayName', 'True (355 nm)');
p2 = plot(aBsc355F * 1e6, height355 * 1e-3, '-', 'Color', [37, 112, 107] / 255, 'LineWidth', 1, 'DisplayName', 'Fernald ret.');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 3]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(3, :), 'Units', 'Normalized');
hold on;
p1 = plot(aExtTrue532 ./ aLRTrue532 * 1e6, height532 * 1e-3, '-', 'Color', [207, 252, 131] / 255, 'LineWidth', 1, 'DisplayName', 'True (532 nm)');
p2 = plot(aBsc532F * 1e6, height532 * 1e-3, '-', 'Color', [75, 140, 116] / 255, 'LineWidth', 1, 'DisplayName', 'Fernald ret.');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 3]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

subplot('Position', subPos(4, :), 'Units', 'Normalized');
hold on;
p1 = plot(aExtTrue1064 ./ aLRTrue1064 * 1e6, height1064 * 1e-3, '-', 'Color', [234, 46, 73] / 255, 'LineWidth', 1, 'DisplayName', 'True (1064 nm)');
p2 = plot(aBsc1064F * 1e6, height1064 * 1e-3, '-', 'Color', [191, 4, 38] / 255, 'LineWidth', 1, 'DisplayName', 'Fernald ret.');
hold off;

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 3]);
ylim([0, 10]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on', 'FontSize', 11);

l = legend([p1, p2], 'Location', 'NorthEast');
l.FontSize = 11;

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_fernald.png'), '-r300');