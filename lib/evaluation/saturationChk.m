function [isPassSaturationChk] = saturationChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% SATURATIONCHK saturation check.
% USAGE:
%    [isPassSaturationChk] = saturationChk(lidarData, lidarConfig, reportFile, lidarType)
% INPUTS:
%    lidarData: struct
%    lidarConfig: struct
%    reportFile: char
%    lidarType: char
% KEYWORDS:
%    figFolder: char
%    figFormat: char
% OUTPUTS:
%    isPassSaturationChk: logical
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

isPassSaturationChk = false(1, length(lidarConfig.chTag));

if length(lidarConfig.saturationChkCfg.tRange) ~= 5
    errStruct.message = 'Wrong configuration for tRange.';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Saturation Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '\n**%s**\n', lidarConfig.chTag{iCh});

    % tRange
    if ~ isempty(lidarConfig.saturationChkCfg.tRange)
        tRange1 = [datenum(lidarConfig.saturationChkCfg.tRange{1}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.saturationChkCfg.tRange{1}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    else
        tRange1 = [];
    end
    if ~ isempty(lidarConfig.saturationChkCfg.tRange)
        tRange2 = [datenum(lidarConfig.saturationChkCfg.tRange{2}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.saturationChkCfg.tRange{2}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    else
        tRange2 = [];
    end
    if ~ isempty(lidarConfig.saturationChkCfg.tRange)
        tRange3 = [datenum(lidarConfig.saturationChkCfg.tRange{3}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.saturationChkCfg.tRange{3}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    else
        tRange3 = [];
    end
    if ~ isempty(lidarConfig.saturationChkCfg.tRange)
        tRange4 = [datenum(lidarConfig.saturationChkCfg.tRange{4}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.saturationChkCfg.tRange{4}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    else
        tRange4 = [];
    end
    if ~ isempty(lidarConfig.saturationChkCfg.tRange)
        tRange5 = [datenum(lidarConfig.saturationChkCfg.tRange{5}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.saturationChkCfg.tRange{5}(23:41), 'yyyy-mm-dd HH:MM:SS')];
    else
        tRange5 = [];
    end

    % load signal
    if ~ isempty(tRange1)
        isT1 = (lidarData.mTime >= tRange1(1)) & (lidarData.mTime <= tRange1(2));
        fprintf(fid, 'Profiles for 100%%: %d\n', sum(isT1));
        sigT1 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isT1), 2);
    else
        sigT1 = NaN(size(lidarData.height));
    end
    if ~ isempty(tRange2)
        isT2 = (lidarData.mTime >= tRange2(1)) & (lidarData.mTime <= tRange2(2));
        fprintf(fid, 'Profiles for 80%%: %d\n', sum(isT2));
        sigT2 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isT2), 2);
    else
        sigT2 = NaN(size(lidarData.height));
    end
    if ~ isempty(tRange3)
        isT3 = (lidarData.mTime >= tRange3(1)) & (lidarData.mTime <= tRange3(2));
        fprintf(fid, 'Profiles for 50%%: %d\n', sum(isT3));
        sigT3 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isT3), 2);
    else
        sigT3 = NaN(size(lidarData.height));
    end
    if ~ isempty(tRange4)
        isT4 = (lidarData.mTime >= tRange4(1)) & (lidarData.mTime <= tRange4(2));
        fprintf(fid, 'Profiles for 20%%: %d\n', sum(isT4));
        sigT4 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isT4), 2);
    else
        sigT4 = NaN(size(lidarData.height));
    end
    if ~ isempty(tRange5)
        isT5 = (lidarData.mTime >= tRange5(1)) & (lidarData.mTime <= tRange5(2));
        fprintf(fid, 'Profiles for 10%%: %d\n', sum(isT5));
        sigT5 = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isT5), 2);
    else
        sigT5 = NaN(size(lidarData.height));
    end

    swBins = ceil(lidarConfig.saturationChkCfg.smoothwindow(iCh) ./ (lidarData.height(2) - lidarData.height(1)));
    % normalize signal
    fprintf(fid, 'Normalization height range: %f - %f m\n', lidarConfig.saturationChkCfg.normRange(iCh, 1), lidarConfig.saturationChkCfg.normRange(iCh, 2));
    normInd = (lidarData.height >= lidarConfig.saturationChkCfg.normRange(iCh, 1)) & (lidarData.height <= lidarConfig.saturationChkCfg.normRange(iCh, 2));
    normRatio2 = nansum(sigT1(normInd)) ./ nansum(sigT2(normInd));
    normRatio3 = nansum(sigT1(normInd)) ./ nansum(sigT3(normInd));
    normRatio4 = nansum(sigT1(normInd)) ./ nansum(sigT4(normInd));
    normRatio5 = nansum(sigT1(normInd)) ./ nansum(sigT5(normInd));
    sigT1Sm = smooth(sigT1, swBins);
    sigT2Sm = smooth(sigT2, swBins);
    sigT3Sm = smooth(sigT3, swBins);
    sigT4Sm = smooth(sigT4, swBins);
    sigT5Sm = smooth(sigT5, swBins);
    sigT2Norm = sigT2Sm * normRatio2;
    sigT3Norm = sigT3Sm * normRatio3;
    sigT4Norm = sigT4Sm * normRatio4;
    sigT5Norm = sigT5Sm * normRatio5;

    %% determine deviations
    cmpInd = (lidarData.height >= lidarConfig.saturationChkCfg.normRange(iCh, 1)) & (lidarData.height <= lidarConfig.saturationChkCfg.normRange(iCh, 2));
    dev2 = (sigT2Norm - sigT1Sm) ./ sigT1Sm * 100;
    totDev2 = nanmean(abs(sigT2Norm(cmpInd) - sigT1Sm(cmpInd)) ./ sigT1Sm(cmpInd)) * 100;
    dev3 = (sigT3Norm - sigT1Sm) ./ sigT1Sm * 100;
    totDev3 = nanmean(abs(sigT3Norm(cmpInd) - sigT1Sm(cmpInd)) ./ sigT1Sm(cmpInd)) * 100;
    dev4 = (sigT4Norm - sigT1Sm) ./ sigT1Sm * 100;
    totDev4 = nanmean(abs(sigT4Norm(cmpInd) - sigT1Sm(cmpInd)) ./ sigT1Sm(cmpInd)) * 100;
    dev5 = (sigT5Norm - sigT1Sm) ./ sigT1Sm * 100;
    totDev5 = nanmean(abs(sigT5Norm(cmpInd) - sigT1Sm(cmpInd)) ./ sigT1Sm(cmpInd)) * 100;

    % deviation check
    isPassChk2 = (abs(totDev2) < lidarConfig.saturationChkCfg.maxDev(iCh));
    isPassChk3 = (abs(totDev3) < lidarConfig.saturationChkCfg.maxDev(iCh));
    isPassChk4 = (abs(totDev4) < lidarConfig.saturationChkCfg.maxDev(iCh));
    isPassChk5 = (abs(totDev5) < lidarConfig.saturationChkCfg.maxDev(iCh));
    isPassSaturationChk(iCh) = isPassChk2 && isPassChk3 && isPassChk4 && isPassChk5;

    fprintf(fid, 'Deviation of 80%%: %f (max: %f)\n', totDev2, lidarConfig.saturationChkCfg.maxDev(iCh));
    fprintf(fid, 'Deviation of 50%%: %f (max: %f)\n', totDev3, lidarConfig.saturationChkCfg.maxDev(iCh));
    fprintf(fid, 'Deviation of 20%%: %f (max: %f)\n', totDev4, lidarConfig.saturationChkCfg.maxDev(iCh));
    fprintf(fid, 'Deviation of 10%%: %f (max: %f)\n', totDev5, lidarConfig.saturationChkCfg.maxDev(iCh));
    fprintf(fid, '\nPass saturation check (1: yes; 0: no): %d\n', isPassSaturationChk(iCh));

    %% signal visualization

    % signal
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    sigT1Tmp = sigT1Sm;
    sigT1Tmp(sigT1Tmp <= 0) = NaN;
    sigT2Tmp = sigT2Sm;
    sigT2Tmp(sigT2Tmp <= 0) = NaN;
    sigT3Tmp = sigT3Sm;
    sigT3Tmp(sigT3Tmp <= 0) = NaN;
    sigT4Tmp = sigT4Sm;
    sigT4Tmp(sigT4Tmp <= 0) = NaN;
    sigT5Tmp = sigT5Sm;
    sigT5Tmp(sigT5Tmp <= 0) = NaN;
    if any(~ isnan(sigT1Tmp))
        hShaded = patch([(100 - lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * sigT1Tmp(~ isnan(sigT1Tmp)); (100 + lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * flipud(sigT1Tmp(~ isnan(sigT1Tmp)))], [lidarData.height(~ isnan(sigT1Tmp)); flipud(lidarData.height(~ isnan(sigT1Tmp)))], [211, 211, 211]/255); hold on;
        hShaded.FaceAlpha = 0.6;
        hShaded.EdgeColor = 'None';
    end
    p2 = semilogx(sigT2Tmp, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '80'); hold on;
    p3 = semilogx(sigT3Tmp, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '50');
    p4 = semilogx(sigT4Tmp, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '20');
    p5 = semilogx(sigT5Tmp, lidarData.height, 'Color', [165, 118, 30]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '10');
    p1 = semilogx(sigT1Tmp, lidarData.height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '100'); hold on;

    xlabel('RCS (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.saturationChkCfg.sigRange(iCh, :));
    ylim(lidarConfig.saturationChkCfg.hRange(iCh, :));
    set(gca, 'XScale', 'log', 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([p1, p2, p3, p4, p5], 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_check_signal_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % normalized signal
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    sigT1Tmp = sigT1;
    sigT1Tmp(sigT1Tmp <= 0) = NaN;
    sigT2Tmp = sigT2Norm;
    sigT2Tmp(sigT2Tmp <= 0) = NaN;
    sigT3Tmp = sigT3Norm;
    sigT3Tmp(sigT3Tmp <= 0) = NaN;
    sigT4Tmp = sigT4Norm;
    sigT4Tmp(sigT4Tmp <= 0) = NaN;
    sigT5Tmp = sigT5Norm;
    sigT5Tmp(sigT5Tmp <= 0) = NaN;
    if any(~ isnan(sigT1Tmp))
        hShaded = patch([(100 - lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * sigT1Tmp(~ isnan(sigT1Tmp)); (100 + lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * flipud(sigT1Tmp(~ isnan(sigT1Tmp)))], [lidarData.height(~ isnan(sigT1Tmp)); flipud(lidarData.height(~ isnan(sigT1Tmp)))], [211, 211, 211]/255); hold on;
        hShaded.FaceAlpha = 0.6;
        hShaded.EdgeColor = 'None';
    end
    p2 = semilogx(sigT2Tmp, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '80'); hold on;
    p3 = semilogx(sigT3Tmp, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '50');
    p4 = semilogx(sigT4Tmp, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '20');
    p5 = semilogx(sigT5Tmp, lidarData.height, 'Color', [165, 118, 30]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '10');
    p1 = semilogx(sigT1Tmp, lidarData.height, 'Color', 'k', 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '100'); hold on;

    xlabel('Normalized signal (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.saturationChkCfg.sigRange(iCh, :));
    ylim(lidarConfig.saturationChkCfg.hRange(iCh, :));
    set(gca, 'XScale', 'log', 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([p1, p2, p3, p4, p5], 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_check_norm_signal_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % deviation
    figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);
    p2 = plot(dev2, lidarData.height, 'Color', [106, 142, 34]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '80'); hold on;
    p3 = plot(dev3, lidarData.height, 'Color', [0, 191, 254]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '50');
    p4 = plot(dev4, lidarData.height, 'Color', [230, 216, 189]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '20');
    p5 = plot(dev5, lidarData.height, 'Color', [165, 118, 30]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '10');

    plot([0, 0], [0, 100000], '--k');
    plot([-1, -1] * lidarConfig.saturationChkCfg.maxDev(iCh), [0, 100000], '-.', 'Color', [193, 193, 193]/255);
    plot([1, 1] * lidarConfig.saturationChkCfg.maxDev(iCh), [0, 100000], '-.', 'Color', [193, 193, 193]/255);

    xlabel('Rel. Deviation (%)');
    ylabel('Height (m)');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim([-50, 50]);
    ylim(lidarConfig.saturationChkCfg.hRange(iCh, :));
    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

    legend([p2, p3, p4, p5], 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_test_deviation_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end