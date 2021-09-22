function internal_check(configFile, varargin)
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
fprintf('[%s] Start reading configurations for internal check!\n', tNow);
fprintf('[%s] Config file: %s\n', tNow, configFile);
config = yaml.ReadYaml(configFile, 0, 1);
fprintf('[%s] Finish!\n', tNow);

%% backup configuration
configFileSave = fullfile(config.evaluationReportPath, sprintf('config_%s.yml', datestr(now, 'yyyymmddHHMMSS')));
fprintf('[%s] Config file saved as: %s\n', configFileSave);
copyfile(configFile, configFileSave);

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
    h5Filename = fullfile(config.dataSavePath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    if exist(h5Filename, 'file') ~= 2
        warning('No lidar data for %s', lidarType{iLidar});
        continue;
    end

    %% read lidar data
    lidarData = struct();
    lidarData.mTime = unix_timestamp_2_datenum(h5read(h5Filename, '/time')) + lidarConfig.tOffset;
    lidarData.height = h5read(h5Filename, '/height') + lidarConfig.hOffset;
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
        'flagDebug', p.Results.flagDebug);

    %% backscatter retrieval check
    if lidarConfig.flagRetrievalChk
        %% convert data

        %% evaluation

        %% visualization

        %% evaluation report output
    end

    %% detection ability check
    if lidarConfig.flagDetectRangeChk
        fprintf('[%s] Start detection range test!\n', tNow);
        detectRangeChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
            'figFolder', config.evaluationReportPath, ...
            'figFormat', config.figFormat);
        fprintf('[%s] Finish!\n', tNow);
    end

    %% quadrant check
    if lidarConfig.flagQuadrantChk
        fprintf('[%s] Start telecover test!\n', tNow);
        quadrantChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
            'figFolder', config.evaluationReportPath, ...
            'figFormat', config.figFormat);
        fprintf('[%s] Finish!\n', tNow);
    end

    %% continuous operation check
    if lidarConfig.flagContOptChk
        fprintf('[%s] Start continuous operation test!\n', tNow);
        contOptChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
            'figFolder', config.evaluationReportPath, ...
            'figFormat', config.figFormat);
        fprintf('[%s] Finish!\n', tNow);
    end

    %% background noise check
    if lidarConfig.flagBgNoiseChk
        fprintf('[%s] Start background noise test!\n', tNow);
        bgNoiseChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
            'figFolder', config.evaluationReportPath, ...
            'figFormat', config.figFormat);
        fprintf('[%s] Finish!\n', tNow);
    end

    %% Rayleigh fit check
    if lidarConfig.flagRayleighChk
        fprintf('[%s] Start Rayleigh fit!\n', tNow);
        RayleighChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
            'figFolder', config.evaluationReportPath, ...
            'figFormat', config.figFormat);
        fprintf('[%s] Finish!\n', tNow);
    end

    %% Saturation check
    if lidarConfig.flagSaturationChk
        fprintf('[%s] Start Rayleigh fit!\n', tNow);
        saturationChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
            'figFolder', config.evaluationReportPath, ...
            'figFormat', config.figFormat);
        fprintf('[%s] Finish!\n', tNow);
    end
end

diaryoff;

end