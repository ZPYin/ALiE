function LEMain(configFile, varargin)
% LEMAIN main program of lidar evaluation.
% USAGE:
%    % Usecase 1: make quicklook
%    LEMain('config.yml', 'flagReadData', true, 'flagQL', true);
%    % Usecase 2: internal check
%    LEMain('config.yml', 'flagReadData', true, 'flagInternalChk', true);
%    % Usecase 3: external check
%    LEMain('config.yml', 'flagReadData', true, 'flagExternalChk', true);
%    % Usecase 4: debug mode
%    LEMain('config.yml', 'flagReadData', 'flagInternalChk', true, 'flagDebug', true);
% INPUTS:
%    configFile: char
%        absolute path of config file.
% KEYWORDS:
%    flagDebug: logical
%    flagReadData: logical
%    flagInternalChk: logical
%    flagExternalChk: logical
%    flagQL: logical
%    flagBackupConfig: logical
% HISTORY:
%    2021-09-23: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'configFile', @ischar);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'flagReadData', false, @islogical);
addParameter(p, 'flagInternalChk', false, @islogical);
addParameter(p, 'flagExternalChk', false, @islogical);
addParameter(p, 'flagQL', false, @islogical);
addParameter(p, 'flagBackupConfig', false, @islogical);

parse(p, configFile, varargin{:});

%% read configuration
if exist(configFile, 'file') == 2
    fprintf('[%s] Start reading configurations!\n', tNow);
    fprintf('[%s] Config file: %s\n', tNow, configFile);
    config = yaml.ReadYaml(configFile, 0, 1);
    fprintf('[%s] Finish!\n', tNow);
else
    errStruct.message = sprintf('Config file does not exist!\n%s', configFile);
    errStruct.identifier = 'LEToolbox:Err004';
    error(errStruct);
end

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

%% backup configuration
if p.Results.flagBackupConfig
    configFileSave = fullfile(config.evaluationReportPath, sprintf('config_%s.yml', datestr(now, 'yyyymmddHHMMSS')));
    fprintf('[%s] Config file saved as: %s\n', tNow, configFileSave);
    copyfile(configFile, configFileSave);
end

if p.Results.flagReadData
    % convert lidar data to HDF5 format
    convertLidarData(config, 'flagDebug', p.Results.flagDebug);
end

if p.Results.flagInternalChk
    % lidar internal check
    internalChk(config, 'flagDebug', p.Results.flagDebug);
end

if p.Results.flagExternalChk
    % lidar external check
    externalChk(config, 'flagDebug', p.Results.flagDebug);
end

if p.Results.flagQL
    % lidar data quicklooks
    displayQL(config, 'flagDebug', p.Results.flagDebug);
end

end