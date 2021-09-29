function displayQL(config, varargin)
% DISPLAYQL display lidar data quicklooks.
% USAGE:
%    displayQL(config)
% INPUTS:
%    config: struct
%        see examples in `./config` folder.
% KEYWORDS:
%    flagDebug: logical
%        flag to print debug messages.
%    flagCorTime: logical
% HISTORY:
%    2021-09-22: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

global LEToolboxInfo

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'config', @isstruct);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'flagCorTime', true, @islogical);

parse(p, config, varargin{:});

%% log output
logFile = fullfile(config.evaluationReportPath, 'lidar_displayQL.log');
diaryon(logFile);

lidarType = fieldnames(config.dataVisualCfg);
for iLidar = 1:length(lidarType)

    lidarConfig = config.dataVisualCfg.(lidarType{iLidar});

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

    %% visualization
    switch lidarConfig.lidarNo

    case 11   % REAL

        % time slot
        tRange = [datenum(lidarConfig.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        if ~ isempty(lidarConfig.markTRange)
            tRangeMark = [datenum(lidarConfig.markTRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.markTRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        end

        isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
        fprintf('Profiles for quicklook: %d\n', sum(isChosen));

        rcs532p = lidarData.rcs532p(:, isChosen);
        rcs532s = lidarData.rcs532s(:, isChosen);
        vdr532 = (lidarData.(['rcs', lidarConfig.vdrCompose{2}])./ lidarData.(['rcs', lidarConfig.vdrCompose{1}])) * lidarConfig.vdrCompose{3} + lidarConfig.vdrCompose{4};
        height = lidarData.height;
        mTime = lidarData.mTime(isChosen);
        deltaT = datenum(0, 1, 0, 0, lidarConfig.deltaT, 0);

        if ~ isempty(lidarConfig.markTRange)
            isChosenMark = (lidarData.mTime >= tRangeMark(1)) & (lidarData.mTime <= tRangeMark(2));

            if ~ any(isChosenMark)
                warning('No profiles were chosen for tRangeMark!');
                rcs532pInt = NaN(size(lidarData.height));
                rcs532sInt = NaN(size(lidarData.height));
                vdr532Int = NaN(size(lidarData.height));
            else
                rcs532pInt = nanmean(lidarData.rcs532p(:, isChosenMark), 2);
                rcs532sInt = nanmean(lidarData.rcs532s(:, isChosenMark), 2);
                vdr532Int = nanmean(lidarData.(['rcs', lidarConfig.vdrCompose{2}])(:, isChosenMark), 2) ./ nanmean(lidarData.(['rcs', lidarConfig.vdrCompose{1}])(:, isChosenMark), 2) * lidarConfig.vdrCompose{3} + lidarConfig.vdrCompose{4};
            end
        end

        % signal regrid
        mTimeGrid = (mTime(1):deltaT:mTime(end));
        heightGrid = height;
        rcs532pGrid = NaN(length(heightGrid), length(mTimeGrid));
        rcs532sGrid = NaN(length(heightGrid), length(mTimeGrid));
        vdr532Grid = NaN(length(heightGrid), length(mTimeGrid));
        tIndGrid = ones(size(mTime));
        if p.Results.flagCorTime
            % correct time drift
            mTimeGrid(1) = mTime(1);
            rcs532pGrid(:, 1) = rcs532p(:, 1);
            rcs532sGrid(:, 1) = rcs532s(:, 1);
            vdr532Grid(:, 1) = vdr532(:, 1);
            tIndGrid(1) = 1;
            for iT = 2:length(mTime)
                tInd = floor((mTime(iT) - mTime(iT - 1) + 1e-9 + 0.1 * deltaT) / deltaT) + tIndGrid(iT - 1);
                if tInd > length(mTimeGrid)
                    continue;
                end

                tIndGrid(iT) = tInd;
                rcs532pGrid(:, tInd) = rcs532p(:, iT);
                rcs532sGrid(:, tInd) = rcs532s(:, iT);
                vdr532Grid(:, tInd) = vdr532(:, iT);
            end
        else
            for iT = 1:length(mTime)
                rcs532pGrid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = rcs532p(:, iT);
                rcs532sGrid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = rcs532s(:, iT);
                vdr532Grid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = vdr532(:, iT);
            end
        end

        %% signal visualization

        % 532 p
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, rcs532pGrid);
        p1.EdgeColor = 'None';
        if ~ isempty(lidarConfig.markTRange)
            rectangle('Position', [tRangeMark(1), lidarConfig.hRange(1, 1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(1, 2) - lidarConfig.hRange(1, 1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
        end

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title{1});

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange(1, :));
        caxis(lidarConfig.sigRange(1, :));
        colormap('jet');

        set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
        ax = gca;
        ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

        datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
        colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

        text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

        if exist(config.evaluationReportPath, 'dir')
            export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('quicklook_%s_%s.%s', lidarType{iLidar}, '532p', config.figFormat)), '-r300');
        end

        % 532 s
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, rcs532sGrid);
        p1.EdgeColor = 'None';
        if ~ isempty(lidarConfig.markTRange)
            rectangle('Position', [tRangeMark(1), lidarConfig.hRange(2, 1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(2, 2) - lidarConfig.hRange(2, 1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
        end

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title{2});

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange(2, :));
        caxis(lidarConfig.sigRange(2, :));
        colormap('jet');

        set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
        ax = gca;
        ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

        datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
        colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

        text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

        if exist(config.evaluationReportPath, 'dir')
            export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('quicklook_%s_%s.%s', lidarType{iLidar}, '532s', config.figFormat)), '-r300');
        end

        % 532 volume depolarization ratio
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, vdr532Grid);
        p1.EdgeColor = 'None';
        if ~ isempty(lidarConfig.markTRange)
            rectangle('Position', [tRangeMark(1), lidarConfig.hRange(3, 1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(3, 2) - lidarConfig.hRange(3, 1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
        end

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title{3});

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange(3, :));
        caxis(lidarConfig.sigRange(3, :));
        colormap('jet');

        set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
        ax = gca;
        ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

        datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
        colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

        text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

        if exist(config.evaluationReportPath, 'dir')
            export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('quicklook_%s_%s.%s', lidarType{iLidar}, '532vdr', config.figFormat)), '-r300');
        end

        % diagnose signal merge
        if p.Results.flagDebug && p.Results.flagDebug
            displayREALSigMerge(lidarData.height, lidarData.mTime(isChosenMark), lidarData.sig532sh(:, isChosenMark), lidarData.sig532sl(:, isChosenMark), lidarData.mergeRange(1, :), 'channelTag', '532S', 'hRange', lidarConfig.hRange(1, :), 'cRange', lidarConfig.sigRange(1, :), 'mergeSlope', lidarData.mergeSlope(1), 'mergeOffset', lidarData.mergeOffset(1), 'figFolder', config.evaluationReportPath);
            displayREALSigMerge(lidarData.height, lidarData.mTime(isChosenMark), lidarData.sig532ph(:, isChosenMark), lidarData.sig532pl(:, isChosenMark), lidarData.mergeRange(2, :), 'channelTag', '532P', 'hRange', lidarConfig.hRange(2, :), 'cRange', lidarConfig.sigRange(2, :), 'mergeSlope', lidarData.mergeSlope(2), 'mergeOffset', lidarData.mergeOffset(2), 'figFolder', config.evaluationReportPath);
            displayREALSigMerge(lidarData.height, lidarData.mTime(isChosenMark), lidarData.sig607h(:, isChosenMark), lidarData.sig607l(:, isChosenMark), lidarData.mergeRange(3, :), 'channelTag', '607', 'hRange', lidarConfig.hRange(3, :), 'cRange', [1e10, 1e13], 'mergeSlope', lidarData.mergeSlope(3), 'mergeOffset', lidarData.mergeOffset(3), 'figFolder', config.evaluationReportPath);
        end

        % integral signal
        if ~ isempty(lidarConfig.markTRange)
            figure('Position', [0, 10, 550, 400], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

            figPos = subfigPos([0.11, 0.13, 0.87, 0.8], 1, 2, 0.03, 0);

            subplot('Position', figPos(1, :), 'Units', 'Normalized');
            rcs532pTmp = rcs532pInt;
            rcs532pTmp(rcs532pTmp <= 0) = NaN;
            rcs532sTmp = rcs532sInt;
            rcs532sTmp(rcs532sTmp <= 0) = NaN;
            pSig = semilogx(rcs532pTmp, lidarData.height, 'Color', [48, 80, 79]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '532 P'); hold on;
            pBg = semilogx(rcs532sTmp, lidarData.height, 'Color', [177, 89, 41]/255, 'LineStyle', '-', 'LineWidth', 2, 'DisplayName', '532 S');

            xlabel('RCS (a.u.)');
            ylabel('Height (m)');
            text(1.13, 1.05, 'REAL Quicklook', 'Units', 'Normalized', 'FontSize', 12, 'FontWeight', 'Bold', 'HorizontalAlignment', 'center');

            xlim([min(lidarConfig.sigRange(1:2, 1)), max(lidarConfig.sigRange(1:2, 2))]);
            ylim([min(lidarConfig.hRange(1:2, 1)), max(lidarConfig.hRange(1:2, 2))]);
            set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

            legend([pSig, pBg], 'Location', 'NorthEast');
            text(-0.1, -0.12, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');
            text(0.3, 0.7, sprintf('From %s\nto %s\nProfiles: %d\n', datestr(tRangeMark(1), 'yyyy-mm-dd HH:MM'), datestr(tRangeMark(2), 'yyyy-mm-dd HH:MM'), sum(isChosenMark)), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

            subplot('Position', figPos(2, :), 'Units', 'Normalized');
            plot(vdr532Int, lidarData.height, 'Color', [231, 41, 139]/255, 'LineStyle', '-', 'LineWidth', 2); hold on;

            xlabel('vol. depol.');
            ylabel('');

            xlim(lidarConfig.sigRange(3, :));
            ylim(lidarConfig.hRange(3, :));
            set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'YTickLabel', '', 'Layer', 'Top', 'Box', 'on', 'LineWidth', 2);

            if exist(config.evaluationReportPath, 'dir')
                export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('Profile_%s_%s.%s', lidarType{iLidar}, 'vdr532', config.figFormat)), '-r300');
            end
        end

    case {3}   % avors

        % time slot
        tRange = [datenum(lidarConfig.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        if ~ isempty(lidarConfig.markTRange)
            tRangeMark = [datenum(lidarConfig.markTRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.markTRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        end

        isChosen = (lidarData.mTime >= tRange(1)) & (lidarData.mTime <= tRange(2));
        fprintf('Profiles for quicklook: %d\n', sum(isChosen));

        rcs532p = lidarData.rcs532p(:, isChosen);
        rcs532s = lidarData.rcs532s(:, isChosen);
        height = lidarData.height;
        mTime = lidarData.mTime(isChosen);
        deltaT = datenum(0, 1, 0, 0, lidarConfig.deltaT, 0);

        % signal regrid
        mTimeGrid = (mTime(1):deltaT:mTime(end));
        heightGrid = height;
        rcs532pGrid = NaN(length(heightGrid), length(mTimeGrid));
        rcs532sGrid = NaN(length(heightGrid), length(mTimeGrid));
        tIndGrid = ones(size(mTime));
        if p.Results.flagCorTime
            % correct time drift
            mTimeGrid(1) = mTime(1);
            rcs532pGrid(:, 1) = rcs532p(:, 1);
            rcs532sGrid(:, 1) = rcs532s(:, 1);
            tIndGrid(1) = 1;
            for iT = 2:length(mTime)
                tInd = floor((mTime(iT) - mTime(iT - 1) + 1e-9 + 0.1 * deltaT) / deltaT) + tIndGrid(iT - 1);
                if tInd > length(mTimeGrid)
                    continue;
                end

                tIndGrid(iT) = tInd;
                rcs532pGrid(:, tInd) = rcs532p(:, iT); 
                rcs532sGrid(:, tInd) = rcs532s(:, iT); 
            end
        else
            for iT = 1:length(mTime)
                rcs532pGrid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = rcs532p(:, iT);
                rcs532sGrid(:, floor((mTime(iT) - mTimeGrid(1) + 1e-9) / deltaT) + 1) = rcs532s(:, iT);
            end
        end

        %% signal visualization

        % rcs 532 p
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, rcs532pGrid);
        p1.EdgeColor = 'None';
        if ~ isempty(lidarConfig.markTRange)
            rectangle('Position', [tRangeMark(1), lidarConfig.hRange(1, 1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(1, 2) - lidarConfig.hRange(1, 1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
        end

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title{1}, 'interpreter', 'none');

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange(1, :));
        caxis(lidarConfig.sigRange(1, :));
        colormap('jet');

        set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
        ax = gca;
        ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

        datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
        colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

        text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

        if exist(config.evaluationReportPath, 'dir')
            export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('quicklook_%s_%s.%s', lidarType{iLidar}, '532p', config.figFormat)), '-r300');
        end

        % rcs 532 s
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, rcs532sGrid);
        p1.EdgeColor = 'None';
        if ~ isempty(lidarConfig.markTRange)
            rectangle('Position', [tRangeMark(1), lidarConfig.hRange(2, 1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(2, 2) - lidarConfig.hRange(2, 1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
        end

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title{2}, 'interpreter', 'none');

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange(2, :));
        caxis(lidarConfig.sigRange(2, :));
        colormap('jet');

        set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'XTick', linspace(mTimeGrid(1), mTimeGrid(end), 5), 'Layer', 'Top', 'Box', 'on', 'TickDir', 'out', 'LineWidth', 2);
        ax = gca;
        ax.XAxis.MinorTickValues = linspace(mTimeGrid(1), mTimeGrid(end), 25);

        datetick(gca, 'x', 'HH:MM', 'KeepTicks', 'KeepLimits');
        colorbar('Position', [0.91, 0.20, 0.03, 0.65], 'Units', 'Normalized');

        text(-0.1, -0.15, sprintf('Version: %s', LEToolboxInfo.programVersion), 'Units', 'Normalized', 'FontSize', 10, 'HorizontalAlignment', 'left', 'FontWeight', 'Bold');

        if exist(config.evaluationReportPath, 'dir')
            export_fig(gcf, fullfile(config.evaluationReportPath, sprintf('quicklook_%s_%s.%s', lidarType{iLidar}, '532s', config.figFormat)), '-r300');
        end

    case {12, 13}   % WHU 1064 

        % time slot
        tRange = [datenum(lidarConfig.tRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.tRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        if ~ isempty(lidarConfig.markTRange)
            tRangeMark = [datenum(lidarConfig.markTRange(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.markTRange(23:41), 'yyyy-mm-dd HH:MM:SS')];
        end

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
        figure('Position', [0, 10, 600, 300], 'Units', 'Pixels', 'Color', 'w', 'Visible', lidarConfig.figVisible);

        subplot('Position', [0.14, 0.15, 0.75, 0.75], 'Units', 'Normalized');
        p1 = pcolor(mTimeGrid, heightGrid, sigGrid);
        p1.EdgeColor = 'None';
        if ~ isempty(lidarConfig.markTRange)
            rectangle('Position', [tRangeMark(1), lidarConfig.hRange(1), (tRangeMark(2) - tRangeMark(1)), (lidarConfig.hRange(2) - lidarConfig.hRange(1))], 'EdgeColor', 'k', 'LineWidth', 2, 'LineStyle', '--', 'FaceColor', [[193, 193, 193]/255, 0.5]);
        end

        xlabel('Local Time');
        ylabel('Height (m)');
        title(lidarConfig.title, 'interpreter', 'none');

        xlim([mTimeGrid(1), mTimeGrid(end)]);
        ylim(lidarConfig.hRange);
        caxis(lidarConfig.sigRange);
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

    otherwise
        errStruct.message = sprintf('Wrong configuration for lidarNo (%d).', lidarConfig.lidarNo);
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end

    if strcmpi(lidarConfig.figVisible, 'off')
        close all;
    end
end

diaryoff;

end