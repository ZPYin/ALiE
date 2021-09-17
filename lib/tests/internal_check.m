%% initialization
configFile = 'D:\Coding\Matlab\lidar_evaluation_1064\config\comparison_config_20210910.yml';

%% read configuration
fprintf('[%s] Start reading configurations for internal check!\n', tNow);
config = yaml.ReadYaml(configFile);
fprintf('[%s] Finish!\n', tNow);

lidarType = fieldnames(config.internalChkCfg);
for iLidar = 1:length(lidarType)

    lidarConfig = config.internalChkCfg.(lidarType{iLidar});

    % prepare output folder
    if ~ exist(config.evaluationReportPath, 'dir')
        fprintf('[%s] Create path for saving evaluation report!\n', tNow);
        mkdir(config.evaluationReportPath);
        fprintf('[%s] Output folder: %s\n', tNow, config.evaluationReportPath);
    end
    if ~ exist(config.evaluationReportPath, 'dir')
        fprintf('[%s] Create path for saving evaluation report!\n', tNow);
        mkdir(config.evaluationReportPath);
        fprintf('[%s] Output folder: %s\n', tNow, config.evaluationReportPath);
    end

    fprintf('[%s] Internal check for %s\n', tNow, lidarType{iLidar});

    %% backscatter retrieval check
    if lidarConfig.flagRetrievalChk
        %% convert data

        %% evaluation

        %% visualization

        %% evaluation report output
    end

    %% detection ability check
    if lidarConfig.flagDetectRangeChk

        %% convert data
        fprintf('[%s] Reading %s data.\n', tNow, lidarType{iLidar});
        lidarData = readLidarData(lidarConfig.dataPath, 'dataFormat', lidarConfig.dataFormat);
        fprintf('[%s] Finish!\n', tNow);

        fprintf('[%s] Convert %s data to netCDF format.\n', tNow, lidarType{iLidar});
        ncFilename = fullfile(config.evaluationReportPath, sprintf(''));
        fprintf('[%s] Finish!\n', tNow);

    end

end