function convertLidarData(config, varargin)
% CONVERTLIDARDATA convert lidar data to HDF5 format.
% USAGE:
%    convertLidarData(config)
% INPUTS:
%    config: struct
% KEYWORDS:
%    flagDebug: logical
% HISTORY:
%    2021-09-22: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'config', @isstruct);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, config, varargin{:});

fprintf('[%s] Start data conversion!\n', tNow);

%% log output
logFile = fullfile(config.evaluationReportPath, 'lidar_data_loading.log');
diaryon(logFile);

lidarType = fieldnames(config.dataLoaderCfg);
for iLidar = 1:length(lidarType)

    lidarConfig = config.dataLoaderCfg.(lidarType{iLidar});
    if ~ isfield(lidarConfig, 'flagFilenameTime')
        lidarConfig.flagFilenameTime = false;
    end
    if ~ isfield(lidarConfig, 'nBin')
        lidarConfig.nBin = [];
    end

    fprintf('[%s] Convert lidar data for %s\n', tNow, lidarType{iLidar});

    %% read lidar data
    fprintf('[%s] Reading %s data.\n', tNow, lidarType{iLidar});
    lidarData = readLidarData(lidarConfig.dataPath, ...
        'dataFormat', lidarConfig.dataFormat, ...
        'dataFilePattern', lidarConfig.dataFilenamePattern, ...
        'flagDebug', p.Results.flagDebug, ...
        'nMaxBin', lidarConfig.nMaxBin, ...
        'flagFilenameTime', lidarConfig.flagFilenameTime, ...
        'nBin', lidarConfig.nBin);
    fprintf('[%s] Finish!\n', tNow);

    %% convert lidar data
    fprintf('[%s] Convert %s data to HDF5 format.\n', tNow, lidarType{iLidar});
    h5Filename = fullfile(config.dataSavePath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    convertLidar2h5(lidarData, h5Filename, lidarConfig.chTag);
    fprintf('[%s] Finish!\n', tNow);

end

diaryoff;

end