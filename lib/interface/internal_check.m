%% initialization
configFile = 'D:\Coding\Matlab\lidar_evaluation_1064\config\comparison_config_20210910.yml';
flagDebug = true;

%% read configuration
fprintf('[%s] Start reading configurations for internal check!\n', tNow);
fprintf('[%s] Config file: %s\n', configFile);
config = yaml.ReadYaml(configFile);
fprintf('[%s] Finish!\n', tNow);

%% log output
logFile = fullfile(config.evaluationReportPath, 'lidar_internal_check.log');
diaryon(logFile);


lidarType = fieldnames(config.internalChkCfg);
for iLidar = 1:length(lidarType)
    
    lidarConfig = config.internalChkCfg.(lidarType{iLidar});
    reportFile = fullfile(config.evaluationReportPath, sprintf('%s_internal_check_report.txt', lidarType{iLidar}));
    fid = fopen(reportFile, 'w');
    fprintf(fid, '# Evaluation Report for %s\n', lidarType{iLidar});
    fclose(fid);

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

    fprintf('[%s] Internal check for %s\n', tNow, lidarType{iLidar});

    % check lidar data file
    h5Filename = fullfile(config.evaluationReportPath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    if exist(h5Filename, 'file') ~= 2
        warning('No lidar data for %s', lidarType{iLidar});
        continue;
    end

    %% read lidar data
    lidarData = struct();
    lidarData.mTime = h5read(h5Filename, '/time') + lidarConfig.tOffset;
    lidarData.height = h5read(h5Filename, '/height') + lidarConfig.hOffset;
    for iCh = 1:length(lidarConfig.chTag)
        if flagDebug
            fprintf('Reading lidar data of %s\n', lidarConfig.chTag{iCh});
        end

        lidarData.(lidarConfig.chTag{iCh}) = h5read(h5Filename, sprintf('/%s', lidarConfig.chTag{iCh}));
    end

    %% pre-process
    lidarData = lidarPreprocess(lidarData, lidarConfig.chTag, ...
        'deadtime', lidarConfig.preprocessCfg.deadTime, ...
        'bgBins', lidarConfig.preprocessCfg.bgBins, ...
        'nPretrigger', lidarConfig.preprocessCfg.nPretrigger, ...
        'bgCorFile', lidarConfig.preprocessCfg.bgCorFile, ...
        'lidarNo', lidarConfig.lidarNo, ...
        'flagDebug', flagDebug);

    %% backscatter retrieval check
    if lidarConfig.flagRetrievalChk
        %% convert data

        %% evaluation

        %% visualization

        %% evaluation report output
    end

    %% detection ability check
    if lidarConfig.flagDetectRangeChk

    end

    %% quadrant check
    if lidarConfig.flagQuadrantChk
        quadrantChk(lidarData, lidarConfig, reportFile);
    end

end

diaryoff;