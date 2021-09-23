function [isPassDetectRangeChk] = detectRangeChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% detectRangeChk description
% USAGE:
%    [isPassDetectRangeChk] = detectRangeChk(lidarData, lidarConfig, reportFile)
% INPUTS:
%    lidarData, lidarConfig, reportFile
% OUTPUTS:
%    isPassDetectRangeChk
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

isPassDetectRangeChk = false(1, length(lidarConfig.chTag));

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Detection Range Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '\n**%s**\n', lidarConfig.chTag{iCh});

    % slot for detection range check
    tRange = [datenum(lidarConfig.detectRangeChkCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.detectRangeChkCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
    isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
    if sum(isChosen) <= 0
        warning('Insufficient profiles were chosen!');
        continue;
    end

    % signal-noise ratio
    sig = nansum(lidarData.(['sig', lidarConfig.chTag{iCh}])(:, isChosen), 2);
    bg = nansum(lidarData.(['bg', lidarConfig.chTag{iCh}])(isChosen));
    snr0 = lidarSNR(sig, bg, 'bgBins', lidarConfig.preprocessCfg.bgBins);
    fprintf(fid, 'Time slot: %s\nNumber of profiles: %d\n', lidarConfig.detectRangeChkCfg.tRange, sum(isChosen));

    % height with low SNR
    snrTmp = snr0;
    snrTmp(lidarData.height <= lidarConfig.fullOverlapHeight) = Inf;
    lowSNRInd = find(snrTmp < lidarConfig.detectRangeChkCfg.minSNR(iCh), 1);

    if isempty(lowSNRInd)
        isPassDetectRangeChk(iCh) = true;
        fprintf(fid, 'Minimum height with SNR>=%5.2f: overflow\n', lidarConfig.detectRangeChkCfg.minSNR(iCh));
    else
        fprintf(fid, 'Minimum height with SNR>=%5.2f: %9.3f m\n', lidarConfig.detectRangeChkCfg.minSNR(iCh), lidarData.height(lowSNRInd));
        isPassDetectRangeChk(iCh) = (lidarData.height(lowSNRInd) >= lidarConfig.detectRangeChkCfg.minHeight(iCh));
    end
    fprintf(fid, '\nPass detection range check (1: yes; 0: no): %d\n', isPassDetectRangeChk(iCh));

    %% signal visualization
    figure('Position', [0, 10, 550, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

    figPos = subfigPos([0.12, 0.13, 0.87, 0.8], 1, 2, 0.03, 0);

    subplot('Position', figPos(1, :), 'Units', 'Normalized');
    sig0 = sig;
    sig0(sig0 <= 0) = NaN;
    bg0 = bg;
    bg0(bg0 <= 0) = NaN;
    pSig = semilogx(sig0, lidarData.height, 'Color', [48, 80, 79]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'signal'); hold on;
    pBg = semilogx([bg0, bg0], [lidarData.height(1), lidarData.height(end)], 'Color', [177, 89, 41]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'background');

    xlabel('Backscatter (a.u.)');
    ylabel('Height (m)');
    text(1.15, 1.05, sprintf('Detection range test (%s, %s)', lidarType, lidarConfig.chTag{iCh}), 'Units', 'Normalized', 'FontSize', 12, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center');

    xlim(lidarConfig.detectRangeChkCfg.sigRange(iCh, :));
    ylim(lidarConfig.detectRangeChkCfg.hRange(iCh, :));
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([pSig, pBg], 'Location', 'NorthEast');
    text(-0.1, -0.1, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');
    text(0.3, 0.7, sprintf('From %s\nto %s\nProfiles: %d\n', datestr(tRange(1), 'yyyy-mm-dd HH:MM'), datestr(tRange(2), 'yyyy-mm-dd HH:MM'), sum(isChosen)), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    subplot('Position', figPos(2, :), 'Units', 'Normalized');
    snrTmp = snr0;
    snrTmp(snrTmp <= 0) = NaN;
    semilogx(snrTmp, lidarData.height, 'Color', [231, 41, 139]/255, 'LineStyle', '-', 'LineWidth', 2); hold on;

    if ~ isempty(lowSNRInd)
        p1 = plot([1e-10, 1e10], [lidarData.height(lowSNRInd), lidarData.height(lowSNRInd)], 'Color', [177, 89, 41]/255, 'LineStyle', '--', 'LineWidth', 2, 'DisplayName', sprintf('SNR < %4.1f', lidarConfig.detectRangeChkCfg.minSNR(iCh)));
        scatter(snrTmp(lowSNRInd), lidarData.height(lowSNRInd), 10, 'Marker', 'o', 'MarkerEdgeColor', [177, 89, 41]/255, 'MarkerFaceColor', [177, 89, 41]/255);

        legend([p1], 'Location', 'NorthEast');
    end

    xlabel('SNR');
    ylabel('');

    xlim(lidarConfig.detectRangeChkCfg.snrRange(iCh, :));
    ylim(lidarConfig.detectRangeChkCfg.hRange(iCh, :));
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTickLabel', '', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('detection_range_test_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end