%% initialization
configFile = 'D:\Coding\Matlab\lidar_evaluation_1064\config\comparison_config_20210910.yml';
flagDebug = false;

%% read configuration
fprintf('[%s] Start reading configurations for internal check!\n', tNow);
fprintf('[%s] Config file: %s\n', configFile);
config = yaml.ReadYaml(configFile);
fprintf('[%s] Finish!\n', tNow);

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
        'flagDebug', flagDebug, ...
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