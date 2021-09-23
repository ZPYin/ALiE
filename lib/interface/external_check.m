function external_check(configFile, varargin)
% external_check description
% USAGE:
%    [output] = external_check(params)
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
fprintf('[%s] Start reading configurations for external check!\n', tNow);
fprintf('[%s] Config file: %s\n', tNow, configFile);
config = yaml.ReadYaml(configFile, 0, 1);
fprintf('[%s] Finish!\n', tNow);

%% backup configuration
configFileSave = fullfile(config.evaluationReportPath, sprintf('config_%s.yml', datestr(now, 'yyyymmddHHMMSS')));
fprintf('[%s] Config file saved as: %s\n', configFileSave);
copyfile(configFile, configFileSave);

%% log output
logFile = fullfile(config.evaluationReportPath, 'lidar_external_check.log');
diaryon(logFile);

reportFile = fullfile(config.evaluationReportPath, sprintf('external_check_report.txt'));
fid = fopen(reportFile, 'w');
fprintf(fid, '# Evaluation Report\n');
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

fprintf('[%s] Start external check\n', tNow);

%% range comparison
if config.externalChkCfg.flagRangeCmp
    fprintf('[%s] Start range comparison!\n', tNow);
    rangeCmp(config, reportFile, varargin{:});
    fprintf('[%s] Finish!\n', tNow);
end

%% RCS comparison
if config.externalChkCfg.flagRCSCmp
    fprintf('[%s] Start RCS comparison!\n', tNow);
    RCSCmp(config, reportFile, varargin{:});
    fprintf('[%s] Finish!\n', tNow);
end

diaryoff;

end