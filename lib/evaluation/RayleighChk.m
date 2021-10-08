function [isPassRayleighChk] = RayleighChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% RAYLEIGHCHK Rayleigh fit.
% USAGE:
%    [isPassRayleighChk] = RayleighChk(lidarData, lidarConfig, reportFile, lidarType)
% INPUTS:
%    lidarData: struct
%    lidarConfig: struct
%    reportFile: char
%    lidarType: char
% KEYWORDS:
%    figFolder: char
%    figFormat: char
% OUTPUTS:
%    isPassRayleighChk: logical
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

isLinearFit = false;   % whether to implement linear fit
if isfield(lidarConfig.RayleighChkCfg, 'flagLinearFit')
    if lidarConfig.RayleighChkCfg.flagLinearFit
        isLinearFit = true;
    end
end

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Rayleigh Check\n');

% slot for detection range check
tRange = [datenum(lidarConfig.RayleighChkCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
          datenum(lidarConfig.RayleighChkCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
if sum(isChosen) <= 0
    warning('Insufficient profiles were chosen!');
    return;
end

% load signal
rcs = [];   % height x channel
bg = [];
for iCh = 1:length(lidarConfig.chTag)
    thisRCS = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isChosen), 2);
    thisBG = nanmean(lidarData.(['bg', lidarConfig.chTag{iCh}])(isChosen));

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
    [mBsc, mExt] = rayleigh_scattering(lidarConfig.RayleighChkCfg.wavelength(iWL), ...
        pressure, temperature + 273.14, 360, 80);
    mRCS = mBsc .* exp(-2 .* nancumsum([lidarData.height(1); diff(lidarData.height)] .* mExt));

    smWinLen = round(lidarConfig.RayleighChkCfg.smoothwindow(iWL) / ...
        (lidarData.height(2) - lidarData.height(1)));

    % normalized
    normInd = (lidarData.height >= lidarConfig.RayleighChkCfg.fitRange(iWL, 1)) & ...
              (lidarData.height <= lidarConfig.RayleighChkCfg.fitRange(iWL, 2));
    baseInd = find(normInd, 1, 'first');
    topInd = find(normInd, 1, 'last');
    normRatio = nansum(MieRCS(normInd)) ./ nansum(mRCS(normInd));
    normMRCS = smooth(mRCS .* normRatio, smWinLen);
    MieRCSSm = smooth(MieRCS, smWinLen);

    % determine Rayleigh fit (with signal deviations)
    devRayleigh = (normMRCS - MieRCSSm) ./ normMRCS * 100;
    isPassRayleighChk(iWL) = nanmean(abs(devRayleigh(normInd))) <= lidarConfig.RayleighChkCfg.maxDev(iWL);
    fprintf(fid, 'Normalization range: %f - %f m\n', ...
        lidarConfig.RayleighChkCfg.fitRange(iWL, 1), ...
        lidarConfig.RayleighChkCfg.fitRange(iWL, 2));
    fprintf(fid, 'Mean relative deviation: %f%% (max: %f%%)\n', ...
        nanmean(abs(devRayleigh(normInd))), ...
        lidarConfig.RayleighChkCfg.maxDev(iWL));
    fprintf(fid, 'Does pass Rayleigh check? (1: yes; 0: no): %d\n', isPassRayleighChk(iWL));

    if isLinearFit
        % determine Rayleigh fit with linear regression
        mRCSFit = normMRCS(normInd);
        isMRCSPos = mRCSFit > 0;
        mieRCSFit = MieRCSSm(normInd);
        isMieRCSPos = mieRCSFit > 0;
        heightFit = lidarData.height(normInd);

        lrMol = fitlm(log10(mRCSFit(isMRCSPos)), heightFit(isMRCSPos));
        lrAer = fitlm(log10(mieRCSFit(isMieRCSPos)), heightFit(isMieRCSPos));

        slopeMieRCS = lrAer.Coefficients.Estimate(2);
        offsetMieRCS = lrAer.Coefficients.Estimate(1);
        R2MieRCS = lrAer.Rsquared.Ordinary;

        slopeMRCS = lrMol.Coefficients.Estimate(2);
        offsetMRCS = lrMol.Coefficients.Estimate(1);
        R2MRCS = lrMol.Rsquared.Ordinary;

        devLinearFit = abs((slopeMieRCS - slopeMRCS) / slopeMRCS) * 100;

        fprintf(fid, 'Linear fit (molecule) slope: %f; offset: %f', slopeMRCS, offsetMRCS);
        fprintf(fid, 'Linear fit (lidar) slope: %f; offset: %f', slopeMieRCS, offsetMieRCS);
        fprintf(fid, 'Rel. dev. slope: %6.2f%%\n', devLinearFit);
    end

    %% signal visualization
    figure('Position', [0, 10, 300, 400], ...
        'Units', 'Pixels', ...
        'Color', 'w', ...
        'Visible', lidarConfig.figVisible);

    rcsTmp = MieRCSSm;
    rcsTmp(rcsTmp <= 0) = NaN;
    mRCSTmp = normMRCS;
    mRCSTmp(mRCSTmp <= 0) = NaN;
    pMie = semilogx(rcsTmp, lidarData.height, ...
        'Color', [140, 140, 140]/255, ...
        'LineStyle', '-', ...
        'LineWidth', 2, ...
        'DisplayName', 'RCS');
    hold on;
    pMol = semilogx(mRCSTmp, lidarData.height, ...
        'Color', [250, 128, 113]/255, ...
        'LineStyle', '-', ...
        'LineWidth', 2, ...
        'DisplayName', 'Molecular');

    % norm range
    plot(lidarConfig.RayleighChkCfg.sigRange(iWL, :), ...
        [1, 1] * lidarConfig.RayleighChkCfg.fitRange(iWL, 1), '--', ...
        'Color', [152, 78, 163]/255, ...
        'LineWidth', 2);
    plot(lidarConfig.RayleighChkCfg.sigRange(iWL, :), ...
        [1, 1] * lidarConfig.RayleighChkCfg.fitRange(iWL, 2), '--', ...
        'Color', [152, 78, 163]/255, ...
        'LineWidth', 2);

    % signal bound
    plot((100 - lidarConfig.RayleighChkCfg.maxDev(iWL)) / 100 * [mRCSTmp(baseInd), mRCSTmp(topInd)], ...
        lidarConfig.RayleighChkCfg.fitRange(iWL, :), '-.', ...
        'Color', [250, 128, 113]/255, ...
        'LineWidth', 1);
    plot((100 + lidarConfig.RayleighChkCfg.maxDev(iWL)) / 100 * [mRCSTmp(baseInd), mRCSTmp(topInd)], ...
        lidarConfig.RayleighChkCfg.fitRange(iWL, :), '-.', ...
        'Color', [250, 128, 113]/255, ...
        'LineWidth', 1);

    if isLinearFit
        % linear fit
        plot(10.^((lidarConfig.RayleighChkCfg.fitRange(iWL, :) - offsetMieRCS) / slopeMieRCS), lidarConfig.RayleighChkCfg.fitRange(iWL, :), '--', ...
            'Color', [0, 0, 0]/255, ...
            'LineWidth', 1);
        plot(10.^((lidarConfig.RayleighChkCfg.fitRange(iWL, :) - offsetMRCS) / slopeMRCS), lidarConfig.RayleighChkCfg.fitRange(iWL, :), '--', ...
            'Color', [255, 69, 0]/255, ...
            'LineWidth', 1);

        text(lidarConfig.RayleighChkCfg.sigRange(iWL, 1), lidarConfig.RayleighChkCfg.fitRange(iWL, 2), sprintf('   s: %f; R^2: %4.2f\n   s (mol): %f; R^2: %4.2f', slopeMieRCS, R2MieRCS, slopeMRCS, R2MRCS), ...
            'Units', 'data', ...
            'fontweight', 'bold', ...
            'fontsize', 9, ...
            'verticalalignment', 'bottom');
    end

    xlabel('RCS (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Rayleigh test (%s, %4.0fnm)', ...
        lidarType, lidarConfig.RayleighChkCfg.wavelength(iWL)));

    xlim(lidarConfig.RayleighChkCfg.sigRange(iWL, :));
    ylim(lidarConfig.RayleighChkCfg.hRange(iWL, :));
    set(gca, 'XMinorTick', 'on', ...
             'YMinorTick', 'on', ...
             'Layer', 'Top', ...
             'Box', 'on', ...
             'LineWidth', 2);

    legend([pMie, pMol], 'Location', 'NorthEast');
    text(0.6, 0.76, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
        'Units', 'Normalized', ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('Rayleigh_test_%s_%d.%s', lidarType, lidarConfig.RayleighChkCfg.wavelength(iWL), p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end