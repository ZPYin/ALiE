function [isPassBgNoiseChk] = bgNoiseChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% bgNoiseChk description
% USAGE:
%    [isPassBgNoiseChk] = bgNoiseChk(lidarData, lidarConfig, reportFile)
% INPUTS:
%    lidarData, lidarConfig, reportFile
% OUTPUTS:
%    isPassBgNoiseChk
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

isPassBgNoiseChk = false(1, length(lidarConfig.chTag));

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Background Noise Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '\n**%s**\n', lidarConfig.chTag{iCh});

    % slot for detection range check
    tRange = [datenum(lidarConfig.bgNoiseChkCfg.closeTRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.bgNoiseChkCfg.closeTRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
    isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
    if sum(isChosen) <= 0
        warning('Insufficient profiles were chosen!');
        continue;
    end

    % backgroud
    bg = nanmean(lidarData.(['sig', lidarConfig.chTag{iCh}])(:, isChosen), 2) + nanmean(lidarData.(['bg', lidarConfig.chTag{iCh}])(isChosen));
    bgMean = nanmean(bg);
    bgMeanBound = [0.9 * bgMean, 1.1 * bgMean];

    % random noise
    winLen = round(lidarConfig.bgNoiseChkCfg.randErrCalcWindowLength ./ (lidarData.height(2) - lidarData.height(1)));
    randNoise = 0;
    for iW = 1:floor(length(lidarData.height) / winLen)
        randNoise = randNoise + nanvar(bg(((iW - 1) * winLen + 1):(iW*winLen)));
    end
    randNoise = sqrt(randNoise) / sqrt(floor(length(lidarData.height) / winLen));

    % systematic error
    sysNoise = nanstd(bg);

    fprintf(fid, 'Random noise: %f\n', randNoise);
    fprintf(fid, 'Systematic noise: %f\n', sysNoise);
    isPassBgNoiseChk(iCh) = (randNoise >= sysNoise);
    fprintf(fid, '\nPass background noise check (1: yes; 0: no): %d\n', isPassBgNoiseChk(iCh));

    %% signal visualization
    figure('Position', [0, 10, 550, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

    plot(lidarData.height, bg, 'Color', [0, 128, 1]/255, 'LineStyle', '-', 'LineWidth', 2); hold on;
    plot([0, 100000], [bgMean, bgMean], '-.', 'Color', [122, 122, 122]/255);
    plot([0, 100000], [bgMeanBound(1), bgMeanBound(1)], '--', 'Color', [211, 211, 211]/255);
    plot([0, 100000], [bgMeanBound(2), bgMeanBound(2)], '--', 'Color', [211, 211, 211]/255);

    ylabel('Background (a.u.)');
    xlabel('Height (m)');
    title(sprintf('Background noise test (%s, %s)', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.bgNoiseChkCfg.hRange(iCh, :));
    ylim(lidarConfig.bgNoiseChkCfg.bgRange(iCh, :));
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('background_noise_test_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end