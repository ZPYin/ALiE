function convertLidarData(config, varargin)
% CONVERTLIDARDATA convert lidar data to HDF5 format.
%
% USAGE:
%    convertLidarData(config)
%
% INPUTS:
%    config: struct
%
% KEYWORDS:
%    flagDebug: logical
%
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
logFile = fullfile(config.resultPath, 'lidar_data_loading.log');
diaryon(logFile);

if isfield(config.dataLoaderCfg, 'lidarList')
    lidarType = config.dataLoaderCfg.lidarList;
else
    lidarType = fieldnames(config.dataLoaderCfg);
end

for iLidar = 1:length(lidarType)

    if ~ isfield(config.dataLoaderCfg, lidarType{iLidar})
        errStruct.message = 'Wrong configuration for lidarList';
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end

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
    [lidarData, chTagFromFile] = readLidarData(lidarConfig.dataPath, ...
        'dataFormat', lidarConfig.dataFormat, ...
        'dataFilePattern', lidarConfig.dataFilenamePattern, ...
        'flagDebug', p.Results.flagDebug, ...
        'nMaxBin', lidarConfig.nMaxBin, ...
        'flagFilenameTime', lidarConfig.flagFilenameTime, ...
        'nBin', lidarConfig.nBin);
    fprintf('[%s] Finish!\n', tNow);

    %% convert lidar data
    if isfield(lidarConfig, 'chTag')
        chTag = lidarConfig.chTag;
    else
        chTag = chTagFromFile;
    end
    fprintf('[%s] Convert %s data to HDF5 format.\n', tNow, lidarType{iLidar});
    h5Filename = fullfile(config.dataSavePath, ...
        sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    convertLidar2h5(lidarData, h5Filename, chTag);
    fprintf('[%s] Finish!\n', tNow);

end

diaryoff;

end