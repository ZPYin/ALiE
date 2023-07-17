function [isPassSaturationChk] = saturationChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% SATURATIONCHK saturation check.
%
% USAGE:
%    [isPassSaturationChk] = saturationChk(lidarData, lidarConfig, reportFile, lidarType)
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
%    isPassSaturationChk: logical
%
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

if ~ isfield(lidarConfig.saturationChkCfg, 'transmission')
    transmission = [1, 0.8, 0.5, 0.2, 0.1];
else
    transmission = lidarConfig.saturationChkCfg.transmission;
end

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Saturation Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '\n**%s**\n', lidarConfig.chTag{iCh});
    fprintf(fid, 'Normalization height range: %f - %f m\n', ...
        lidarConfig.saturationChkCfg.normRange(iCh, 1), ...
        lidarConfig.saturationChkCfg.normRange(iCh, 2));

    tRange = NaN(2, length(transmission));
    sigT = NaN(length(transmission), length(lidarData.height));
    sigTSm = NaN(length(transmission), length(lidarData.height));
    sigTNorm = NaN(length(transmission), length(lidarData.height));
    devSig = NaN(length(transmission), length(lidarData.height));
    totDevSig = NaN(1, length(transmission));
    sigArr = NaN(1, length(transmission));
    isPassChk = false(1, length(transmission));

    swBins = ceil(lidarConfig.saturationChkCfg.smoothwindow(iCh) ./ ...
                    (lidarData.height(2) - lidarData.height(1)));
    cmpInd = (lidarData.height >= 500) & (lidarData.height <= 2000);
    normInd = (lidarData.height >= lidarConfig.saturationChkCfg.normRange(iCh, 1)) & ...
              (lidarData.height <= lidarConfig.saturationChkCfg.normRange(iCh, 2));
    for iPrf = 1:length(transmission)

        if ~ isempty(lidarConfig.saturationChkCfg.tRange{iPrf})
            tRange(:, iPrf) = [datenum(lidarConfig.saturationChkCfg.tRange{iPrf}(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
                               datenum(lidarConfig.saturationChkCfg.tRange{iPrf}(23:41), 'yyyy-mm-dd HH:MM:SS')];
            isInTime = (lidarData.mTime >= tRange(1, iPrf)) & (lidarData.mTime <= tRange(2, iPrf));

            fprintf(fid, 'Profiles for %d%%: %d\n', transmission(iPrf) * 100, sum(isInTime));
            sigT(iPrf, :) = nanmean(lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isInTime), 2);
            sigTSm(iPrf, :) = smooth(sigT(iPrf, :), swBins);

            normRatio = nanmean(sigT(1, normInd)) ./ nanmean(sigT(iPrf, normInd));
            sigTNorm(iPrf, :) = sigTSm(iPrf, :) * normRatio;

            % determine deviations
            devSig(iPrf, :) = (sigTNorm(iPrf, :) - sigTNorm(1, :)) ./ sigTNorm(1, :) * 100;
            totDevSig(iPrf) = (nanmean(sigTNorm(iPrf, cmpInd)) - nanmean(sigTNorm(1, cmpInd))) ./ nanmean(sigTNorm(1, cmpInd)) * 100;

            sigArr(iPrf) = nanmean(sigT(iPrf, cmpInd), 2);

            if (iPrf > 1)
                % deviation check
                isPassChk(iPrf) = (abs(totDevSig(iPrf)) < lidarConfig.saturationChkCfg.maxDev(iCh));
                
                fprintf(fid, 'Deviation of %d%%: %f (max: %f)\n', transmission(iPrf) * 100, totDevSig(iPrf), ...
                lidarConfig.saturationChkCfg.maxDev(iCh));
            end
        end
    end

    isPassSaturationChk(iCh) = all(isPassChk);
    fprintf(fid, '\nPass saturation check (1: yes; 0: no): %d\n', ...
        isPassSaturationChk(iCh));
    
    %% signal linearity
    lrSig = fitlm(transmission, sigArr);
    R2Sig = lrSig.Rsquared.Ordinary;
    slopeSig = lrSig.Coefficients.Estimate(2);
    offsetSig = lrSig.Coefficients.Estimate(1);
    fprintf(fid, 'R^2: %5.3f\n', R2Sig);
    isPassLinearityChk = R2Sig > 0.95;
    fprintf(fid, 'Pass linearity check (1: yes; 0: no): %d\n', isPassLinearityChk);

    %% signal visualization

    % signal
    figure('Position', [0, 10, 300, 400], ...
        'Units', 'Pixels', ...
        'Color', 'w', ...
        'Visible', lidarConfig.figVisible);

    lineInstances = [];
    sigTSm(sigTSm <= 0) = NaN;
    sigTTmp = sigTSm(1, :);
    for iPrf = length(transmission):-1:1

        if (iPrf == 1) && any(~ isnan(sigTNorm(1, :)))
            hShaded = patch([(100 - lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * sigTTmp(~ isnan(sigTTmp)); ...
                            (100 + lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * flipud(sigTTmp(~ isnan(sigTTmp)))], ...
                            [transpose(lidarData.height(~ isnan(sigTTmp))); transpose(flipud(lidarData.height(~ isnan(sigTTmp))))], ...
                            [211, 211, 211]/255);
            hold on;
            hShaded.FaceAlpha = 0.6;
            hShaded.EdgeColor = 'None';

            p1 = semilogx(sigTTmp, lidarData.height, ...
                'Color', 'k', ...
                'LineStyle', '-', ...
                'LineWidth', 2, ...
                'DisplayName', sprintf('%d', transmission(iPrf) * 100));
        end

        if (iPrf > 1)
            p1 = semilogx(sigTSm(iPrf, :), lidarData.height, ...
                'LineStyle', '-', ...
                'LineWidth', 2, ...
                'DisplayName', sprintf('%d', transmission(iPrf) * 100)); hold on;
        end

        lineInstances = cat(1, lineInstances, p1);
    end

    xlabel('RCS (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.saturationChkCfg.sigRange(iCh, :));
    ylim(lidarConfig.saturationChkCfg.hRange(iCh, :));
    set(gca, 'XScale', 'log', ...
             'XMinorTick', 'on', ...
             'YMinorTick', 'on', ...
             'Layer', 'Top', ...
             'Box', 'on', ...
             'LineWidth', 2);

    legend(lineInstances, 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
        'Units', 'Normalized', ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'Bold');

    if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
        addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
    end

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_check_signal_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % normalized signal
    figure('Position', [0, 10, 300, 400], ...
           'Units', 'Pixels', ...
           'Color', 'w', ...
           'Visible', lidarConfig.figVisible);

    lineInstances = [];
    sigT(sigT <= 0) = NaN;
    sigTTmp = sigT(1, :);

    for iPrf = length(transmission):-1:1

        if (iPrf == 1) && any(~ isnan(sigTTmp))
            hShaded = patch([(100 - lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * sigTTmp(~ isnan(sigTTmp)); ...
                            (100 + lidarConfig.saturationChkCfg.maxDev(iCh)) / 100 * flipud(sigTTmp(~ isnan(sigTTmp)))], ...
                            [transpose(lidarData.height(~ isnan(sigTTmp))); transpose(flipud(lidarData.height(~ isnan(sigTTmp))))], ...
                            [211, 211, 211]/255);
            hold on;
            hShaded.FaceAlpha = 0.6;
            hShaded.EdgeColor = 'None';

            p1 = semilogx(sigTTmp, lidarData.height, ...
                'Color', 'k', ...
                'LineStyle', '-', ...
                'LineWidth', 2, ...
                'DisplayName', sprintf('%d', transmission(iPrf) * 100));
        end

        if (iPrf > 1)
            p1 = semilogx(sigT(iPrf, :), lidarData.height, ...
                'LineStyle', '-', ...
                'LineWidth', 2, ...
                'DisplayName', sprintf('%d', transmission(iPrf) * 100));
            hold on;
        end

        lineInstances = cat(1, lineInstances, p1);
    end

    xlabel('Normalized signal (a.u.)');
    ylabel('Height (m)');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim(lidarConfig.saturationChkCfg.sigRange(iCh, :));
    ylim(lidarConfig.saturationChkCfg.hRange(iCh, :));
    set(gca, 'XScale', 'log', ...
             'XMinorTick', 'on', ...
             'YMinorTick', 'on', ...
             'Layer', 'Top', ...
             'Box', 'on', ...
             'LineWidth', 2);

    legend(lineInstances, 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
        'Units', 'Normalized', ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'Bold');

    if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
        addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
    end

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_check_norm_signal_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % deviation
    lineInstances = [];
    figure('Position', [0, 10, 300, 400], ...
           'Units', 'Pixels', ...
           'Color', 'w', ...
           'Visible', lidarConfig.figVisible);

    for iPrf = length(transmission):-1:2
        p1 = plot(devSig(iPrf, :), lidarData.height, ...
            'LineStyle', '-', ...
            'LineWidth', 2, ...
            'DisplayName', sprintf('%d', transmission(iPrf) * 100));
        hold on;

        lineInstances = cat(1, lineInstances, p1);
    end

    plot([0, 0], [0, 100000], '--k');
    plot([-1, -1] * lidarConfig.saturationChkCfg.maxDev(iCh), ...
         [0, 100000], '-.', 'Color', [193, 193, 193]/255);
    plot([1, 1] * lidarConfig.saturationChkCfg.maxDev(iCh), ...
         [0, 100000], '-.', 'Color', [193, 193, 193]/255);

    xlabel('Rel. Deviation (%)');
    ylabel('Height (m)');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim([-50, 50]);
    ylim(lidarConfig.saturationChkCfg.hRange(iCh, :));
    set(gca, 'XMinorTick', 'on', ...
             'YMinorTick', 'on', ...
             'Layer', 'Top', ...
             'Box', 'on', ...
             'LineWidth', 2);

    legend(lineInstances, 'Location', 'NorthEast');
    text(0.6, 0.62, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
        'Units', 'Normalized', ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'Bold');

    if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
        addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
    end

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_test_deviation_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    % linearity
    figure('Position', [0, 10, 400, 330], ...
           'Units', 'Pixels', ...
           'Color', 'w', ...
           'Visible', lidarConfig.figVisible);
    p2 = scatter(transmission, sigArr, 'o', ...
        'MarkerFaceColor', [90, 154, 213]/255, ...
        'MarkerEdgeColor', [90, 154, 213]/255);
    hold on;
    p3 = plot([0, 2], [0, 2] * slopeSig + offsetSig, ...
        'Color', [90, 154, 213]/255, ...
        'LineStyle', '--', ...
        'LineWidth', 1);
    grid on;

    xlabel('Transmittance');
    ylabel('Ave. signal');
    title(sprintf('Saturation test for %s, %s', lidarType, lidarConfig.chTag{iCh}));

    xlim([0, 1.2]);
    set(gca, 'XMinorTick', 'on', ...
             'YMinorTick', 'on', ...
             'XTick', sort(transmission), ...
             'Box', 'on', ...
             'LineWidth', 2);
    text(0.1, 0.7, sprintf('y=%4.2fx+%4.2f\nR^2: %4.2f', slopeSig, offsetSig, R2Sig), 'Units', 'Normalized', 'FontSize', 11, 'FontWeight', 'bold', 'Color', 'k');

    text(0, -0.13, sprintf('Version: %s', LEToolboxInfo.programVersion), ...
        'Units', 'Normalized', ...
        'FontSize', 10, ...
        'HorizontalAlignment', 'left', ...
        'FontWeight', 'Bold');

    if (exist(LEToolboxInfo.institute_logo, 'file') == 2) && LEToolboxInfo.flagWaterMark
        addWaterMark(LEToolboxInfo.institute_logo, [0.5, 0.5, 0.6, 0.6]);
    end

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('saturation_test_linearity_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end