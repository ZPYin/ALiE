function convertLidarData(configFile, varargin)
% internal_check description
% USAGE:
%    [output] = internal_check(params)
% INPUTS:
%    params
% OUTPUTS:
%    output
% EXAMPLE:
% HISTORY:
%    2021-09-22: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'configFile', @ischar);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, configFile, varargin{:});

%% read configuration
fprintf('[%s] Start reading configurations for lidar data conversion!\n', tNow);
fprintf('[%s] Config file: %s\n', configFile);
config = yaml.ReadYaml(configFile, 0, 1);
fprintf('[%s] Finish!\n', tNow);

%% backup configuration
configFileSave = fullfile(config.evaluationReportPath, sprintf('config_%s.yml', datestr(now, 'yyyymmddHHMMSS')));
fprintf('[%s] Config file saved as: %s\n', tNow, configFileSave);
copyfile(configFile, configFileSave);

%% log output
logFile = fullfile(config.evaluationReportPath, 'lidar_data_loading.log');
diaryon(logFile);

lidarType = fieldnames(config.dataLoaderCfg);
for iLidar = 1:length(lidarType)

    lidarConfig = config.dataLoaderCfg.(lidarType{iLidar});

    % prepare output folder
    if ~ exist(config.evaluationReportPath, 'dir')
        fprintf('[%s] Create path for saving evaluation report!\n', tNow);
        mkdir(config.evaluationReportPath);
        fprintf('[%s] Output folder: %s\n', tNow, config.evaluationReportPath);
    end
    if ~ exist(config.dataSavePath, 'dir')
        fprintf('[%s] Create path for saving data!\n', tNow);
        mkdir(config.dataSavePath);
        fprintf('[%s] Data folder: %s\n', tNow, config.dataSavePath);
    end

    fprintf('[%s] Convert lidar data for %s\n', tNow, lidarType{iLidar});

    %% read lidar data
    fprintf('[%s] Reading %s data.\n', tNow, lidarType{iLidar});
    lidarData = readLidarData(lidarConfig.dataPath, ...
        'dataFormat', lidarConfig.dataFormat, ...
        'dataFilePattern', lidarConfig.dataFilenamePattern, ...
        'flagDebug', p.Results.flagDebug, ...
        'nMaxBin', lidarConfig.nMaxBin, ...
        'chTag', lidarConfig.chTag);
    fprintf('[%s] Finish!\n', tNow);

    %% convert lidar data
    fprintf('[%s] Convert %s data to HDF5 format.\n', tNow, lidarType{iLidar});
    h5Filename = fullfile(config.dataSavePath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    convertLidar2h5(lidarData, h5Filename);
    fprintf('[%s] Finish!\n', tNow);

end

diaryoff;

end