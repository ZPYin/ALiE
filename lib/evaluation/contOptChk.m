function [isPassContOptChk] = contOptChk(lidarData, lidarConfig, reportFile, lidarType, varargin)
% contOptChk description
% USAGE:
%    [isPasscontOptChk] = contOptChk(lidarData, lidarConfig, reportFile)
% INPUTS:
%    lidarData, lidarConfig, reportFile
% OUTPUTS:
%    isPasscontOptChk
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

fid = fopen(reportFile, 'a');
fprintf(fid, '\n## Continuous Operation Check\n');

% slot for continuous check
tRange = [datenum(lidarConfig.contOptChk.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.contOptChk.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];

% continuous operation check
isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
fprintf(fid, 'Profiles for continuous operation check: %d (min: %d)\n', sum(isChosen), lidarConfig.contOptChk.nMinProfile);
isPassContOptChk = (sum(isChosen) >= lidarConfig.contOptChk.nMinProfile);
fprintf(fid, '\nPass continuous operation check (1: yes; 0: no): %d\n', isPassContOptChk);

for iCh = 1:length(lidarConfig.chTag)

    if sum(isChosen) <= 1
        warning('Insufficient profiles were chosen!');
        continue;
    end

    sig = lidarData.(['rcs', lidarConfig.chTag{iCh}])(:, isChosen);
    height = lidarData.height;
    mTime = lidarData.mTime(isChosen);
    deltaT = datenum(0, 1, 0, 0, lidarConfig.contOptChk.deltaT, 0);

    % signal regrid
    mTimeGrid = (mTime(1):deltaT:mTime(end));
    heightGrid = height;
    sigGrid = NaN(length(heightGrid), length(mTimeGrid));
    for iT = 1:length(mTime)
        sigGrid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = sig(:, iT);
    end

    %% signal visualization
    figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

    subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
    p1 = pcolor(mTimeGrid, heightGrid, sigGrid);
    p1.EdgeColor = 'None';

    xlabel('Local Time');
    ylabel('Height (m)');
    title(sprintf('Continuous operation (%s, %s)', lidarType, lidarConfig.chTag{iCh}));

    xlim([mTimeGrid(1), mTimeGrid(end)]);
    ylim(lidarConfig.contOptChk.hRange);
    caxis(lidarConfig.contOptChk.cRange(iCh, :));
    colormap('jet');

    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
    ax = gca;
    ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

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