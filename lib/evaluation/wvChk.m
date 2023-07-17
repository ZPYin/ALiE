function [isPassWVChk] = wvChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% WVCHK Water Vapor Raman channel test.
%
% USAGE:
%    [isPassWVChk] = wvChk(lidarData, lidarConfig, reportFile, lidarType)
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
%    isPassWVChk: logical
%
% HISTORY:
%    2023-07-15: first edition by Zhenping
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

isPassWVChk = false(1, 1);

isLinearFit = false;   % whether to implement linear fit
if isfield(lidarConfig.wvChkCfg, 'flagWVFit')
    if lidarConfig.wvChkCfg.flagWVFit
        isLinearFit = true;
    end
end

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Water Vapor Check\n');

% slot for detection range check
tRange = [datenum(lidarConfig.wvChkCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
          datenum(lidarConfig.wvChkCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
if sum(isChosen) <= 0
    warning('Insufficient profiles were chosen!');
    return;
end

% load signal
chTags = {'407', '386'};
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
sig407 = sig(:, 1);
sig386 = sig(:, 2);
RCS407 = rcs(:, 1);
RCS386 = rcs(:, 2);
bg407 = bg(:, 1);
bg386 = bg(:, 2);

% smooth signal
smWinLen = round(lidarConfig.wvChkCfg.smoothwindow / (lidarData.height(2) - lidarData.height(1)));
RCS407sm = smooth(RCS407, smWinLen);
RCS386sm = smooth(RCS386, smWinLen);
SNR407 = lidarSNR(sig407, bg407, 'bgBins', lidarConfig.preprocessCfg.bgBins) * sqrt(smWinLen);
SNR386 = lidarSNR(sig386, bg386, 'bgBins', lidarConfig.preprocessCfg.bgBins) * sqrt(smWinLen);

%% Load Sonde
sonde = struct();
switch lidarConfig.wvChkCfg.MeteorSource
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

    [alt, temp, pres, rh] = read_websonde(sondeTime, ...
        [sondeTime - datenum(0, 1, 0, 6, 0, 0), sondeTime + datenum(0, 1, 0, 6, 0, 0)], ...
        lidarConfig.wvChkCfg.WMOStationID, 'BUFR');
    es = saturated_vapor_pres(temp);
    WVMR_rs = 18.0160 / 28.9660 * rh / 100 .* es ./ (pres - rh / 100 .* es) * 1000;
    sonde.altitude = alt;
    sonde.WVMR = WVMR_rs;

case 'localsonde'
    sondeData = read_sonde(lidarConfig.wvChkCfg.MeteorFile);
    es = saturated_vapor_pres(sondeData.temperature);
    sonde.altitude = sondeData.height;
    sonde.WVMR = 18.0160 / 28.9660 * sondeData.relative_humidity / 100 .* ...
        es ./ (sondeData.pressure - sondeData.relative_humidity / 100 .* es) * 1000;

otherwise

    sonde.altitude = [];
    sonde.WVMR = [];
    warning('Unknown meteorological source: %s', lidarConfig.wvChkCfg.MeteorSource);

end

% interpolate sonde profile to lidar height bins
rsWVMRInterp = [];
if ~ isempty(sonde.altitude)
    isValid = (~ isnan(sonde.WVMR));
    rsH = (sonde.altitude - sonde.altitude(1));

    rsH = rsH(isValid);
    rsWVMR = sonde.WVMR(isValid);

    % sort height
    [rsH_sort, sortIdx] = sort(rsH);
    rsWVMR_sort = rsWVMR(sortIdx);

    % remove duplicated values
    [rsH_uniq, uniqIdx] = unique(rsH_sort);
    rsWVMR_uniq = rsWVMR_sort(uniqIdx);

    if length(rsWVMR_uniq) >= 3
        rsWVMRInterp = interp1(rsH_uniq, rsWVMR_uniq, lidarData.height);
    end
end

%% Lidar uncalibrated water vapor mixing ratio
WVMRRaw = RCS407sm ./ RCS386sm;
WVMRRawStd = WVMRRaw .* sqrt(1 ./ SNR407.^2 + 1 ./ SNR386.^2);

%% Water Vapor Calibration
wvConst = NaN;
if isLinearFit && (~ isempty(rsWVMRInterp))
    % linear fit
    isInCaliRange = (lidarData.height >= lidarConfig.wvChkCfg.fitRange(1)) & ...
                    (lidarData.height <= lidarConfig.wvChkCfg.fitRange(2));
    isValidCaliPoints =  (SNR407 >= 3) & (SNR386 >= 3) & (~ isnan(rsWVMRInterp));

    lrWV = fitlm(WVMRRaw(isInCaliRange & isValidCaliPoints), ...
                 rsWVMRInterp(isInCaliRange & isValidCaliPoints), ...
                 'Intercept', false, ...
                 'weights', WVMRRawStd(isInCaliRange & isValidCaliPoints));

    wvConst = lrWV.Coefficients.Estimate(1);

elseif (~ isLinearFit)
    % fixed water vapor calibration constant
    wvConst = lidarConfig.wvChkCfg.wvConst;

end

%% Water Vapor Mixing Ratio Product Assessment
WVAbsErr = [];
WVBias = [];
meanAbsDev = NaN;
if ~ isnan(wvConst)
    WVMR_lidar = wvConst .* WVMRRaw;

    WVBias = WVMR_lidar - rsWVMRInterp;
    WVAbsErr = abs(WVMR_lidar - rsWVMRInterp);

    isInEvalRange = (lidarData.height >= lidarConfig.wvChkCfg.evalRange(1)) & ...
                    (lidarData.height <= lidarConfig.wvChkCfg.evalRange(2));

    meanAbsDev = nanmean(WVAbsErr(isInEvalRange));
end

% determine water vapor test
if ~ isnan(wvConst)
    % with calibration
    isPassWVChk = (meanAbsDev <= lidarConfig.wvChkCfg.meanAbsDev);

    fprintf(fid, 'Water vapor calibration constant: %f g/kg\n', ...
        wvConst);
    fprintf(fid, 'Mean absolute deviation: %6.3f g/kg (max: %f%%)\n', ...
        meanAbsDev, lidarConfig.wvChkCfg.meanAbsDev);
    fprintf(fid, 'Does pass water vapor check? (1: yes; 0: no): %d\n', isPassWVChk);
else
    % no calibrated water vapor product
    fprintf(fid, 'No water vapor calibration!\n');
    fprintf(fid, 'Does pass water vapor check? (1: yes; 0: no): %d\n', 0);
end

%% signal visualization

% water vapor calibration
if isLinearFit && (~ isempty(rsWVMRInterp))
    figure('Position', [0, 10, 400, 300], ...
        'Units', 'Pixels', ...
        'Color', 'w', ...
        'Visible', lidarConfig.figVisible);

    hold on;
    scatter(WVMRRaw(isInCaliRange & isValidCaliPoints), rsWVMRInterp(isInCaliRange & isValidCaliPoints), 5, ...
        'Marker', 'o', ...
        'MarkerFaceColor', 'b', ...
        'MarkerEdgeColor', 'b');

    plot([-1e5, 1e5], [-1e5, 1e5] .* wvConst, '--r', 'LineWidth', 2);
    hold off;

    xlabel('WVMR-Lidar (a.u.)');
    ylabel('WVMR-Sonde (g/kg)');
    title('Linear Fit for water vapor calibration');

    xlim([min(WVMRRaw(isInCaliRange & isValidCaliPoints)) * 0.9, max(WVMRRaw(isInCaliRange & isValidCaliPoints)) * 1.1]);
    ylim(lidarConfig.wvChkCfg.wvmrRange);

    text(0.1, 0.7, sprintf('wv const: %f g/kg', wvConst), 'Units', 'Normalized', ...
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

% profiles of water vapor
figure('Position', [0, 10, 700, 400], ...
    'Units', 'Pixels', ...
    'Color', 'w', ...
    'Visible', lidarConfig.figVisible);

subPos = subfigPos([0.1, 0.11, 0.86, 0.8], 1, 3, 0.04, 0);

% signal
subplot('Position', subPos(1, :), 'Units', 'Normalized');

hold on;
RCS386sm(RCS386sm <= 0) = NaN;
RCS407sm(RCS407sm <= 0) = NaN;
p1 = semilogx(RCS386sm, lidarData.height, '-b', 'LineWidth', 2, 'DisplayName', '386');
p2 = semilogx(RCS407sm, lidarData.height, '-g', 'LineWidth', 2, 'DisplayName', '407');
hold off;

xlabel('RCS (a.u.)');
ylabel('Height (m)');

ylim(lidarConfig.wvChkCfg.hRange);

legend([p1, p2], 'Location', 'NorthEast');

set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'Layer', 'Top', ...
         'Box', 'on', ...
         'XScale', 'log', ...
         'LineWidth', 2);

% wvmr
subplot('Position', subPos(2, :), 'Units', 'Normalized');

if ~ isnan(wvConst)
    hold on;
    p1 = plot(WVMR_lidar, lidarData.height, '-b', 'LineWidth', 2, 'DisplayName', 'lidar');

    if ~ isempty(sonde.altitude)
        p2 = plot(sonde.WVMR, sonde.altitude - sonde.altitude(1), '-r', 'LineWidth', 2, 'DisplayName', 'sonde');
    else
        p2 = plot([], [], '-r', 'DisplayName', 'sonde');
    end
    hold off;
    
    xlabel('WVMR (g/kg)');
    ylabel('');
    title(sprintf('%s-%s', datestr(tRange(1), 'yyyy-mm-dd HH:MM'), datestr(tRange(2), 'HH:MM')));
    
    ylim(lidarConfig.wvChkCfg.hRange);
    xlim(lidarConfig.wvChkCfg.wvmrRange);

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
if ~ isempty(WVAbsErr)
    p1 = plot(WVBias, lidarData.height, '-k', 'LineWidth', 2, 'DisplayName', 'abs. err.');
    p2 = plot(WVMRRawStd .* wvConst, lidarData.height, '--m', 'LineWidth', 2, 'DisplayName', 'uncertainty');
else
    p1 = plot([], [], '-b', 'DisplayName', 'abs. err.');
    p2 = plot([], [], '--m', 'DisplayName', 'uncertainty');
end
plot(lidarConfig.wvChkCfg.meanAbsDev .* [1, 1], [0, 10000], '--r');
plot(lidarConfig.wvChkCfg.meanAbsDev .* [-1, -1], [0, 10000], '--r');
plot([0, 0], [0, 10000], '--k');
hold off;

xlabel('Error (g/kg)');
ylabel('');

xlim([-1, 1]);
ylim(lidarConfig.wvChkCfg.hRange);

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
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('wv_profile_%s.%s', lidarType, p.Results.figFormat)), '-r300');
end

if strcmpi(lidarConfig.figVisible, 'off')
    close all;
end

fclose(fid);

end