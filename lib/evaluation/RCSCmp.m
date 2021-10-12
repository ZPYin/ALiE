function RCSCmp(config, reportFile, varargin)
% RCSCMP range corrected signal comparison.
% USAGE:
%    RCSCmp(config, reportFile)
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
    rcs = cat(2, rcs, nanmean(allData.(lidarType{1}).(['rcs', config.externalChkCfg.(lidarType{1}).chTag{iCh}])(:, isChosen), 2));
end
if iscell(config.externalChkCfg.RCSCmpCfg.sigCompose)
    sigCompose = transpose(config.externalChkCfg.RCSCmpCfg.sigCompose{1});
else
    sigCompose = transpose(config.externalChkCfg.RCSCmpCfg.sigCompose(1, :));
end

if size(rcs, 2) ~= length(sigCompose)
    errStruct.message = 'Wrong configuration for sigCompose. Incompatible size with channel number';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

cmpSig = cat(2, cmpSig, rcs * sigCompose);
fprintf(fid, 'Time slot: %s\n', config.externalChkCfg.RCSCmpCfg.tRange);
fprintf(fid, 'Number of profiles for %s (standard): %d\n', lidarType{1}, sum(isChosen));

% other lidars
for iLidar = 2:length(lidarType)
    isChosen = (allData.(lidarType{iLidar}).mTime >= tRange(1)) & ...
               (allData.(lidarType{iLidar}).mTime <= tRange(2));

    thisHeight = allData.(lidarType{iLidar}).height;
    rcs = [];
    thisLidar = lidarType{iLidar};

    if ~ any(isChosen)
        % no profile selected
        warning('No profiles were chosen for %s', lidarType{iLidar});
        rcs = NaN(length(allData.(thisLidar).height), length(config.externalChkCfg.(thisLidar).chTag));
    else
        for iCh = 1:length(config.externalChkCfg.(lidarType{iLidar}).chTag)
            sig = nanmean(allData.(lidarType{iLidar}).(['sig', config.externalChkCfg.(lidarType{iLidar}).chTag{iCh}])(:, isChosen), 2);
            rcs = cat(2, rcs, sig .* thisHeight.^2);
        end
    end

    %% signal interpolation
    if iscell(config.externalChkCfg.RCSCmpCfg.sigCompose)
        sigCompose = transpose(config.externalChkCfg.RCSCmpCfg.sigCompose{iLidar});
    else
        sigCompose = transpose(config.externalChkCfg.RCSCmpCfg.sigCompose(iLidar, :));
    end

    if size(rcs, 2) ~= length(sigCompose)
        errStruct.message = 'Wrong configuration for sigCompose. Incompatible size with channel number';
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end

    thisCmpSig = rcs * sigCompose;
    thisCmpSigInterp = interp1(thisHeight, thisCmpSig, height);
    cmpSig = cat(2, cmpSig, thisCmpSigInterp);

    fprintf(fid, 'Number of profiles for %s: %d\n', lidarType{iLidar}, sum(isChosen));
end

%% signal normalization
cmpSigNorm = cmpSig;
isNormRange = (height >= config.externalChkCfg.RCSCmpCfg.normRange(1)) & ...
              (height <= config.externalChkCfg.RCSCmpCfg.normRange(2));
if ~ any(isNormRange)
    errStruct.message = sprintf('Wrong configuration for normRange.');
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end
for iLidar = 2:length(lidarType)
    normRatio = nanmean(cmpSig(isNormRange, 1), 1) ./ ...
                nanmean(cmpSig(isNormRange, iLidar), 1);
    cmpSigNorm(:, iLidar) = cmpSig(:, iLidar) * normRatio;
end

piecewiseSM = config.externalChkCfg.RCSCmpCfg.smoothwindow;
for iW = 1:size(piecewiseSM, 1)
    piecewiseSM(iW, 1) = find(height >= piecewiseSM(iW, 1), 1, 'first');
    piecewiseSM(iW, 2) = find(height <= piecewiseSM(iW, 2), 1, 'last');
    piecewiseSM(iW, 3) = round(piecewiseSM(iW, 3) / (height(2) - height(1)));
end

%% signal smoothing
cmpSigSm = NaN(size(cmpSigNorm));
for iLidar = 1:length(lidarType)
    cmpSigSm(:, iLidar) = smoothWin(cmpSigNorm(:, iLidar), piecewiseSM, 'moving');
end

%% signal evaluation

% relative deviation
sigDev = NaN(size(cmpSigSm));
for iLidar = 2:size(cmpSigSm, 2)
    sigDev(:, iLidar) = (cmpSigSm(:, iLidar) - cmpSigSm(:, 1)) ./ ...
                        cmpSigSm(:, 1) * 100;
end

% mean relative deviation
nES = size(config.externalChkCfg.RCSCmpCfg.hChkRange, 1);
meanSigDev = NaN(nES, length(lidarType));
for iES = 1:nES
    isInES = (height >= config.externalChkCfg.RCSCmpCfg.hChkRange(iES, 1)) & ...
             (height <= config.externalChkCfg.RCSCmpCfg.hChkRange(iES, 2));

    meanSigDev(iES, :) = nanmean(abs(sigDev(isInES, :)), 1);

    for iLidar = 2:length(lidarType)
        fprintf(fid, 'Mean relative deviations of %s between %f - %f: %6.2f%% (max: %6.2f%%)\n', ...
            lidarType{iLidar}, ...
            config.externalChkCfg.RCSCmpCfg.hChkRange(iES, 1), ...
            config.externalChkCfg.RCSCmpCfg.hChkRange(iES, 2), ...
            meanSigDev(iES, iLidar), ...
            config.externalChkCfg.RCSCmpCfg.maxDev(iES));
    end
end

%% data visualization

% signal
figure('Position', [0, 10, 300, 400], ...
       'Units', 'Pixels', ...
       'Color', 'w', ...
       'Visible', config.externalChkCfg.figVisible);

cmpSigSmTmp = cmpSigSm;
cmpSigSmTmp(cmpSigSmTmp <= 0) = NaN;
lineInstances = [];
for iLidar = 2:length(lidarType)
    p1 = semilogx(cmpSigSmTmp(:, iLidar), height, ...
        'LineStyle', '-', ...
        'LineWidth', 2, ...
        'DisplayName', lidarType{iLidar});
    hold on;
    lineInstances = cat(1, lineInstances, p1);
end
p1 = semilogx(cmpSigSmTmp(:, 1), height, ...
    'Color', 'k', ...
    'LineStyle', '-', ...
    'LineWidth', 1, ...
    'DisplayName', lidarType{1});
hold on;
lineInstances = [p1; lineInstances];

% fit range
plot(config.externalChkCfg.RCSCmpCfg.sigRange, ...
    [1, 1] * config.externalChkCfg.RCSCmpCfg.normRange(1), '--', ...
    'Color', [152, 78, 163]/255, ...
    'LineWidth', 2);
plot(config.externalChkCfg.RCSCmpCfg.sigRange, ...
    [1, 1] * config.externalChkCfg.RCSCmpCfg.normRange(2), '--', ...
    'Color', [152, 78, 163]/255, ...
    'LineWidth', 2);

xlabel('Backscatter (a.u.)');
ylabel('Height (m)');
title('Lidar signal comparison');

xlim(config.externalChkCfg.RCSCmpCfg.sigRange);
ylim(config.externalChkCfg.RCSCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.23, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('signal_comparison.%s', config.figFormat)), '-r300');
end

% relative deviation
figure('Position', [0, 10, 300, 400], ...
       'Units', 'Pixels', ...
       'Color', 'w', ...
       'Visible', config.externalChkCfg.figVisible);

lineInstances0 = [];
for iLidar = 2:length(lidarType)
    p1 = plot(sigDev(:, iLidar), height, ...
        'LineStyle', '-', ...
        'Color', lineInstances(iLidar).Color, ...
        'LineWidth', 2, ...
        'DisplayName', lidarType{iLidar});
    hold on;
    lineInstances0 = cat(1, lineInstances0, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound
for iES = 1:nES
    plot([-1, -1] * config.externalChkCfg.RCSCmpCfg.maxDev(iES), ...
        config.externalChkCfg.RCSCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);
    plot([1, 1] * config.externalChkCfg.RCSCmpCfg.maxDev(iES), ...
        config.externalChkCfg.RCSCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RCSCmpCfg.maxDev(iPatch), ...
         config.externalChkCfg.RCSCmpCfg.maxDev(iPatch), ...
         -config.externalChkCfg.RCSCmpCfg.maxDev(iPatch), ...
         -config.externalChkCfg.RCSCmpCfg.maxDev(iPatch)], ...
        [config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 1), ...
         config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Relative Dev. (%)');
ylabel('Height (m)');
title('Lidar signal comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.RCSCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'LineWidth', 2);

lgHandle = legend(lineInstances0, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.23, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('signal_deviation.%s', config.figFormat)), '-r300');
end

% mean relative deviation
figure('Position', [0, 10, 300, 400], ...
       'Units', 'Pixels', ...
       'Color', 'w', ...
       'Visible', config.externalChkCfg.figVisible);

lineInstances1 = [];
for iLidar = 2:length(lidarType)
    p1 = scatter(meanSigDev(:, iLidar), ...
        mean(config.externalChkCfg.RCSCmpCfg.hChkRange, 2), 25, ...
        'Marker', 's', ...
        'MarkerFaceColor', lineInstances(iLidar).Color, ...
        'MarkerEdgeColor', lineInstances(iLidar).Color, ...
        'DisplayName', lidarType{iLidar});
    hold on;
    lineInstances1 = cat(1, lineInstances1, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound
for iES = 1:nES
    plot([-1, -1] * config.externalChkCfg.RCSCmpCfg.maxDev(iES), ...
        config.externalChkCfg.RCSCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);
    plot([1, 1] * config.externalChkCfg.RCSCmpCfg.maxDev(iES), ...
        config.externalChkCfg.RCSCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.RCSCmpCfg.maxDev(iPatch), ...
         config.externalChkCfg.RCSCmpCfg.maxDev(iPatch), ...
         -config.externalChkCfg.RCSCmpCfg.maxDev(iPatch), ...
         -config.externalChkCfg.RCSCmpCfg.maxDev(iPatch)], ...
        [config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 1), ...
         config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.RCSCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Mean Rel. Dev. (%)');
ylabel('Height (m)');
title('Lidar signal comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.RCSCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'LineWidth', 2);

lgHandle = legend(lineInstances1, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.23, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('signal_mean_deviation.%s', config.figFormat)), '-r300');
end

if strcmpi(config.externalChkCfg.figVisible, 'off')
    close all;
end

fclose(fid);

end