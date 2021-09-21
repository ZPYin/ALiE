function [isPassQuadrantChk] = quadrantChk(lidarData, lidarConfig, reportFile, varargin)
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

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'lidarData', @isstruct);
addRequired(p, 'lidarConfig', @isstruct);
addRequired(p, 'reportFile', @ischar);

parse(p, lidarData, lidarConfig, reportFile, varargin{:});

isPassQuadrantChk = false(1, length(lidarConfig.chTag));

if length(lidarConfig.quadrantChk.quadrantTime) ~= 5
    errStruct.message = 'Wrong configuration for quadrantTime.';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

fid = fopen(reportFile, 'a');
fprintf(fid, '## Quadrant Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '**%s**\n', lidarConfig.chTag{iCh});

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
    fprintf(fid, 'Profiles for east1: %d\n', sum(isWest)); 
    fprintf(fid, 'Profiles for east1: %d\n', sum(isNorth)); 
    fprintf(fid, 'Profiles for east1: %d\n', sum(isEast2)); 

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
    devEast1v2 = smooth(sigEast2Norm - sigEast1Norm, swBins) ./ smooth(sigEast1, swBins) * 100;   % (%)
    totalDevEast1v2 = nanmean(sigEast2Norm(cmpInd) - sigEast1Norm(cmpInd)) ./ nanmean(sigEast1Norm(cmpInd)) * 100;

    % quadrant deviations
    devEast1 = smooth(sigEast1Norm - totalSig, swBins) ./ smooth(totalSig, swBins) * 199;
    totalDevEast1 = nanmean(sigEast1Norm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;
    devSouth = smooth(sigSouthNorm - totalSig, swBins) ./ smooth(totalSig, swBins) * 199;
    totalDevSouth = nanmean(sigSouthNorm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;
    devWest = smooth(sigEast1Norm - totalSig, swBins) ./ smooth(totalSig, swBins) * 199;
    totalDevWest = nanmean(sigEast1Norm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;
    devNorth = smooth(sigNorthNorm - totalSig, swBins) ./ smooth(totalSig, swBins) * 199;
    totalDevNorth = nanmean(sigNorthNorm(cmpInd) - totalSig(cmpInd)) ./ nanmean(totalSig(cmpInd)) * 100;

    % deviation check
    isStable = (totalDevEast1v2 < lidarConfig.quadrantChkCfg.stableThresh);
    isPassChkEast1 = (totalDevEast1 < lidarConfig.quadrantChkCfg.maxDev);
    isPassChkSouth = (totalDevSouth < lidarConfig.quadrantChkCfg.maxDev);
    isPassChkWest = (totalDevWest < lidarConfig.quadrantChkCfg.maxDev);
    isPassChkNorth = (totalDevNorth < lidarConfig.quadrantChkCfg.maxDev);
    isPassQuadrantChk(iCh) = ((isPassChkEast1 + isPassChkSouth + isPassChkWest + isPassChkNorth) >= 3) && isStable;

    fprintf(fid, 'Deviation between East1 and East2: %f\n', totalDevEast1v2);
    fprintf(fid, 'Deviation of East: %f\n', totalDevEast1);
    fprintf(fid, 'Deviation of South: %f\n', totalDevSouth);
    fprintf(fid, 'Deviation of West: %f\n', totalDevWest);
    fprintf(fid, 'Deviation of North: %f\n', totalDevNorth);
    fprintf(fid, 'Pass quadrant check (1: yes; 0: no): %d\n', isPassQuadrantChk(iCh));

    %% signal visualization

    % normalized signal (all)
    figure('Position', [0, 10, 400, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    pTotal = plot(totalSig, lidarData.height, 'Color', [140, 140, 140]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'Total'); hold on;
    pEast1 = plot(sigEast1Norm, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'East1');
    pSouth = plot(sigSouthNorm, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'South');
    pWest = plot(sigWestNorm, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', 'West');
    pEast2 = plot(sigEast2Norm, lidarData.height, 'Color', [254, 191, 111]/255, 'LineStyle', '--', 'LineWidth', 2, 'DisplayName', 'East2');

    xlabel('Normalized signal (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Telecover test for %s, %s', lidarConfig))

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end