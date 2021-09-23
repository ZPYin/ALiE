function RCSCmp(config, reportFile, varargin)
% RCSCmp description
% USAGE:
%    [output] = RCSCmp(params)
% INPUTS:
%    params
% OUTPUTS:
%    output
% EXAMPLE:
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

lidarType = config.externalChkCfg.RCSCmpCfg.LidarList;

%% report file
fid = fopen(reportFile, 'a');
fprintf(fid, '\n## RCS comparison\n');

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
tRange = [datenum(config.externalChkCfg.RCSCmpCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(config.externalChkCfg.RCSCmpCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
cmpSig = [];
mTime = allData.(lidarType{1}).mTime;
height = allData.(lidarType{1}).height;
isChosen = (mTime >= tRange(1)) & (mTime <= tRange(2));

if ~ any(isChosen)
    warning('Wrong configuration for tRange. No profiles were chosen.');
    return;
end

% standard lidar
rcs = [];
for iCh = 1:length(config.externalChkCfg.(lidarType{1}).chTag)
    rcs = cat(2, rcs, nansum(allData.(lidarType{1}).(['rcs', config.externalChkCfg.(lidarType{1}).chTag{iCh}])(:, isChosen), 2));
end
cmpSig = cat(2, cmpSig, rcs * transpose(config.externalChkCfg.RCSCmpCfg.sigCompose(1, :)));
fprintf(fid, 'Time slot: %s\n', config.externalChkCfg.RCSCmpCfg.tRange);
fprintf(fid, 'Number of profiles for %s (standard): %d\n', lidarType{1}, sum(isChosen));

% other lidars
for iLidar = 2:length(lidarType)
    rcs = [];
    isChosen = (allData.(lidarType{iLidar}).mTime >= tRange(1)) & (allData.(lidarType{iLidar}).mTime <= tRange(2));

    for iCh = 1:length(config.externalChkCfg.(lidarType{iLidar}).chTag)
        rcs = cat(2, rcs, nansum(allData.(lidarType{iLidar}).(['rcs', config.externalChkCfg.(lidarType{iLidar}).chTag{iCh}])(:, isChosen), 2));
    end

    %% signal interpolation
    thisHeight = allData.(lidarType{iLidar}).height;
    thisCmpSig = rcs * transpose(config.externalChkCfg.RCSCmpCfg.sigCompose(iLidar, :));
    thisCmpSigInterp = interp1(thisHeight, thisCmpSig, height);
    cmpSig = cat(2, cmpSig, thisCmpSigInterp);

    fprintf(fid, 'Number of profiles for %s: %d\n', lidarType{iLidar}, sum(isChosen));
end

%% signal normalization
cmpSigNorm = cmpSig;
isNormRange = (height >= config.externalChkCfg.RCSCmpCfg.normRange(1)) & (height <= config.externalChkCfg.RCSCmpCfg.normRange(2));
if ~ any(isNormRange)
    errStruct.message = sprintf('Wrong configuration for normRange.');
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end
for iLidar = 2:length(lidarType)
    normRatio = nanmean(cmpSig(isNormRange, 1), 1) ./ nanmean(cmpSig(isNormRange, iLidar), 1);
    cmpSigNorm(:, iLidar) = cmpSig(:, iLidar) * normRatio;
end

%% signal smoothing


%% data visualization

% signal
figure('Position', [0, 10, 550, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances = [];
lineInstances(1) = plot(height, cmpSigNorm(:, 1), 'Color', 'k', 'Marker', 's', 'MarkerFaceColor', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{1}); hold on;
for iLidar = 2:length(lidarType)
    p1 = plot(height, cmpSigNorm(:, iLidar), 'Marker', 'o', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', lidarType{iLidar}); hold on;
    lineInstances = cat(1, lineInstances, p1);
end

% fit range
plot(config.externalChkCfg.RCSCmpCfg.sigRange, [1, 1] * config.externalChkCfg.RCSCmpCfg.fitRange(1), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);
plot(config.externalChkCfg.RCSCmpCfg.sigRange, [1, 1] * config.externalChkCfg.RCSCmpCfg.fitRange(2), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);

ylabel('Backscatter (a.u.)');
xlabel('Height (m)');
title('Range comparison');

ylim(config.externalChkCfg.RCSCmpCfg.sigRange);
xlim(config.externalChkCfg.RCSCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.1, -0.14, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('range_comparison.%s', config.figFormat)), '-r300');
end

% auto-correlation
figure('Position', [0, 10, 550, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', config.externalChkCfg.figVisible);

lineInstances1 = [];
for iLidar = 2:length(lidarType)
    p1 = plot(hLag, corrVal(:, iLidar), 'Marker', 'o', 'LineStyle', '-', 'Color', lineInstances(iLidar).Color, 'LineWidth', 2, 'DisplayName', sprintf('%s: %4.1f m', lidarType{iLidar}, hMaxLag(iLidar))); hold on;
    lineInstances1 = cat(1, lineInstances1, p1);

    plot([hMaxLag(iLidar), hMaxLag(iLidar)], [0, maxCorr(iLidar)], 'LineStyle', '--', 'Color', p1.Color, 'LineWidth', 2);
end

ylabel('Correlation Coeff. (a.u.)');
xlabel('Range lag (m)');
title('Range comparison');

% ylim(config.externalChkCfg.RCSCmpCfg.sigRange);
xlim([min(hLag), max(hLag)]);
set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

lgHandle = legend(lineInstances1, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.1, -0.14, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

if exist(config.evaluationReportPath, 'dir')
    export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('range_comparison_correlation.%s', config.figFormat)), '-r300');
end

if strcmpi(config.externalChkCfg.figVisible, 'off')
    close all;
end

fclose(fid);

end