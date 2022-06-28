clc;
close all;

%% Parameter definition
dataFolder355 = 'D:\Data\EARLINET_test_dataset\ASCII\355';
dataFolder387 = 'D:\Data\EARLINET_test_dataset\ASCII\Raman1';
dataFolder532 = 'D:\Data\EARLINET_test_dataset\ASCII\532';
dataFolder607 = 'D:\Data\EARLINET_test_dataset\ASCII\Raman2';
solution355 = 'D:\Data\EARLINET_test_dataset\ASCII\Solutions\aerowv1.000.txt';
solution532 = 'D:\Data\EARLINET_test_dataset\ASCII\Solutions\aerowv2.000.txt';

%% Read data
dataFiles355 = listfile(dataFolder355, '.*.txt', 1);
dataFiles387 = listfile(dataFolder387, '.*.txt', 1);
dataFiles532 = listfile(dataFolder532, '.*.txt', 1);
dataFiles607 = listfile(dataFolder607, '.*.txt', 1);

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

fid = fopen(solution355, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
fclose(fid);

pressure = data3{2};
temperature = data3{3};
aExtTrue355 = data3{4};
aLRTrue355 = data3{5};

fid = fopen(solution532, 'r');
data3 = textscan(fid, '%f%f%f%f%f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'headerlines', 9);
fclose(fid);

aExtTrue532 = data3{4};
aLRTrue532 = data3{5};

%% Remove background
signal355NoBg = signal355 - nanmean(signal355(1800:1900));
signal387NoBg = signal387 - nanmean(signal387(1800:1900));
signal532NoBg = signal532 - nanmean(signal532(1800:1900));
signal607NoBg = signal607 - nanmean(signal607(1800:1900));

%% Molecular scattering
[mBsc355, mExt355] = rayleigh_scattering(355, pressure, temperature + 273.14, 360, 80);
[mBsc532, mExt532] = rayleigh_scattering(532, pressure, temperature + 273.14, 360, 80);

%% Raman retrieval
aExt355 = LidarRamanExt(height355', signal387NoBg', 355, 387, 1, pressure', temperature' + 273.14, 40, 380, 70, 'moving');
aExt532 = LidarRamanExt(height532', signal607NoBg', 532, 607, 1, pressure', temperature' + 273.14, 40, 380, 70, 'moving');
[aBsc355, aLR355] = LidarRamanBsc(height355', signal355NoBg', signal387NoBg', aExt355, 1, mExt355', mBsc355', [7000, 8000], 355, 0, 5, true);
[aBsc532, aLR532] = LidarRamanBsc(height532', signal532NoBg', signal607NoBg', aExt532, 1, mExt532', mBsc532', [7000, 8000], 532, 0, 5, true);

%% data visualization

% 355
figure('Position', [0, 10, 650, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
p1 = semilogx(signal355NoBg / length(dataFiles355) * 10 / 2400, height355, '-b', 'DisplayName', '355'); hold on;
p2 = semilogx(signal387NoBg / length(dataFiles355) * 10 / 2400, height355, '-g', 'DisplayName', '387');

xlabel('Signal');
ylabel('Height (m)');

xlim([0, 50]);
ylim([0, 10000]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Box', 'on');

legend([p1, p2], 'Location', 'NorthEast');

subplot('Position', subPos(2, :), 'Units', 'Normalized');
p1 = plot(aExtTrue355 ./ aLRTrue355 * 1e6, height355, '-b', 'DisplayName', 'True'); hold on;
p2 = plot(aBsc355 * 1e6, height355, '-g', 'DisplayName', 'Retrieval');

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 4]);
ylim([0, 10000]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on');

legend([p1, p2], 'Location', 'NorthEast');

subplot('Position', subPos(3, :), 'Units', 'Normalized');
p1 = plot(aExtTrue355 * 1e6, height355, '-b', 'DisplayName', 'True'); hold on;
p2 = plot(aExt355 * 1e6, height355, '-g', 'DisplayName', 'Retrieval');

xlabel('Extinction (Mm-1)');
ylabel('');

xlim([0, 300]);
ylim([0, 10000]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on');

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_355.png'), '-r300');

% 532
figure('Position', [0, 10, 700, 400], 'Units', 'Pixels', 'Color', 'w');

subPos = subfigPos([0.1, 0.15, 0.88, 0.83], 1, 3, 0.02, 0);

subplot('Position', subPos(1, :), 'Units', 'Normalized');
p1 = semilogx(signal532NoBg / length(dataFiles532) * 10 / 2400, height532, '-b', 'DisplayName', '532'); hold on;
p2 = semilogx(signal607NoBg / length(dataFiles532) * 10 / 2400, height532, '-g', 'DisplayName', '607');

xlabel('Signal');
ylabel('Height (m)');

xlim([0, 50]);
ylim([0, 10000]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Box', 'on');

legend([p1, p2], 'Location', 'NorthEast');

subplot('Position', subPos(2, :), 'Units', 'Normalized');
p1 = plot(aExtTrue532 ./ aLRTrue532 * 1e6, height532, '-b', 'DisplayName', 'True'); hold on;
p2 = plot(aBsc532 * 1e6, height532, '-g', 'DisplayName', 'Retrieval');

xlabel('Backscatter (Mm-1sr-1)');
ylabel('');

xlim([0, 4]);
ylim([0, 10000]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on');

legend([p1, p2], 'Location', 'NorthEast');

subplot('Position', subPos(3, :), 'Units', 'Normalized');
p1 = plot(aExtTrue532 * 1e6, height532, '-b', 'DisplayName', 'True'); hold on;
p2 = plot(aExt532 * 1e6, height532, '-g', 'DisplayName', 'Retrieval');

xlabel('Extinction (Mm-1)');
ylabel('');

xlim([0, 300]);
ylim([0, 10000]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTicklabel', '', 'Box', 'on');

export_fig(gcf, fullfile(LEToolboxInfo.projectDir, 'image', 'earlinet_test_532.png'), '-r300');