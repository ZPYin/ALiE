function displayQL(configFile, varargin)
% displayQL description
% USAGE:
%    [output] = displayQL(params)
% INPUTS:
%    params
% OUTPUTS:
%    output
% EXAMPLE:
% HISTORY:
%    2021-09-22: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

global LEToolboxInfo

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'configFile', @ischar);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, configFile, varargin{:});

%% read configuration
fprintf('[%s] Start reading configurations for showing quicklook!\n', tNow);
fprintf('[%s] Config file: %s\n', tNow, configFile);
config = yaml.ReadYaml(configFile, 0, 1);
fprintf('[%s] Finish!\n', tNow);

%% log output
logFile = fullfile(config.evaluationReportPath, 'lidar_displayQL.log');
diaryon(logFile);

lidarType = fieldnames(config.dataVisualCfg);
for iLidar = 1:length(lidarType)

    lidarConfig = config.dataVisualCfg.(lidarType{iLidar});

    % prepare output folder
    if ~ exist(config.dataSavePath, 'dir')
        fprintf('[%s] Create path for saving data!\n', tNow);
        mkdir(config.dataSavePath);
        fprintf('[%s] Data folder: %s\n', tNow, config.dataSavePath);
    end

    fprintf('[%s] Quicklook for %s\n', tNow, lidarType{iLidar});

    % check lidar data file
    h5Filename = fullfile(config.dataSavePath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    if exist(h5Filename, 'file') ~= 2
        warning('No lidar data for %s', lidarType{iLidar});
        continue;
    end

    %% read lidar data
    lidarData = struct();
    lidarData.mTime = unix_timestamp_2_datenum(h5read(h5Filename, '/time'));
    lidarData.height = h5read(h5Filename, '/height');
    for iCh = 1:length(lidarConfig.chTag)
        if p.Results.flagDebug
            fprintf('Reading lidar data of %s\n', lidarConfig.chTag{iCh});
        end

        lidarData.(['sig', lidarConfig.chTag{iCh}]) = h5read(h5Filename, sprintf('/sig%s', lidarConfig.chTag{iCh}));
    end

    %% pre-process
    lidarData = lidarPreprocess(lidarData, lidarConfig.chTag, ...
        'deadtime', lidarConfig.preprocessCfg.deadTime, ...
        'bgBins', lidarConfig.preprocessCfg.bgBins, ...
        'nPretrigger', lidarConfig.preprocessCfg.nPretrigger, ...
        'bgCorFile', lidarConfig.preprocessCfg.bgCorFile, ...
        'lidarNo', lidarConfig.lidarNo, ...
        'flagDebug', p.Results.flagDebug, ...
        'tOffset', datenum(0, 1, 0, 0, lidarConfig.preprocessCfg.tOffset, 0), ...
        'hOffset', lidarConfig.preprocessCfg.hOffset, ...
        'overlapFile', lidarConfig.preprocessCfg.overlapFile);

    switch lidarConfig.lidarNo
    case 12

        % slot for continuous check
        tRange = [datenum(lidarConfig.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        tRangeMark = [datenum(lidarConfig.markTRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.markTRange(23:41), 'yyyy-mm-dd HH:MM:SS')];

        % continuous operation check
        isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
        fprintf('Profiles for quicklook: %d\n', sum(isChosen));
        
        sig = lidarData.rcs1064e(:, isChosen);
        height = lidarData.height;
        mTime = lidarData.mTime(isChosen);
        deltaT = datenum(0, 1, 0, 0, lidarConfig.deltaT, 0);

        % signal regrid
        mTimeGrid = (mTime(1):deltaT:mTime(end));
        heightGrid = height;
        sigGrid = NaN(length(heightGrid), length(mTimeGrid));
        for iT = 1:length(mTime)
            sigGrid(:, floor((mTime(iT) - mTimeGrid(1)) / deltaT) + 1) = sig(:, iT);
        end

        %% signal visualization
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, sigGrid);
        p1.EdgeColor = 'None';
        rectangle('Position', [tRangeMark(1), lidarConfig.hRange(1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(2) - lidarConfig.hRange(1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title);

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange);
        caxis([1e7, 1e10]);
        colormap('jet');

        set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
        ax = gca;
        ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

        datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
        colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

        text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

        if exist(config.evaluationReportPath, 'dir')
            export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('quicklook_%s_%s.%s', lidarType{iLidar}, '1064e', config.figFormat)), '-r300');
        end

        if strcmpi(lidarConfig.figVisible, 'off')
            close all;
        end

    otherwise
        errStruct.message = sprintf('Wrong configuration for lidarNo (%d).', lidarConfig.lidarNo);
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end

end

diaryoff;

end