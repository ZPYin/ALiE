function LEMain(configFile, varargin)
% LEMain description
% USAGE:
%    [output] = LEMain(params)
% INPUTS:
%    params
% OUTPUTS:
%    output
% EXAMPLE:
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
fprintf('[%s] Start reading configurations for internal check!\n', tNow);
fprintf('[%s] Config file: %s\n', tNow, configFile);
config = yaml.ReadYaml(configFile, 0, 1);
fprintf('[%s] Finish!\n', tNow);

%% backup configuration
if p.Results.flagBackupConfig
    configFileSave = fullfile(config.evaluationReportPath, sprintf('config_%s.yml', datestr(now, 'yyyymmddHHMMSS')));
    fprintf('[%s] Config file saved as: %s\n', tNow, configFileSave);
    copyfile(configFile, configFileSave);
end

if p.Results.flagReadData
    convertLidarData(config, 'flagDebug', p.Results.flagDebug);
end

if p.Results.flagInternalChk
    internal_check(config, 'flagDebug', p.Results.flagDebug);
end

if p.Results.flagExternalChk
    external_check(config, 'flagDebug', p.Results.flagDebug);
end

if p.Results.flagQL
    displayQL(config, 'flagDebug', p.Results.flagDebug);
end

end