function lidarDataLoader(configFile, varargin)
% LIDARDATALOADER convert lidar data to HDF5 format.
% USAGE:
%    [output] = lidarDataLoader(params)
% INPUTS:
%    params
% OUTPUTS:
%    output
% EXAMPLE:
% HISTORY:
%    2021-09-13: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'configFile', @ischar);

parse(p, configFile, varargin{:});

%% read configurations
fprintf('[%s] Start reading configurations for lidar data loader!\n', tNow);
config = yaml.ReadYaml(configFile);
fprintf('[%s] Finish!\n', tNow);

%% Create log file
logFile = fullfile(config.evaluationReportPath, sprintf('LidarDataLoad_%s.log', sprintf(now, 'yyyymmddHHMMSS')));
diaryon(logFile);

%% read data
lidarType = fieldnames(config.dataLoaderCfg);
for iLidar = 1:length(lidarType)
    lidarCfg = config.dataLoaderCfg.(lidarType{iLidar});

    % prepare output folder
    if ~ exist(config.evaluationReportPath, 'dir')
        fprintf('[%s] Create path for saving evluation report!\n', tNow);
        mkdir(config.evaluationReportPath);
        fprintf('[%s] Output folder: %s\n', tNow, config.evaluationReportPath);
    end

    % prepare data exporting path
    if ~ exist(config.dataSavePath, 'dir')
        fprintf('[%s] Create path for saving lidar data!\n', tNow);
        mkdir(config.dataSavePath);
        fprintf('[%s] Output folder: %s\n', tNow, config.dataSavePath);
    end

    %% read lidar data
    fprintf('[%s] Reading %s data.\n', tNow, lidarType{iLidar});
    lidarData = readLidarData(lidarCfg.dataPath, 'dataFormat', lidarConfig.dataFormat, 'dataFilePattern', lidarCfg.dataFilenamePattern);
    fprintf('[%s] Finish!\n', tNow);

    %% convert lidar data to HDF5
    ncFile = fullfile(config.dataSavePath, sprintf('%s_rawdata.h5', lidarType{iLidar}));
    convertData2H5(lidarData, ncFile);
end

diaryoff;

end