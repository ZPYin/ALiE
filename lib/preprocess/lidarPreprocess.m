function [ lidarData ] = lidarPreprocess(lidarData, chTag, varargin)
% lidarPreprocess description
% USAGE:
%    [sigCor, rcs, bg] = lidarPreprocess(lidarData, varargin)
% INPUTS:
%    params
% OUTPUTS:
%    sigCor, rcs, bg
% EXAMPLE:
% HISTORY:
%    2021-09-19: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'lidarData', @isstruct);
addRequired(p, 'chTag', @iscell);
addParameter(p, 'deadtime', [], @isnumeric);
addParameter(p, 'bgBins', [], @isnumeric);
addParameter(p, 'nPretrigger', 0, @isnumeric);
addParameter(p, 'bgCorFile', '', @ischar);
addParameter(p, 'lidarNo', 12, @isnumeric);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, lidarData, chTag, varargin{:});

switch p.Results.lidarNo
case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12}
    % all lidars

    % pretrigger removes for height
    lidarData.height = lidarData.height((p.Results.nPretrigger + 1):end);

    for iCh = 1:length(chTag)

        sig = lidarData.(chTag{iCh});

        % deadtime correction
        if ~ isempty(p.Results.deadtime)

            if length(p.Results.deadtime) ~= length(chTag)
                errStruct.message = sprintf('Wrong configuration for deadtime.');
                errStruct.identifier = 'LEToolbox:Err003';
                error(errStruct);
            end

            sigCor = sig ./ (1 - p.Results.deadtime(iCh) .* sig);
        end

        % nPretrigger remove
        sigCor = sigCor((p.Results.nPretrigger + 1):end);

        if p.Results.bgBins(2) > length(lidarData.height)
            errStruct.message = sprintf('Wrong configuration for bgBins.');
            errStruct.identifier = 'LEToolbox:Err003';
            error(errStruct);
        end

        % background correction
        bg = nanmean(sigCor(p.Results.bgBins(1):p.Results.bgBins(2), :), 1);
        sigCor = sigCor - repmat(bg, 1, length(lidarData.mTime));

        % range correction
        rcs = sigCor .* repmat(transpose(lidarData.height.^2), 1, length(lidarData.mTime));

        lidarData.(chTag{iCh}) = sigCor;
        lidarData.(strrep(chTag{iCh}, 'sig', 'bg')) = bg;
        lidarData.(strrep(chTag{iCh}, 'sig', 'rcs')) = rcs;
    end

otherwise
    errStruct.message = sprintf('Wrong configuration for lidarNo (%d).', p.Results.lidarNo);
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

end