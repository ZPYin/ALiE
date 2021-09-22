function [isPassRayleighChk] = RayleighChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% RayleighChk description
% USAGE:
%    [isPassRayleighChk] = RayleighChk(lidarData, lidarConfig, reportFile)
% INPUTS:
%    lidarData, lidarConfig, reportFile
% OUTPUTS:
%    isPassRayleighChk
% EXAMPLE:
% HISTORY:
%    2021-09-19: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

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

isPassRayleighChk = false(1, length(lidarConfig.RayleighChkCfg.wavelength));

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Rayleigh Check\n');

% slot for detection range check
tRange = [datenum(lidarConfig.RayleighChkCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.RayleighChkCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
if sum(isChosen) <= 0
    warning('Insufficient profiles were chosen!');
    return;
end

% load signal
rcs = [];   % height x channel
bg = [];
for iCh = 1:length(lidarConfig.chTag)
    thisRCS = nansum(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isChosen), 2);
    thisBG = nansum(lidarData.(['bg', lidarConfig.chTag{iCh}])(isChosen));

    rcs = cat(2, rcs, thisRCS);
    bg = cat(2, bg, thisBG);
end

for iWL = 1:length(lidarConfig.RayleighChkCfg.wavelength)

    fprintf(fid, '\n**Wavelength: %6.1f nm**\n', lidarConfig.RayleighChkCfg.wavelength(iWL));

    % Mie signal
    MieRCS = rcs * transpose(lidarConfig.RayleighChkCfg.MieGlue(iWL, :));

    % Rayleigh signal
    [temperature, pressure, ~, ~] = read_meteordata(mean(tRange), lidarData.height + 0, ...
        'meteor_data', 'standard_atmosphere', ...
        'station', 'beijing');
    [mBsc, mExt] = rayleigh_scattering(lidarConfig.RayleighChkCfg.wavelength(iWL), pressure, temperature + 273.14, 360, 80);
    mRCS = mBsc .* exp(-2 .* nancumsum([lidarData.height(1); diff(lidarData.height)] .* mExt));

    % normalized
    normInd = (lidarData.height >= lidarConfig.RayleighChkCfg.fitRange(iWL, 1)) & (lidarData.height <= lidarConfig.RayleighChkCfg.fitRange(iWL, 2));
    baseInd = find(normInd, 1, 'first');
    topInd = find(normInd, 1, 'last');
    normRatio = nansum(MieRCS(normInd)) ./ nansum(mRCS(normInd));
    normMRCS = mRCS .* normRatio;

    % determine Rayleigh fit
    smWinLen = round(lidarConfig.RayleighChkCfg.smoothwindow(iWL) / (lidarData.height(2) - lidarData.height(1)));
    devRayleigh = smooth(normMRCS - MieRCS, smWinLen) ./ smooth(normMRCS, smWinLen) * 100;
    isPassRayleighChk(iWL) = any(abs(devRayleigh(normInd)) > lidarConfig.RayleighChkCfg.maxDev(iWL));
    fprintf(fid, 'Normalization range: %f - %f m\n', lidarConfig.RayleighChkCfg.fitRange(iWL, 1), lidarConfig.RayleighChkCfg.fitRange(iWL, 2));
    fprintf(fid, 'Max relative deviation: %f%% (max: %f%%)\n', max(abs(devRayleigh(normInd))), lidarConfig.RayleighChkCfg.maxDev(iWL));
    fprintf(fid, 'Does pass Rayleigh check? (1: yes; 0: no): %d\n', isPassRayleighChk(iWL));

    %% signal visualization
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

    rcsTmp = smooth(MieRCS, smWinLen);
    rcsTmp(rcsTmp <= 0) = NaN;
    mRCSTmp = normMRCS;
    mRCSTmp(mRCSTmp <= 0) = NaN;
    pMie = semilogx(rcsTmp, lidarData.height, 'Color', [140, 140, 140]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'RCS'); hold on;
    pMol = semilogx(mRCSTmp, lidarData.height, 'Color', [178, 34, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'Molecular');

    % norm range
    plot(lidarConfig.RayleighChkCfg.sigRange(iCh, :), [1, 1] * lidarConfig.RayleighChkCfg.fitRange(iWL, 1), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);
    plot(lidarConfig.RayleighChkCfg.sigRange(iCh, :), [1, 1] * lidarConfig.RayleighChkCfg.fitRange(iWL, 2), '--', 'Color', [152, 78, 163]/255, 'LineWidth', 2);

    % signal bound
    plot((100 - lidarConfig.RayleighChkCfg.maxDev(iWL)) / 100 * [mRCSTmp(baseInd), mRCSTmp(topInd)], lidarConfig.RayleighChkCfg.fitRange(iWL, :), '-.', 'Color', [178, 34, 34]/255, 'LineWidth', 1);
    plot((100 + lidarConfig.RayleighChkCfg.maxDev(iWL)) / 100 * [mRCSTmp(baseInd), mRCSTmp(topInd)], lidarConfig.RayleighChkCfg.fitRange(iWL, :), '-.', 'Color', [178, 34, 34]/255, 'LineWidth', 1);

    xlabel('RCS (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Rayleigh test (%s, %4fnm)', lidarType, lidarConfig.RayleighChkCfg.wavelength(iWL)));

    xlim(lidarConfig.RayleighChkCfg.sigRange(iCh, :));
    ylim(lidarConfig.RayleighChkCfg.hRange(iCh, :));
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([pMie, pMol], 'Location', 'NorthEast');
    text(0.6, 0.76, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('detection_range_test_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end