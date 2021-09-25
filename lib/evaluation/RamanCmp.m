function RamanCmp(config, reportFile, varargin)
% RAMANCMP Raman retrieval results comparison (external check)
% USAGE:
%    RamanCmp(config, reportFile)
% INPUTS:
%    config: struct
%    reportFile: char
% KEYWORDS:
%    flagDebug: logical
% HISTORY:
%    2021-09-22: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

global LEToolboxInfo

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'config', @isstruct);
addRequired(p, 'reportFile', @ischar);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, config, reportFile, varargin{:});

lidarType = config.externalChkCfg.RamanCmpCfg.LidarList;

%% report file
fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Raman comparison\n');

if length(lidarType) <= 1
    warning('Only 1 lidar was configured.');
    return;
end

%% read data
allData = struct();   % struct with all lidar data

for iLidar = 1:length(lidarType)

    lidarConfig = config.externalChkCfg.(lidarType{iLidar});
    lidarData = struct();

    % check lidar data file
    h5Filename = fullfile(config.dataSavePath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    if exist(h5Filename, 'file') ~= 2
        warning('No lidar data for %s', lidarType{iLidar});
        continue;
    end

    lidarData.mTime = unix_timestamp_2_datenum(h5read(h5Filename, '/time'));
    lidarData.height = h5read(h5Filename, '/height');
    for iCh = 1:length(lidarConfig.chTag)
        if p.Results.flagDebug
            fprintf('Reading lidar data of %s-%s\n', lidarType{iLidar}, lidarConfig.chTag{iCh});
        end

        lidarData.(['sig', lidarConfig.chTag{iCh}]) = h5read(h5Filename, sprintf('/sig%s', lidarConfig.chTag{iCh}));
    end

    %% pre-process
    lidarData = lidarPreprocess(lidarData, lidarConfig.chTag, ...
        'deadtime', lidarConfig.deadTime, ...
        'bgBins', lidarConfig.bgBins, ...
        'nPretrigger', lidarConfig.nPretrigger, ...
        'bgCorFile', lidarConfig.bgCorFile, ...
        'lidarNo', lidarConfig.lidarNo, ...
        'flagDebug', p.Results.flagDebug, ...
        'tOffset', datenum(0, 1, 0, 0, lidarConfig.tOffset, 0), ...
        'hOffset', lidarConfig.hOffset, ...
        'overlapFile', lidarConfig.overlapFile);

    allData.(lidarType{iLidar}) = lidarData;
end

%% compose lidar signal
tRange = [datenum(config.externalChkCfg.RamanCmpCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(config.externalChkCfg.RamanCmpCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
cmpRaman = [];
cmpMie = [];
mTime = allData.(lidarType{1}).mTime;
height = allData.(lidarType{1}).height;
isChosen = (mTime >= tRange(1)) & (mTime <= tRange(2));

if ~ any(isChosen)
    warning('Wrong configuration for tRange. No profiles were chosen.');
    return;
end

% standard lidar
cmpRaman = cat(2, cmpRaman, allData.(lidarType{1}).(['rcs', config.externalChkCfg.RamanCmpCfg.RamanChTag{1}])(:, isChosen));
cmpMie = cat(2, cmpMie, allData.(lidarType{1}).(['rcs', config.externalChkCfg.RamanCmpCfg.MieChCompose{1}{1}]) + allData.(lidarType{1}).(['rcs', config.externalChkCfg.RamanCmpCfg.MieChCompose{1}{2}]) * externalChkCfg.RamanCmpCfg.MieChCompose{1}{3});
fprintf(fid, 'Time slot: %s\n', config.externalChkCfg.RamanCmpCfg.tRange);
fprintf(fid, 'Number of profiles for %s (standard): %d\n', lidarType{1}, sum(isChosen));

% other lidars
for iLidar = 2:length(lidarType)
    isChosen = (allData.(lidarType{iLidar}).mTime >= tRange(1)) & (allData.(lidarType{iLidar}).mTime <= tRange(2));

    thisRaman = allData.(lidarType{iLidar}).(['rcs', config.externalChkCfg.RamanCmpCfg.RamanChTag{iLidar}])(:, isChosen);
    thisMie = allData.(lidarType{iLidar}).(['rcs', config.externalChkCfg.RamanCmpCfg.MieChCompose{iLidar}{1}]) + allData.(lidarType{iLidar}).(['rcs', config.externalChkCfg.RamanCmpCfg.MieChCompose{iLidar}{2}]) * externalChkCfg.RamanCmpCfg.MieChCompose{iLidar}{3};

    %% signal interpolation
    thisHeight = allData.(lidarType{iLidar}).height;
    thisRamanInterp = interp1(thisHeight, thisRaman, height);
    thisMieInterp = interp1(thisHeight, thisMie, height);
    cmpRaman = cat(2, cmpRaman, thisRamanInterp);
    cmpMie = cat(2, cmpMie, thisMieInterp);

    fprintf(fid, 'Number of profiles for %s: %d\n', lidarType{iLidar}, sum(isChosen));
end

piecewiseSM = config.externalChkCfg.RamanCmpCfg.smoothwindow;
for iW = 1:size(piecewiseSM, 1)
    piecewiseSM(iW, 1) = find(height >= piecewiseSM(iW, 1), 1, 'first');
    piecewiseSM(iW, 2) = find(height <= piecewiseSM(iW, 2), 1, 'last');
    piecewiseSM(iW, 3) = round(piecewiseSM(iW, 3) / (height(2) - height(1)));
end

%% signal smoothing
cmpRaman = NaN(size(cmpRaman));
cmpMie = NaN(size(cmpMie));
for iLidar = 1:length(lidarType)
    cmpRaman(:, iLidar) = smoothWin(cmpRaman(:, iLidar), piecewiseSM, 'moving');
    cmpMie(:, iLidar) = smoothWin(cmpMie(:, iLidar), piecewiseSM, 'moving');
end

%% Raman retrieval
aBsc = NaN(size(cmpRaman));
aExt = NaN(size(cmpRaman));

% Rayleigh scattering
[temperature, pressure, ~, ~] = read_meteordata(mean(tRange), height + 0, ...
    'meteor_data', 'standard_atmosphere', ...
    'station', 'beijing');
[mBsc, mExt] = rayleigh_scattering(config.externalChkCfg.RamanCmpCfg.wavelengthMie, pressure, temperature + 273.14, 360, 80);

for iLidar = 1:length(lidarType)
    aExt(:, iLidar) = LidarRamanExt(height, cmpRaman(:, iLidar), cmpBg(iLidar), config.externalChkCfg.RamanCmpCfg.wavelengthMie, config.externalChkCfg.RamanCmpCfg.wavelengthRaman, 1, pressure, temperature + 273.14, 20, 360, 80, 'moving');
    aBsc(:, iLidar) = LidarRamanBsc(height, cmpMie(:, iLidar), cmpRaman(:, iLidar), aExt(:, iLidar), 1, mExt, mBsc, config.externalChkCfg.RamanCmpCfg.refRange, config.externalChkCfg.RamanCmpCfg.wavelengthMie, config.externalChkCfg.RamanCmpCfg.refValue, 5);
end

% relative deviation
aBscDev = NaN(size(aBsc));
aExtDev = NaN(size(aExt));
for iLidar = 2:size(aBsc, 2)
    aBscDev(:, iLidar) = (aBsc(:, iLidar) - aBsc(:, 1)) ./ aBsc(:, 1) * 100;
    aExtDev(:, iLidar) = (aExt(:, iLidar) - aExt(:, 1)) ./ aExt(:, 1) * 100;
end

% mean relative deviation
nES = size(config.externalChkCfg.RamanCmpCfg.hChkRange, 1);
meanABscDev = NaN(nES, length(lidarType));
stdABscDev = NaN(nES, length(lidarType));
meanAExtDev = NaN(nES, length(lidarType));
stdAExtDev = NaN(nES, length(lidarType));
aBscTmp = aBsc;
aExtTmp = aExt;
aBscTmp(aBscTmp <= config.externalChkCfg.RamanCmpCfg.minBsc) = NaN;
aExtTmp(aBscTmp <= config.externalChkCfg.RamanCmpCfg.minBsc) = NaN;
for iES = 1:nES
    isInES = (height >= config.externalChkCfg.RamanCmpCfg.hChkRange(iES, 1)) & (height <= config.externalChkCfg.RamanCmpCfg.hChkRange(iES, 2));

    meanABscDev(iES, :) = nanmean(abs(aBscTmp(isInES, :) - repmat(aBscTmp(isInES, 1), 1, length(lidarType))) ./ repmat(aBscTmp(isInES, 1), 1, length(lidarType)), 1) * 100;
    stdABscDev(iES, :) = nanstd(abs(aBscTmp(isInES, :) - repmat(aBscTmp(isInES, 1), 1, length(lidarType))) ./ repmat(aBscTmp(isInES, 1), 1, length(lidarType)), 0, 1) * 100;

    meanAExtDev(iES, :) = nanmean(abs(aExtTmp(isInES, :) - repmat(aExtTmp(isInES, 1), 1, length(lidarType))) ./ repmat(aExtTmp(isInES, 1), 1, length(lidarType)), 1) * 100;
    stdAExtDev(iES, :) = nanstd(abs(aExtTmp(isInES, :) - repmat(aExtTmp(isInES, 1), 1, length(lidarType))) ./ repmat(aExtTmp(isInES, 1), 1, length(lidarType)), 0, 1) * 100;

    for iLidar = 2:length(lidarType)
        fprintf(fid, 'Mean relative deviations of %s Backscatter: %6.2f%% (max: %6.2f%%)\n', lidarType{iLidar}, meanABscDev(iES, iLidar), config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 1));
        fprintf(fid, 'Mean relative deviations of %s Extinction: %6.2f%% (max: %6.2f%%)\n', lidarType{iLidar}, meanAExtDev(iES, iLidar), config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 1));
        fprintf(fid, 'Standard relative deviations of %s Backscatter: %6.2f%% (max: %6.2f%%)\n', lidarType{iLidar}, stdABscDev(iES, iLidar), config.externalChkCfg.RamanCmpCfg.maxDev(iES, 2));
        fprintf(fid, 'Standard relative deviations of %s Extinction: %6.2f%% (max: %6.2f%%)\n', lidarType{iLidar}, stdAExtDev(iES, iLidar), config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 2));
    end
end

%% data visualization

% backscatter
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances = [];
lineInstances(1) = plot(aBsc(:, 1), height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{1}); hold on;
for iLidar = 2:length(lidarType)
    p1 = plot(aBsc(:, iLidar), height, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances = cat(1, lineInstances, p1);
end
plot([0, 0], [-100000, 100000], '-.k');

% fit range
plot(config.externalChkCfg.RamanCmpCfg.bscRange, [1, 1] * config.externalChkCfg.RamanCmpCfg.refRange(1), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);
plot(config.externalChkCfg.RamanCmpCfg.bscRange, [1, 1] * config.externalChkCfg.RamanCmpCfg.refRange(2), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);

xlabel('Bsc. coeff. (m^{-1}*sr^{-1})');
ylabel('Height (m)');
title('Aerosol backscatter comparison');

xlim(config.externalChkCfg.RamanCmpCfg.bscRange);
ylim(config.externalChkCfg.RamanCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.2, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Raman_backscatter_comparison.%s', config.figFormat)), '-r300');
end

% extinction
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances = [];
lineInstances(1) = plot(aExt(:, 1), height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{1}); hold on;
for iLidar = 2:length(lidarType)
    p1 = plot(aExt(:, iLidar), height, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances = cat(1, lineInstances, p1);
end
plot([0, 0], [-100000, 100000], '-.k');

% fit range
plot(config.externalChkCfg.RamanCmpCfg.extRange, [1, 1] * config.externalChkCfg.RamanCmpCfg.refRange(1), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);
plot(config.externalChkCfg.RamanCmpCfg.extRange, [1, 1] * config.externalChkCfg.RamanCmpCfg.refRange(2), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);

xlabel('Ext. coeff. (m^{-1})');
ylabel('Height (m)');
title('Aerosol extinction comparison');

xlim(config.externalChkCfg.RamanCmpCfg.extRange);
ylim(config.externalChkCfg.RamanCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.2, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Raman_extinction_comparison.%s', config.figFormat)), '-r300');
end

% relative deviation (backscatter)
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances0 = [];
for iLidar = 2:length(lidarType)
    p1 = plot(aBscDev(:, iLidar), height, 'LineStyle', '-', 'Color', lineInstances(iLidar).Color, 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances0 = cat(1, lineInstances0, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances0 = cat(1, lineInstances0, p3);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1), config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances0 = cat(1, lineInstances0, p4);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2), config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Relative Dev. (%)');
ylabel('Height (m)');
title('Raman Backscatter comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.RamanCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances0, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Raman_Backscatter_deviation.%s', config.figFormat)), '-r300');
end

% mean relative deviation (backscatter)
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances1 = [];
for iLidar = 2:length(lidarType)
    p1 = scatter(meanABscDev(:, iLidar), mean(config.externalChkCfg.RamanCmpCfg.hChkRange, 2), 25, 'Marker', 's', 'MarkerFaceColor', lineInstances(iLidar).Color, 'MarkerEdgeColor', lineInstances(iLidar).Color, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances1 = cat(1, lineInstances1, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances1 = cat(1, lineInstances1, p3);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1), config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 1)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevBsc(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances1 = cat(1, lineInstances1, p4);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2), config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevBsc(iPatch, 2)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Mean Rel. Dev. (%)');
ylabel('Height (m)');
title('Raman Backscatter comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.RamanCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances1, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Raman_Backscatter_mean_deviation.%s', config.figFormat)), '-r300');
end

% relative deviation (extinction)
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances0 = [];
for iLidar = 2:length(lidarType)
    p1 = plot(aExtDev(:, iLidar), height, 'LineStyle', '-', 'Color', lineInstances(iLidar).Color, 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances0 = cat(1, lineInstances0, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances0 = cat(1, lineInstances0, p3);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1), config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances0 = cat(1, lineInstances0, p4);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2), config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Relative Dev. (%)');
ylabel('Height (m)');
title('Raman Extinction comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.RamanCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances0, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Raman_Extinction_deviation.%s', config.figFormat)), '-r300');
end

% mean relative deviation (extinction)
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances1 = [];
for iLidar = 2:length(lidarType)
    p1 = scatter(meanABscDev(:, iLidar), mean(config.externalChkCfg.RamanCmpCfg.hChkRange, 2), 25, 'Marker', 's', 'MarkerFaceColor', lineInstances(iLidar).Color, 'MarkerEdgeColor', lineInstances(iLidar).Color, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances1 = cat(1, lineInstances1, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances1 = cat(1, lineInstances1, p3);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1), config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 1)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.RamanCmpCfg.maxDevExt(iES, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances1 = cat(1, lineInstances1, p4);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2), config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2), -config.externalChkCfg.RamanCmpCfg.maxDevExt(iPatch, 2)], ...
        [config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.RamanCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Mean Rel. Dev. (%)');
ylabel('Height (m)');
title('Raman Extinction comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.RamanCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances1, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Raman_Extinction_mean_deviation.%s', config.figFormat)), '-r300');
end

if strcmpi(config.externalChkCfg.figVisible, 'off')
    close all;
end

fclose(fid);

end