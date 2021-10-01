function [isPassContOptChk] = contOptChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% CONTOPTCHK continuous operation check
% USAGE:
%    [isPasscontOptChk] = contOptChk(lidarData, lidarConfig, reportFile, lidarType)
% INPUTS:
%    lidarData: struct
%    lidarConfig: struct
%    reportFile: char
%    lidarType: char
% KEYWORDS:
%    figFolder: char
%    figFormat: char
%    flagCorTime: logical
% OUTPUTS:
%    isPasscontOptChk: logical
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
addParameter(p, 'flagCorTime', true, @islogical);

parse(p, lidarData, lidarConfig, reportFile, lidarType, varargin{:});

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Continuous Operation Check\n');

% slot for continuous check
tRange = [datenum(lidarConfig.contOptChkCfg.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
          datenum(lidarConfig.contOptChkCfg.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];

% continuous operation check
isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
fprintf(fid, 'Profiles for continuous operation check: %d (min: %d)\n', ...
    sum(isChosen), lidarConfig.contOptChkCfg.nMinProfile);
isPassContOptChk = (sum(isChosen) >= lidarConfig.contOptChkCfg.nMinProfile);
fprintf(fid, '\nPass continuous operation check (1: yes; 0: no): %d\n', isPassContOptChk);

tRangeMark = [];
if isfield(lidarConfig.contOptChkCfg, 'markTRange')
    if ~ isempty(lidarConfig.contOptChkCfg.markTRange)
        tRangeMark = [datenum(lidarConfig.contOptChkCfg.markTRange(1:19), 'yyyy-mm-dd HH:MM:SS'), ...
                      datenum(lidarConfig.contOptChkCfg.markTRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
    end
end

for iCh = 1:length(lidarConfig.chTag)

    if sum(isChosen) <= 1
        warning('Insufficient profiles were chosen!');
        continue;
    end

    sig = lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isChosen);
    height = lidarData.height;
    mTime = lidarData.mTime(isChosen);
    mTime = sort(mTime);
    deltaT = datenum(0, 1, 0, 0, lidarConfig.contOptChkCfg.deltaT, 0);

    % signal regrid
    mTimeGrid = (mTime(1):deltaT:mTime(end));
    heightGrid = height;
    sigGrid = NaN(length(heightGrid), length(mTimeGrid));
    tIndGrid = ones(size(mTime));
    if p.Results.flagCorTime
        % correct time drift
        mTimeGrid(1) = mTime(1);
        sigGrid(:, 1) = sig(:, 1);
        tIndGrid(1) = 1;
        for iT = 2:length(mTime)
            tInd = floor((mTime(iT) - mTime(iT - 1) + 1e-9 + 0.1 * deltaT) / deltaT) + tIndGrid(iT - 1);
            if tInd > length(mTimeGrid)
                continue;
            end
            tIndGrid(iT) = tInd;
            sigGrid(:, tInd) = sig(:, iT); 
        end
    else
        for iT = 1:length(mTime)
            sigGrid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = sig(:, iT);
        end
    end

    %% signal visualization
    figure('Position', [0, 10, 600, 300], ...
           'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

    subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
    p1 = pcolor(mTimeGrid, heightGrid, sigGrid);
    p1.EdgeColor = 'None';
    if ~ isempty(tRangeMark)
        rectangle('Position', [tRangeMark(1), lidarConfig.contOptChkCfg.hRange(1, 1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.contOptChkCfg.hRange(1, 2) - lidarConfig.contOptChkCfg.hRange(1, 1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
    end

    xlabel('Local Time');
    ylabel('Height (m)');
    title(sprintf('Continuous operation (%s, %s)', lidarType, lidarConfig.chTag{iCh}));

    xlim([tRange(1), tRange(2)]);
    ylim(lidarConfig.contOptChkCfg.hRange);
    caxis(lidarConfig.contOptChkCfg.cRange(iCh, :));
    colormap('jet');

    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(tRange(1), tRange(2), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
    ax = gca;
    ax.XAxis.MinorTickValues = linspace(tRange(1), tRange(2), 25);

    datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
    colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

    text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

    if exist(p.Results.figFolder, 'dir')
        export_fig(gcf, fullfile(p.Results.figFolder, sprintf('continuous_operation_%s_%s.%s', lidarType, lidarConfig.chTag{iCh}, p.Results.figFormat)), '-r300');
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

fclose(fid);

end