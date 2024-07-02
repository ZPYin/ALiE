function [isPassTempChk] = tempChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% TEMPCHK Temperature Raman channel test.
%
% USAGE:
%    [isPassTempChk] = tempChk(lidarData, lidarConfig, reportFile, lidarType)
%
% INPUTS:
%    lidarData: struct
%    lidarConfig: struct
%    reportFile: char
%    lidarType: char
%
% KEYWORDS:
%    figFolder: char
%    figFormat: char
%
% OUTPUTS:
%    isPassTempChk: logical
%
% HISTORY:
%    2024-07-02: first edition by Zhenping
% .. Authors: - zp.yin@whu.edu.cn

global LEToolboxInfo

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'lidarData', @isstruct);
addRequired(p, 'lidarConfig', @isstruct);
addRequired(p, 'reportFile', @ischar);
addRequired(p, 'lidarType', @ischar);
addParameter(p, 'figFolder', '', @ischar);
addParameter(p, 'figFormat', 'png', @ischar);

parse(p, lidarData, lidarConfig, reportFile, lidarType, varargin{:});

isPassTempChk = false(1, 1);

isFit = false;   % whether to implement linear fit
if isfield(lidarConfig.tempChkCfg, 'flagTempFit')
    if lidarConfig.tempChkCfg.flagTempFit
        isFit = true;
    end
end

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Temperature Check\n');

% slot for detection range check
tRange = [datenum(lidarConfig.tempChkCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
          datenum(lidarConfig.tempChkCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
if sum(isChosen) <= 0
    warning('Insufficient profiles were chosen!');
    return;
end

% load signal
chTags = {'353', '354'};
rcs = [];   % height x channel
sig = [];
bg = [];
for iCh = 1:length(chTags)
    thisRCS = nanmean(lidarData.(['rcs', chTags{iCh}])(:, isChosen), 2);
    thisSIG = nanmean(lidarData.(['sig', chTags{iCh}])(:, isChosen), 2);
    thisBG = nanmean(lidarData.(['bg', chTags{iCh}])(isChosen));

    rcs = cat(2, rcs, thisRCS);
    sig = cat(2, sig, thisSIG);
    bg = cat(2, bg, thisBG);
end

% Range corrected signal
sigHJ = sig(:, 1);
sigLJ = sig(:, 2);
RCSHJ = rcs(:, 1);
RCSLJ = rcs(:, 2);
bgHJ = bg(:, 1);
bgLJ = bg(:, 2);

% smooth signal
smWinLen = round(lidarConfig.tempChkCfg.smoothwindow / (lidarData.height(2) - lidarData.height(1)));
RCSHJsm = smooth(RCSHJ, smWinLen);
RCSLJsm = smooth(RCSLJ, smWinLen);
SNRHJ = lidarSNR(sigHJ, bgHJ, 'bgBins', lidarConfig.preprocessCfg.bgBins) * sqrt(smWinLen);
SNRLJ = lidarSNR(sigLJ, bgLJ, 'bgBins', lidarConfig.preprocessCfg.bgBins) * sqrt(smWinLen);

%% Load Sonde
sonde = struct();
switch lidarConfig.tempChkCfg.MeteorSource
case 'websonde'

    mDate = floor(mean(lidarData.mTime));
    flagBefore06 = mean(lidarData.mTime) <= (mDate + datenum(0, 1, 0, 6, 0, 0));
    flagAfter18 = mean(lidarData.mTime) >= (mDate + datenum(0, 1, 0, 18, 0, 0));

    if (flagBefore06)
        sondeTime = mDate + datenum(0, 1, 0, 0, 0, 0);
    elseif (flagAfter18)
        sondeTime = mDate + 1;
    else
        sondeTime = mDate + datenum(0, 1, 0, 12, 0, 0);
    end

    [alt, temp, ~, ~] = read_websonde(sondeTime, ...
        [sondeTime - datenum(0, 1, 0, 6, 0, 0), sondeTime + datenum(0, 1, 0, 6, 0, 0)], ...
        lidarConfig.tempChkCfg.WMOStationID, 'BUFR');
    sonde.altitude = alt;
    sonde.temperature = temp + 273.14;

case 'localsonde'

    sondeData = read_sonde(lidarConfig.tempChkCfg.MeteorFile);
    sonde.altitude = sondeData.height;
    sonde.temperature = sondeData.temperature + 273.14;

otherwise

    sonde.altitude = [];
    sonde.temperature = [];
    warning('Unknown meteorological source: %s', lidarConfig.tempChkCfg.MeteorSource);

end

% interpolate sonde profile to lidar height bins
rsTempInterp = [];
if ~ isempty(sonde.altitude)
    isValid = (~ isnan(sonde.temperature));
    rsH = (sonde.altitude - sonde.altitude(1));

    rsH = rsH(isValid);
    rsTemp = sonde.temperature(isValid);

    % sort height
    [rsH_sort, sortIdx] = sort(rsH);
    rsTemp_sort = rsTemp(sortIdx);

    % remove duplicated values
    [rsH_uniq, uniqIdx] = unique(rsH_sort);
    rsTemp_uniq = rsTemp_sort(uniqIdx);

    if length(rsTemp_uniq) >= 3
        rsTempInterp = interp1(rsH_uniq, rsTemp_uniq, lidarData.height);
    end
end

%% Lidar uncalibrated signal ratio
QRaw = RCSHJsm ./ RCSLJsm;
QRawStd = QRaw .* sqrt(1 ./ SNRHJ.^2 + 1 ./ SNRLJ.^2);

%% Temperature Calibration
tempConst = NaN;
if isFit && (~ isempty(rsTempInterp))
    % linear fit
    isInCaliRange = (lidarData.height >= lidarConfig.tempChkCfg.fitRange(1)) & ...
                    (lidarData.height <= lidarConfig.tempChkCfg.fitRange(2));
    isValidCaliPoints =  (SNRHJ >= 3) & (SNRLJ >= 3) & (~ isnan(rsTempInterp));

    [tempConst, ~] = polyfit(1 ./ (rsTempInterp(isValidCaliPoints)), log(QRaw), 2);

elseif (~ isFit)
    % fixed temperature calibration constant
    tempConst = lidarConfig.tempChkCfg.tempConst;
end

TRetFunc = @(x) (-2 * tempConst(1) ./ (tempConst(2) + sqrt(tempConst(2).^2 - 4 * tempConst(1) * (tempConst(3) - log(x)))));

%% temperature Product Assessment
tempAbsErr = NaN(size(QRaw));
tempBias = NaN(size(QRaw));
tempStd = NaN(size(QRaw));
meanAbsDev = NaN;
if ~ isnan(tempConst)
    isPositive = QRaw > 0;
    temp_lidar(isPositive) = TRetFunc(QRaw(isPositive));

    tempBias(isPositive) = temp_lidar(isPositive) - rsTempInterp(isPositive);
    tempAbsErr(isPositive) = abs(temp_lidar(isPositive) - rsTempInterp(isPositive));
    tempStd(isPositive) = abs((TRetFunc(QRaw(isPositive) + 0.0001) - TRetFunc(QRaw(isPositive))) / 0.0001 .* sqrt(QRawStd(isPositive)));

    isInEvalRange = (lidarData.height >= lidarConfig.tempChkCfg.evalRange(1)) & ...
                    (lidarData.height <= lidarConfig.tempChkCfg.evalRange(2));

    meanAbsDev = nanmean(tempAbsErr(isInEvalRange));
end

% determine temperature test
if ~ isnan(tempConst)
    % with calibration
    isPassTempChk = (meanAbsDev <= lidarConfig.tempChkCfg.meanAbsDev);

    fprintf(fid, 'Temperature calibration constant: %f\n', ...
        tempConst);
    fprintf(fid, 'Mean absolute deviation: %6.3f K (max: %f%% K)\n', ...
        meanAbsDev, lidarConfig.tempChkCfg.meanAbsDev);
    fprintf(fid, 'Does pass temperature check? (1: yes; 0: no): %d\n', isPassTempChk);
else
    % no calibrated temperature product
    fprintf(fid, 'No temperature calibration!\n');
    fprintf(fid, 'Does pass temperature check? (1: yes; 0: no): %d\n', 0);
end

%% signal visualization

% temperature calibration
if isLinearFit && (~ isempty(rsTempInterp))
    figure('Position', [0, 10, 400, 300], ...
        'Units', 'Pixels', ...
        'Color', 'w', ...
        'Visible', lidarConfig.figVisible);

    hold on;
    scatter(rsTempInterpRaw(isInCaliRange & isValidCaliPoints), QRaw(isInCaliRange & isValidCaliPoints), 5, ...
        'Marker', 'o', ...
        'MarkerFaceColor', 'b', ...
        'MarkerEdgeColor', 'b');

    minQRaw = min(QRaw(isInCaliRange & isValidCaliPoints));
    maxQRaw = max(QRaw(isInCaliRange & isValidCaliPoints));
    plot(TRetFunc(linspace(minQRaw, maxQRaw, 20)), linspace(minQRaw, maxQRaw, 20), '--r', 'LineWidth', 2);
    hold off;

    xlabel('temperature (K)');
    ylabel('Q');
    title('Fit for temperature calibration');

    xlim(lidarConfig.tempChkCfg.tempRange);
    % ylim(lidarConfig.tempChkCfg.wvmrRange);

    text(0.1, 0.7, sprintf('Temperature const: %f*(1/T)^2 + %f*(1/T) + %f', tempConst(1), tempConst(2), tempConst(3)), 'Units', 'Normalized', ...
        'FontSize', 10);
    text(0.8, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
        'Units', 'Normalized', ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'Bold');

    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Box', 'on');

    if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
        addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
    end

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, ...
            sprintf('wv_test_linearfit_%s.%s', lidarType, p.Results.figFormat)), '-r300');
    end
end

% profiles of temperature
figure('Position', [0, 10, 700, 400], ...
    'Units', 'Pixels', ...
    'Color', 'w', ...
    'Visible', lidarConfig.figVisible);

subPos = subfigPos([0.1, 0.11, 0.86, 0.8], 1, 3, 0.04, 0);

% signal
subplot('Position', subPos(1, :), 'Units', 'Normalized');

hold on;
RCSLJsm(RCSLJsm <= 0) = NaN;
RCSHJsm(RCSHJsm <= 0) = NaN;
p1 = semilogx(RCSLJsm, lidarData.height, '-b', 'LineWidth', 2, 'DisplayName', 'LJ');
p2 = semilogx(RCSHJsm, lidarData.height, '-g', 'LineWidth', 2, 'DisplayName', 'HJ');
hold off;

xlabel('RCS (a.u.)');
ylabel('Height (m)');

ylim(lidarConfig.tempChkCfg.hRange);

legend([p1, p2], 'Location', 'NorthEast');

set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'XScale', 'log', ...
         'LineWidth', 2);

% temperature
subplot('Position', subPos(2, :), 'Units', 'Normalized');

if ~ isnan(tempConst)
    hold on;
    p1 = plot(abs(), lidarData.height, '-b', 'LineWidth', 2, 'DisplayName', 'lidar');

    if ~ isempty(sonde.altitude)
        p2 = plot(sonde.temperature, sonde.altitude - sonde.altitude(1), '-r', 'LineWidth', 2, 'DisplayName', 'sonde');
    else
        p2 = plot([], [], '-r', 'DisplayName', 'sonde');
    end
    hold off;
    
    xlabel('Temperature (K)');
    ylabel('');
    title(sprintf('%s-%s', datestr(tRange(1), 'yyyy-mm-dd HH:MM'), datestr(tRange(2), 'HH:MM')));
    
    ylim(lidarConfig.tempChkCfg.hRange);
    xlim(lidarConfig.tempChkCfg.tempRange);

    legend([p1, p2], 'Location', 'NorthEast');

    set(gca, 'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'YTickLabel', '', ...
        'Layer', 'Top', ...
        'Box', 'on', ...
        'LineWidth', 2);
end

% error
subplot('Position', subPos(3, :), 'Units', 'Normalized');

hold on;
if ~ isempty(tempAbsErr)
    p1 = plot(tempBias, lidarData.height, '-k', 'LineWidth', 2, 'DisplayName', 'abs. err.');
    p2 = plot(tempStd, lidarData.height, '--m', 'LineWidth', 2, 'DisplayName', 'uncertainty');
else
    p1 = plot([], [], '-b', 'DisplayName', 'abs. err.');
    p2 = plot([], [], '--m', 'DisplayName', 'uncertainty');
end
plot(lidarConfig.tempChkCfg.meanAbsDev .* [1, 1], [0, 10000], '--r');
plot(lidarConfig.tempChkCfg.meanAbsDev .* [-1, -1], [0, 10000], '--r');
plot([0, 0], [0, 10000], '--k');
hold off;

xlabel('Error (K)');
ylabel('');

xlim([-1, 1]);
ylim(lidarConfig.tempChkCfg.hRange);

set(gca, 'XMinorTick', 'on', ...
        'YMinorTick', 'on', ...
        'YTickLabel', '', ...
        'Layer', 'Top', ...
        'Box', 'on', ...
        'LineWidth', 2);

legend([p1, p2], 'Location', 'NorthEast');
text(0.69, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
    'Units', 'Normalized', ...
    'FontSize', 10, ...
    'HorizontalAlignment', 'left', ...
    'FontWeight', 'Bold');

if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
    addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
end

if exist(p.Results.figFolder, 'dir')
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('temperature_profile_%s.%s', lidarType, p.Results.figFormat)), '-r300');
end

if strcmpi(lidarConfig.figVisible, 'off')
    close all;
end

fclose(fid);

end