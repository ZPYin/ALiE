function [isPassQuadrantChk] = quadrantChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% quadrantChk description
% USAGE:
%    [isPassQuadrantChk] = quadrantChk(lidarData, lidarConfig, reportFile)
% INPUTS:
%    lidarData, lidarConfig, reportFile
% OUTPUTS:
%    isPassQuadrantChk
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

isPassQuadrantChk = false(1, length(lidarConfig.chTag));

if length(lidarConfig.quadrantChkCfg.quadrantTime) ~= 5
    errStruct.message = 'Wrong configuration for quadrantTime.';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Quadrant Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '\n**%s**\n', lidarConfig.chTag{iCh});

    % quadrant time
    east1TRange = [datenum(lidarConfig.quadrantChkCfg.quadrantTime{1}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.quadrantChkCfg.quadrantTime{1}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    southTRange = [datenum(lidarConfig.quadrantChkCfg.quadrantTime{2}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.quadrantChkCfg.quadrantTime{2}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    westTRange = [datenum(lidarConfig.quadrantChkCfg.quadrantTime{3}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.quadrantChkCfg.quadrantTime{3}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    northTRange = [datenum(lidarConfig.quadrantChkCfg.quadrantTime{4}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.quadrantChkCfg.quadrantTime{4}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    east2TRange = [datenum(lidarConfig.quadrantChkCfg.quadrantTime{5}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.quadrantChkCfg.quadrantTime{5}(23:41), 'yyyy-mm-dd HH:MM:SS')];

    % quadrant index
    isEast1 = (lidarData.mTime >= east1TRange(1)) & (lidarData.mTime <= east1TRange(2));
    isSouth = (lidarData.mTime >= southTRange(1)) & (lidarData.mTime <= southTRange(2));
    isWest = (lidarData.mTime >= westTRange(1)) & (lidarData.mTime <= westTRange(2));
    isNorth = (lidarData.mTime >= northTRange(1)) & (lidarData.mTime <= northTRange(2));
    isEast2 = (lidarData.mTime >= east2TRange(1)) & (lidarData.mTime <= east2TRange(2));
    fprintf(fid, 'Profiles for east1: %d\n', sum(isEast1));
    fprintf(fid, 'Profiles for south: %d\n', sum(isSouth));
    fprintf(fid, 'Profiles for west: %d\n', sum(isWest));
    fprintf(fid, 'Profiles for north: %d\n', sum(isNorth));
    fprintf(fid, 'Profiles for east2: %d\n', sum(isEast2));

    if (~ any(isEast1)) || (~ any(isSouth)) || (~ any(isWest)) || (~ any(isNorth)) || (~ any(isEast2))
        warning('Wrong telecover test!!!');
        continue;
    end

    % load signal
    sigEast1 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isEast1), 2);
    sigSouth = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isSouth), 2);
    sigWest = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isWest), 2);
    sigNorth = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isNorth), 2);
    sigEast2 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isEast2), 2);
    totalSig = (sigEast1 + sigSouth + sigWest + sigNorth);

    % normalize signal
    fprintf(fid, 'Normalization height range: %f - %f m\n', lidarConfig.quadrantChkCfg.normRange(1), lidarConfig.quadrantChkCfg.normRange(2));
    normInd = (lidarData.height >= lidarConfig.quadrantChkCfg.normRange(1)) & (lidarData.height <= lidarConfig.quadrantChkCfg.normRange(2));
    normRatioEast1 = nansum(totalSig(normInd)) ./ nansum(sigEast1(normInd));
    normRatioSouth = nansum(totalSig(normInd)) ./ nansum(sigSouth(normInd));
    normRatioWest = nansum(totalSig(normInd)) ./ nansum(sigWest(normInd));
    normRatioNorth = nansum(totalSig(normInd)) ./ nansum(sigNorth(normInd));
    normRatioEast2 = nansum(totalSig(normInd)) ./ nansum(sigEast2(normInd));
    sigEast1Norm = sigEast1 .* normRatioEast1;
    sigSouthNorm = sigSouth .* normRatioSouth;
    sigWestNorm = sigWest .* normRatioWest;
    sigNorthNorm = sigNorth .* normRatioNorth;
    sigEast2Norm = sigEast2 .* normRatioEast2;

    %% determine deviations

    % stability check
    swBins = ceil(lidarConfig.quadrantChkCfg.smoothwindow ./ (lidarData.height(2) - lidarData.height(1)));
    cmpInd = (lidarData.height >= 2000) & (lidarData.height <= 4000);
    % devEast1v2 = smooth(sigEast2Norm - sigEast1Norm, swBins) ./ smooth(sigEast1, swBins) * 100;   % (%)
    totalDevEast1v2 = nanmean(sigEast2Norm(cmpInd) - sigEast1Norm(cmpInd)) ./ nanmean(sigEast1Norm(cmpInd)) * 100;

    % quadrant deviations
    devEast1 = smooth(sigEast1Norm - totalSig, swBins) ./ smooth(totalSig, swBins) * 100;
    totalDevEast1 = nanmean(sigEast1Norm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;
    devSouth = smooth(sigSouthNorm - totalSig, swBins) ./ smooth(totalSig, swBins) * 100;
    totalDevSouth = nanmean(sigSouthNorm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;
    devWest = smooth(sigWestNorm - totalSig, swBins) ./ smooth(totalSig, swBins) * 100;
    totalDevWest = nanmean(sigEast1Norm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;
    devNorth = smooth(sigNorthNorm - totalSig, swBins) ./ smooth(totalSig, swBins) * 100;
    totalDevNorth = nanmean(sigNorthNorm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;

    % deviation check
    isStable = (abs(totalDevEast1v2) < lidarConfig.quadrantChkCfg.stableThresh);
    isPassChkEast1 = (abs(totalDevEast1) < lidarConfig.quadrantChkCfg.maxDev);
    isPassChkSouth = (abs(totalDevSouth) < lidarConfig.quadrantChkCfg.maxDev);
    isPassChkWest = (abs(totalDevWest) < lidarConfig.quadrantChkCfg.maxDev);
    isPassChkNorth = (abs(totalDevNorth) < lidarConfig.quadrantChkCfg.maxDev);
    isPassQuadrantChk(iCh) = ((isPassChkEast1 + isPassChkSouth + isPassChkWest + isPassChkNorth) >= 3) && isStable;

    fprintf(fid, 'Deviation between East1 and East2: %f (max: %f)\n', totalDevEast1v2, lidarConfig.quadrantChkCfg.stableThresh);
    fprintf(fid, 'Deviation of East: %f (max: %f)\n', totalDevEast1, lidarConfig.quadrantChkCfg.maxDev);
    fprintf(fid, 'Deviation of South: %f (max: %f)\n', totalDevSouth, lidarConfig.quadrantChkCfg.maxDev);
    fprintf(fid, 'Deviation of West: %f (max: %f)\n', totalDevWest, lidarConfig.quadrantChkCfg.maxDev);
    fprintf(fid, 'Deviation of North: %f (max: %f)\n', totalDevNorth, lidarConfig.quadrantChkCfg.maxDev);
    fprintf(fid, '\nPass quadrant check (1: yes; 0: no): %d\n', isPassQuadrantChk(iCh));

    %% signal visualization

    % normalized signal (near)
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    pTotal = plot(totalSig, lidarData.height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'Total'); hold on;
    pEast1 = plot(sigEast1Norm, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'East1');
    pSouth = plot(sigSouthNorm, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'South');
    pWest = plot(sigWestNorm, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'West');
    pNorth = plot(sigNorthNorm, lidarData.height, 'Color', [165, 118, 30]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'North');
    pEast2 = plot(sigEast2Norm, lidarData.height, 'Color', [254, 191, 111]/255, 'LineStyle', '--', 'LineWidth', 2, 'DisplayName', 'East2');

    xlabel('Normalized signal (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Telecover test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.quadrantChkCfg.normSigDisplayRangeNear);
    ylim(lidarConfig.quadrantChkCfg.hRangeNear);
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([pTotal, pEast1, pSouth, pWest, pNorth, pEast2], 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('telecover_test_signal_near_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % normalized signal (all)
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    pTotal = plot(totalSig, lidarData.height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'Total'); hold on;
    pEast1 = plot(sigEast1Norm, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'East1');
    pSouth = plot(sigSouthNorm, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'South');
    pWest = plot(sigWestNorm, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'West');
    pNorth = plot(sigNorthNorm, lidarData.height, 'Color', [165, 118, 30]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'North');
    pEast2 = plot(sigEast2Norm, lidarData.height, 'Color', [254, 191, 111]/255, 'LineStyle', '--', 'LineWidth', 2, 'DisplayName', 'East2');

    xlabel('Normalized signal (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Telecover test (%s, %s)', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.quadrantChkCfg.normSigDisplayRangeAll);
    ylim(lidarConfig.quadrantChkCfg.hRangeAll);
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([pTotal, pEast1, pSouth, pWest, pNorth, pEast2], 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('telecover_test_signal_full_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % deviation
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    pEast1 = plot(devEast1, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'East1'); hold on;
    pSouth = plot(devSouth, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'South');
    pWest = plot(devWest, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'West');
    pNorth = plot(devNorth, lidarData.height, 'Color', [165, 118, 30]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'North');

    plot([0, 0], [0, 100000], '--k');
    plot([-10, 10], [0, 100000], '-.', 'Color', [193, 193, 193]/255);
    plot([10, 10], [0, 100000], '-.', 'Color', [193, 193, 193]/255);

    xlabel('Rel. Deviation');
    ylabel('Height (m)');
    title(sprintf('Telecover test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim([-50, 50]);
    ylim(lidarConfig.quadrantChkCfg.hRangeNear);
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([pEast1, pSouth, pWest, pNorth], 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('telecover_test_deviation_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end