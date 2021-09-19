function [isPassQuadrantChk] = quadrantChk(lidarData, lidarConfig, reportFile, varargin)
% quadrantChk description
% USAGE:
%    [isPassQuadrantChk] = quadrantChk(lidarData, lidarConfig, reportFile)
% INPUTS:
%    lidarData, lidarConfig, reportFile
% OUTPUTS:
%    isPassQuadrantChk
% EXAMPLE:
% HISTORY:
%    2021-09-19: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'lidarData', @isstruct);
addRequired(p, 'lidarConfig', @isstruct);
addRequired(p, 'reportFile', @ischar);

parse(p, lidarData, lidarConfig, reportFile, varargin{:});

isPassQuadrantChk = false(1, length(lidarConfig.chTag));

if length(lidarConfig.quadrantChk.quadrantTime) ~= 5
    errStruct.message = 'Wrong configuration for quadrantTime.';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

fid = fopen(reportFile, 'a');
fprintf(fid, '## Quadrant Check\n');

for iCh = 1:length(lidarConfig.chTag)
    fprintf(fid, '**%s**\n', lidarConfig.chTag{iCh});

    % load signal
    east1TRange = [datenum(lidarConfig.quadrantChkCfg.quadrantTime{1}(1:19), 'yyyy-mm-dd HH:MM:SS'), datenum(lidarConfig.quadrantChkCfg.quadrantTime{1}())]

    % determine deviations

    % signal visualization
end

fclose(fid);

end