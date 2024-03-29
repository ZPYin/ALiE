function FernaldCmp(config, reportFile, varargin)
% FERNALDCMP Fernald retrieval results comparison (external check)
%
% USAGE:
%    FernaldCmp(config, reportFile)
%
% INPUTS:
%    config: struct
%    reportFile: char
%
% KEYWORDS:
%    flagDebug: logical
%
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

lidarType = config.externalChkCfg.FernaldCmpCfg.LidarList;

%% report file
fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Fernald comparison\n');

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
            fprintf('Reading lidar data of %s-%s\n', ...
                lidarType{iLidar}, lidarConfig.chTag{iCh});
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
tRange = [datenum(config.externalChkCfg.FernaldCmpCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
          datenum(config.externalChkCfg.FernaldCmpCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
cmpSig = [];
cmpBg = [];
mTime = allData.(lidarType{1}).mTime;
height = allData.(lidarType{1}).height;
isChosen = (mTime >= tRange(1)) & (mTime <= tRange(2));

if ~ any(isChosen)
    warning('Wrong configuration for tRange. No profiles were chosen.');
    return;
end

% standard lidar
sig = [];
bg = [];
for iCh = 1:length(config.externalChkCfg.(lidarType{1}).chTag)
    sig = cat(2, sig, nanmean(allData.(lidarType{1}).(['sig', config.externalChkCfg.(lidarType{1}).chTag{iCh}])(:, isChosen), 2));
    bg = cat(2, bg,  nanmean(allData.(lidarType{1}).(['bg', config.externalChkCfg.(lidarType{1}).chTag{iCh}])(isChosen)));
end

if iscell(config.externalChkCfg.FernaldCmpCfg.sigCompose)
    sigCompose = transpose(config.externalChkCfg.FernaldCmpCfg.sigCompose{1});
else
    sigCompose = transpose(config.externalChkCfg.FernaldCmpCfg.sigCompose(1, :));
end

cmpSig = cat(2, cmpSig, sig * sigCompose);
cmpBg = cat(2, cmpBg, bg * sigCompose);
fprintf(fid, 'Time slot: %s\n', config.externalChkCfg.FernaldCmpCfg.tRange);
fprintf(fid, 'Number of profiles for %s (standard): %d\n', lidarType{1}, sum(isChosen));

% other lidars
for iLidar = 2:length(lidarType)
    sig = [];
    bg = [];
    thisLidar = lidarType{iLidar};
    isChosen = (allData.(thisLidar).mTime >= tRange(1)) & (allData.(thisLidar).mTime <= tRange(2));

    if ~ any(isChosen)
        % no profile selected
        warning('No profiles were chosen for %s', lidarType{iLidar});
        sig = NaN(length(allData.(thisLidar).height), length(config.externalChkCfg.(thisLidar).chTag));
        bg = NaN(1, length(lidarType));
    else
        for iCh = 1:length(config.externalChkCfg.(thisLidar).chTag)
            sig = cat(2, sig, nanmean(allData.(thisLidar).(['sig', config.externalChkCfg.(thisLidar).chTag{iCh}])(:, isChosen), 2));
            bg = cat(2, bg, nanmean(allData.(thisLidar).(['bg', config.externalChkCfg.(thisLidar).chTag{iCh}])(isChosen)));
        end
    end

    %% signal interpolation
    if iscell(config.externalChkCfg.FernaldCmpCfg.sigCompose)
        sigCompose = transpose(config.externalChkCfg.FernaldCmpCfg.sigCompose{iLidar});
    else
        sigCompose = transpose(config.externalChkCfg.FernaldCmpCfg.sigCompose(iLidar, :));
    end

    if size(sig, 2) ~= length(sigCompose)
        errStruct.message = 'Wrong configuration for sigCompose. Incompatible size with channel number';
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end

    thisHeight = allData.(thisLidar).height;
    thisCmpSig = sig * sigCompose;
    thisCmpSigInterp = interp1(thisHeight, thisCmpSig, height);
    cmpSig = cat(2, cmpSig, thisCmpSigInterp);
    cmpBg = cat(2, cmpBg, bg);

    fprintf(fid, 'Number of profiles for %s: %d\n', thisLidar, sum(isChosen));
end

piecewiseSM = config.externalChkCfg.FernaldCmpCfg.smoothwindow;
for iW = 1:size(piecewiseSM, 1)
    piecewiseSM(iW, 1) = find(height >= piecewiseSM(iW, 1), 1, 'first');
    piecewiseSM(iW, 2) = find(height <= piecewiseSM(iW, 2), 1, 'last');
    piecewiseSM(iW, 3) = round(piecewiseSM(iW, 3) / (height(2) - height(1)));
end

%% signal smoothing
cmpSigSm = NaN(size(cmpSig));
for iLidar = 1:length(lidarType)
    cmpSigSm(:, iLidar) = smoothWin(cmpSig(:, iLidar), piecewiseSM, 'moving');
end

%% Fernald retrieval
aBsc = NaN(size(cmpSigSm));
aExt = NaN(size(cmpSigSm));

% Rayleigh scattering
[temperature, pressure, ~, ~] = read_meteordata(mean(tRange), height + 0, ...
    'meteor_data', 'standard_atmosphere', ...
    'station', 'beijing');
[mBsc, ~] = rayleigh_scattering(config.externalChkCfg.FernaldCmpCfg.wavelength, ...
    pressure, temperature + 273.14, 360, 80);

for iLidar = 1:length(lidarType)
    aBsc(:, iLidar) = CMAFernald(height, cmpSigSm(:, iLidar), ...
        cmpBg(iLidar), config.externalChkCfg.FernaldCmpCfg.lidarRatio, ...
        config.externalChkCfg.FernaldCmpCfg.refRange, ...
        config.externalChkCfg.FernaldCmpCfg.refValue, mBsc);
    aExt(:, iLidar) = config.externalChkCfg.FernaldCmpCfg.lidarRatio .* aBsc(:, iLidar);
end

% relative deviation
aBscDev = NaN(size(aBsc));
for iLidar = 2:size(aBsc, 2)
    aBscDev(:, iLidar) = (aBsc(:, iLidar) - aBsc(:, 1)) ./ aBsc(:, 1) * 100;
end

% mean relative deviation
nES = size(config.externalChkCfg.FernaldCmpCfg.hChkRange, 1);
meanABscDev = NaN(nES, length(lidarType));
stdABscDev = NaN(nES, length(lidarType));
aBscTmp = aBsc;
aBscTmp(aBscTmp <= config.externalChkCfg.FernaldCmpCfg.minBsc) = NaN;
for iES = 1:nES
    isInES = (height >= config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, 1)) & ...
             (height <= config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, 2));

    meanABscDev(iES, :) = nanmean(abs(aBscTmp(isInES, :) - repmat(aBscTmp(isInES, 1), 1, length(lidarType))) ./ ...
        repmat(aBscTmp(isInES, 1), 1, length(lidarType)), 1) * 100;
    stdABscDev(iES, :) = nanstd(abs(aBscTmp(isInES, :) - repmat(aBscTmp(isInES, 1), 1, length(lidarType))) ./ ...
        repmat(aBscTmp(isInES, 1), 1, length(lidarType)), 1) * 100;

    for iLidar = 2:length(lidarType)
        fprintf(fid, 'Mean relative deviations of %s: %6.2f%% (max: %6.2f%%)\n', ...
            lidarType{iLidar}, ...
            meanABscDev(iES, iLidar), ...
            config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 1));
        fprintf(fid, 'Standard relative deviations of %s: %6.2f%% (max: %6.2f%%)\n', ...
            lidarType{iLidar}, ...
            stdABscDev(iES, iLidar), ...
            config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 2));
    end
end

%% data visualization
cmaps = colormap('jet');

% backscatter
figure('Position', [0, 10, 300, 400], ...
       'Units', 'Pixels', ...
       'Color', 'w', ...
       'Visible', config.externalChkCfg.figVisible);

lineInstances = [];
lineInstances(1) = plot(aBsc(:, 1), height, ...
    'Color', 'k', ...
    'LineStyle', '-', ...
    'LineWidth', 2, ...
    'DisplayName', lidarType{1});
hold on;

for iLidar = 2:length(lidarType)
    p1 = plot(aBsc(:, iLidar), height, ...
        'color', cmaps(floor((iLidar - 1) / (length(lidarType) - 1) * 250), :), ...
        'LineStyle', '-', ...
        'LineWidth', 2, ...
        'DisplayName', lidarType{iLidar});
    hold on;
    lineInstances = cat(1, lineInstances, p1);
end
plot([0, 0], [-100000, 100000], '-.k');

% fit range
plot(config.externalChkCfg.FernaldCmpCfg.bscRange, ...
    [1, 1] * config.externalChkCfg.FernaldCmpCfg.refRange(1), '--', ...
    'Color', [152, 78, 163]/255, ...
    'LineWidth', 2);
plot(config.externalChkCfg.FernaldCmpCfg.bscRange, ...
    [1, 1] * config.externalChkCfg.FernaldCmpCfg.refRange(2), '--', ...
    'Color', [152, 78, 163]/255, ...
    'LineWidth', 2);

xlabel('Bsc. coeff. (m^{-1}*sr^{-1})');
ylabel('Height (m)');
title('Aerosol backscatter comparison');

xlim(config.externalChkCfg.FernaldCmpCfg.bscRange);
ylim(config.externalChkCfg.FernaldCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
    'YMinorTick', 'on', ...
    'Layer', 'Top', ...
    'Box', 'on', ...
    'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.2, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('Fernald_backscatter_comparison.%s', config.figFormat)), '-r300');
end

% extinction
figure('Position', [0, 10, 300, 400], ...
       'Units', 'Pixels', ...
       'Color', 'w', ...
       'Visible', config.externalChkCfg.figVisible);

lineInstances = [];
lineInstances(1) = plot(aExt(:, 1), height, ...
    'Color', 'k', ...
    'LineStyle', '-', ...
    'LineWidth', 2, ...
    'DisplayName', lidarType{1});
hold on;

for iLidar = 2:length(lidarType)
    p1 = plot(aExt(:, iLidar), height, ...
        'color', cmaps(floor((iLidar - 1) / (length(lidarType) - 1) * 250), :), ...
        'LineStyle', '-', ...
        'LineWidth', 2, ...
        'DisplayName', lidarType{iLidar});
    hold on;
    lineInstances = cat(1, lineInstances, p1);
end
plot([0, 0], [-100000, 100000], '-.k');

% fit range
plot(config.externalChkCfg.FernaldCmpCfg.extRange, ...
    [1, 1] * config.externalChkCfg.FernaldCmpCfg.refRange(1), '--', ...
    'Color', [152, 78, 163]/255, ...
    'LineWidth', 2);
plot(config.externalChkCfg.FernaldCmpCfg.extRange, ...
    [1, 1] * config.externalChkCfg.FernaldCmpCfg.refRange(2), '--', ...
    'Color', [152, 78, 163]/255, ...
    'LineWidth', 2);

xlabel('Ext. coeff. (m^{-1})');
ylabel('Height (m)');
title('Aerosol extinction comparison');

xlim(config.externalChkCfg.FernaldCmpCfg.extRange);
ylim(config.externalChkCfg.FernaldCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'LineWidth', 2);

lgHandle = legend(lineInstances, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.2, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('Fernald_extinction_comparison.%s', config.figFormat)), '-r300');
end

% relative deviation
figure('Position', [0, 10, 300, 400], ...
    'Units', 'Pixels', ...
    'Color', 'w', ...
    'Visible', config.externalChkCfg.figVisible);

lineInstances0 = [];
for iLidar = 2:length(lidarType)
    p1 = plot(aBscDev(:, iLidar), height, ...
        'LineStyle', '-', ...
        'Color', lineInstances(iLidar).Color, ...
        'LineWidth', 2, ...
        'DisplayName', lidarType{iLidar});
    hold on;

    lineInstances0 = cat(1, lineInstances0, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 1), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2, ...
        'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 1), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);

    if iES <= 1
        lineInstances0 = cat(1, lineInstances0, p3);
    end
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1), ...
         config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1)], ...
        [config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1)], ...
         [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 2), ...
            config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '-.', ...
            'Color', [160, 160, 160]/255, ...
            'LineWidth', 2, ...
            'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 2), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '-.', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);

    if iES <= 1
        lineInstances0 = cat(1, lineInstances0, p4);
    end
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2)], ...
        [config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Relative Dev. (%)');
ylabel('Height (m)');
title('Backscatter/extinction comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.FernaldCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'LineWidth', 2);

lgHandle = legend(lineInstances0, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('Fernald_deviation.%s', config.figFormat)), '-r300');
end

% mean relative deviation
figure('Position', [0, 10, 300, 400], ...
       'Units', 'Pixels', ...
       'Color', 'w', ...
       'Visible', config.externalChkCfg.figVisible);

lineInstances1 = [];
for iLidar = 2:length(lidarType)
    p1 = scatter(meanABscDev(:, iLidar), ...
        mean(config.externalChkCfg.FernaldCmpCfg.hChkRange, 2), 25, ...
        'Marker', 's', 'MarkerFaceColor', lineInstances(iLidar).Color, ...
        'MarkerEdgeColor', lineInstances(iLidar).Color, ...
        'DisplayName', lidarType{iLidar});
    hold on;

    lineInstances1 = cat(1, lineInstances1, p1);
end

plot([0, 0], [-100000, 100000], '--k');

% error bound (mean deviation)
for iES = 1:nES
    p3 = plot([-1, -1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 1), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2, ...
        'DisplayName', 'Mean Dev.');
    plot([1, 1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 1), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '--', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);

    if iES <= 1
        lineInstances1 = cat(1, lineInstances1, p3);
    end
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1), ...
         config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 1)], ...
        [config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

% error bound (standard deviation)
for iES = 1:nES
    p4 = plot([-1, -1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 2), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '-.', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2, ...
        'DisplayName', 'Standard Dev.');
    plot([1, 1] * config.externalChkCfg.FernaldCmpCfg.maxDev(iES, 2), ...
        config.externalChkCfg.FernaldCmpCfg.hChkRange(iES, :), '-.', ...
        'Color', [160, 160, 160]/255, ...
        'LineWidth', 2);

    if iES <= 1
        lineInstances1 = cat(1, lineInstances1, p4);
    end
end

for iPatch = 1:nES
    hShaded = patch(...
        [config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2), ...
         -config.externalChkCfg.FernaldCmpCfg.maxDev(iPatch, 2)], ...
        [config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 2), ...
         config.externalChkCfg.FernaldCmpCfg.hChkRange(iPatch, 1)], [160, 160, 160]/255);
    hShaded.FaceAlpha = 0.3;
    hShaded.EdgeColor = 'None';
    hold on;
end

xlabel('Mean Rel. Dev. (%)');
ylabel('Height (m)');
title('Backscatter/extinction comparison');

xlim([-50, 50]);
ylim(config.externalChkCfg.FernaldCmpCfg.hRange);
set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'LineWidth', 2);

lgHandle = legend(lineInstances1, 'Location', 'NorthEast');
lgHandle.Interpreter = 'None';
text(-0.16, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
     'Units', 'Normalized', ...
     'FontSize', 10, ...
     'HorizontalAlignment', 'left', ...
     'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(config.resultPath, 'dir')
    export_fig(gcf, fullfile(config.resultPath, sprintf('Fernald_mean_deviation.%s', config.figFormat)), '-r300');
end

if strcmpi(config.externalChkCfg.figVisible, 'off')
    close all;
end

fclose(fid);

end