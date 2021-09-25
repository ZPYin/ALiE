function VDRCmp(config, reportFile, varargin)
% VDRCMP volume depolarization ratio comparison.
% USAGE:
%    VDRCmp(config, reportFile)
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

lidarType = config.externalChkCfg.VDRCmpCfg.LidarList;

%% report file
fid = fopen(reportFile, 'a');
fprintf(fid, '\n## VDR comparison\n');

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
tRange = [datenum(config.externalChkCfg.VDRCmpCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(config.externalChkCfg.VDRCmpCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
pSig = [];
sSig = [];
cmpVDR = [];
mTime = allData.(lidarType{1}).mTime;
height = allData.(lidarType{1}).height;
isChosen = (mTime >= tRange(1)) & (mTime <= tRange(2));

if ~ any(isChosen)
    warning('Wrong configuration for tRange. No profiles were chosen.');
    return;
end

% standard lidar
pSig = cat(2, pSig, nanmean(allData.(lidarType{1}).(['rcs', config.externalChkCfg.VDRCmpCfg.vdrCompose{1}{1}])(:, isChosen), 2));
sSig = cat(2, sSig, nanmean(allData.(lidarType{1}).(['rcs', config.externalChkCfg.VDRCmpCfg.vdrCompose{1}{2}])(:, isChosen), 2));
cmpVDR = cat(2, cmpVDR, sSig(:, 1) ./ pSig(:, 1) .* config.externalChkCfg.VDRCmpCfg.vdrCompose{1}{3} + config.externalChkCfg.VDRCmpCfg.vdrCompose{1}{4});
fprintf(fid, 'Time slot: %s\n', config.externalChkCfg.VDRCmpCfg.tRange);
fprintf(fid, 'Number of profiles for %s (standard): %d\n', lidarType{1}, sum(isChosen));

% other lidars
for iLidar = 2:length(lidarType)
    isChosen = (allData.(lidarType{iLidar}).mTime >= tRange(1)) & (allData.(lidarType{iLidar}).mTime <= tRange(2));

    thisPSig = nanmean(allData.(lidarType{iLidar}).(['rcs', config.externalChkCfg.VDRCmpCfg.vdrCompose{iLidar}{1}])(:, isChosen), 2);
    thisSSig = nanmean(allData.(lidarType{iLidar}).(['rcs', config.externalChkCfg.VDRCmpCfg.vdrCompose{iLidar}{2}])(:, isChosen), 2);
    thisCmpVDR = sSig(:, iCh) ./ pSig(:, iCh) .* config.externalChkCfg.VDRCmpCfg.vdrCompose{iLidar}{3} + config.externalChkCfg.VDRCmpCfg.vdrCompose{iLidar}{4};

    %% signal interpolation
    thisHeight = allData.(lidarType{iLidar}).height;
    thisPSigInterp = interp1(thisHeight, thisPSig, height);
    thisSSigInterp = interp1(thisHeight, thisSSig, height);
    thisCmpVDRInterp = interp1(thisHeight, thisCmpVDR, height);
    pSig = cat(2, pSig, thisPSigInterp);
    sSig = cat(2, sSig, thisSSigInterp);
    cmpVDR = cat(2, cmpVDR, thisCmpVDRInterp);

    fprintf(fid, 'Number of profiles for %s: %d\n', lidarType{iLidar}, sum(isChosen));
end

piecewiseSM = config.externalChkCfg.VDRCmpCfg.smoothwindow;
for iW = 1:size(piecewiseSM, 1)
    piecewiseSM(iW, 1) = find(height >= piecewiseSM(iW, 1), 1, 'first');
    piecewiseSM(iW, 2) = find(height <= piecewiseSM(iW, 2), 1, 'last');
    piecewiseSM(iW, 3) = round(piecewiseSM(iW, 3) / (height(2) - height(1)));
end

%% signal smoothing
pSigSm = NaN(size(pSig));
sSigSm = NaN(size(sSig));
cmpVDRSm = NaN(size(cmpVDR));
for iLidar = 1:length(lidarType)
    pSigSm(:, iLidar) = smoothWin(pSigSm(:, iLidar), piecewiseSM, 'moving');
    sSigSm(:, iLidar) = smoothWin(sSigSm(:, iLidar), piecewiseSM, 'moving');

    cmpVDRSm(:, iLidar) = pSigSm(:, iLidar) ./ sSigSm(:, iLidar) .* config.externalChkCfg.VDRCmpCfg.vdrCompose{iLidar}{3} + config.externalChkCfg.VDRCmpCfg.vdrCompose{iLidar}{4};
end

%% signal evaluation

% relative deviation
VDRDev = NaN(size(cmpVDRSm));
for iLidar = 2:size(cmpVDRSm, 2)
    VDRDev(:, iLidar) = (cmpVDRSm(:, iLidar) - cmpVDRSm(:, 1)) ./ cmpVDRSm(:, 1) * 100;
end

% mean relative deviation
nES = size(config.externalChkCfg.VDRCmpCfg.hChkRange, 1);
meanVDRDev = NaN(nES, length(lidarType));
stdVDRDev = NaN(nES, length(lidarType));
for iES = 1:nES
    isInES = (height >= config.externalChkCfg.VDRCmpCfg.hChkRange(iES, 1)) & (height <= config.externalChkCfg.VDRCmpCfg.hChkRange(iES, 2));

    meanVDRDev(iES, :) = nanmean(abs(cmpVDRSm(isInES, :) - repmat(cmpVDRSm(isInES, 1), 1, length(lidarType))) ./ repmat(cmpVDRSm(isInES, 1), 1, length(lidarType)), 1) * 100;
    stdVDRDev(iES, :) = nanstd(abs(cmpVDRSm(isInES, :) - repmat(cmpVDRSm(isInES, 1), 1, length(lidarType))) ./ repmat(cmpVDRSm(isInES, 1), 1, length(lidarType)), 0, 1) * 100;

    for iLidar = 2:length(lidarType)
        fprintf(fid, 'Mean relative deviations of %s: %6.2f%% (max: %6.2f%%)\n', lidarType{iLidar}, meanVDRDev(iES, iLidar), config.externalChkCfg.VDRCmpCfg.maxDev(iES, 1));
        fprintf(fid, 'Mean relative deviations of %s: %6.2f%% (max: %6.2f%%)\n', lidarType{iLidar}, stdVDRDev(iES, iLidar), config.externalChkCfg.VDRCmpCfg.maxDev(iES, 1));
    end
end

%% data visualization

% signal
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances = [];
lineInstances(1) = plot(cmpVDRSm(:, 1), height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{1}); hold on;
for iLidar = 2:length(lidarType)
    p1 = plot(cmpVDRSm(:, iLidar), height, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances = cat(1, lineInstances, p1);
end

xlabel('Vol. depol.');
ylabel('Height (m)');
title('VDR comparison');

xlim(config.externalChkCfg.VDRCmpCfg.vdrRange);
ylim(config.externalChkCfg.VDRCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('vdr_comparison.%s', config.figFormat)), '-r300');
end

% relative deviation
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances0 = [];
for iLidar = 2:length(lidarType)
    p1 = plot(VDRDev(:, iLidar), height, 'LineStyle', '-', 'Color', lineInstances(iLidar).Color, 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances0 = cat(1, lineInstances0, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances0 = cat(1, lineInstances0, p3);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1), config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1)], ...
        [config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances0 = cat(1, lineInstances0, p4);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2), config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2)], ...
        [config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Relative Dev. (%)');
ylabel('Height (m)');
title('VDR comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.VDRCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances0, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('signal_deviation.%s', config.figFormat)), '-r300');
end

% mean relative deviation
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances1 = [];
for iLidar = 2:length(lidarType)
    p1 = scatter(meanVDRDev(:, iLidar), mean(config.externalChkCfg.VDRCmpCfg.hChkRange, 2), 25, 'Marker', 's', 'MarkerFaceColor', lineInstances(iLidar).Color, 'MarkerEdgeColor', lineInstances(iLidar).Color, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances1 = cat(1, lineInstances1, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '--', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances1 = cat(1, lineInstances1, p3);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1), config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 1)], ...
        [config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2, 'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.VDRCmpCfg.maxDev(iES, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iES, :), '-.', 'Color', [160, 160, 160]/255, 'LineWidth', 2);
    lineInstances1 = cat(1, lineInstances1, p4);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2), config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2), -config.externalChkCfg.VDRCmpCfg.maxDev(iPatch, 2)], ...
        [config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 2), config.externalChkCfg.VDRCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Mean Rel. Dev. (%)');
ylabel('Height (m)');
title('VDR comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.VDRCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances1, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('VDR_mean_deviation.%s', config.figFormat)), '-r300');
end

if strcmpi(config.externalChkCfg.figVisible, 'off')
    close all;
end

fclose(fid);

end