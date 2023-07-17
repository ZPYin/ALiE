function externalChk(config, varargin)
% EXTERNALCHK lidar external check.
%
% USAGE:
%    externalChk(config)
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

%% log output
logFile = fullfile(config.resultPath, 'lidar_external_check.log');
diaryon(logFile);

reportFile = fullfile(config.resultPath, sprintf('external_check_report.txt'));
fid = fopen(reportFile, 'w');
fprintf(fid, '# Evaluation Report\n');
fclose(fid);

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

%% Fernald retrieval results comparison
if config.externalChkCfg.flagFernaldCmp
    fprintf('[%s] Start Fernald comparison!\n', tNow);
    FernaldCmp(config, reportFile, varargin{:});
    fprintf('[%s] Finish!\n', tNow)
end

%% VDR comparison
if config.externalChkCfg.flagVDRCmp
    fprintf('[%s] Start VDR comparison!\n', tNow);
    VDRCmp(config, reportFile, varargin{:});
    fprintf('[%s] Finish!\n', tNow);
end

%% Raman comparison
if config.externalChkCfg.flagRamanCmp
    fprintf('[%s] Start Raman comparison!\n', tNow);
    RamanCmp(config, reportFile, varargin{:});
    fprintf('[%s] Finish!\n', tNow);
end

diaryoff;

end