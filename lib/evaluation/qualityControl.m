function qualityControl(config, varargin)

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'config', @isstruct);
addParameter(p, 'flagDebug', @islogical);

parse(p, config, varargin{:});

%% log output
logFile = fullfile(config.logPath, 'lidar_QC.log');
diaryon(logFile);

if isfield(config.qcCfg, 'lidarList')
    lidarType = config.qcCfg.lidarList;
else
    lidarType = fieldnames(config.qcCfg);
end

for iLidar = 1:length(lidarType)

    lidarConfig = config.qcCfg.(lidarType{iLidar});
    fprintf('[%s] Quality control for %s\n', tNow, lidarType{iLidar});

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

    %% quality-control
    lidarDataOut = lidarQC(lidarData, lidarConfig.chTag);
    QCFilename = fullfile(config.level0Path, sprintf('57461_YLJ1_%s_prodL0_v010.nc', datestr(lidarDataOut.time(1), 'yyyymmddHHMMSS')));
    lidarQCSave(QCFilename, lidarDataOut);
end

end