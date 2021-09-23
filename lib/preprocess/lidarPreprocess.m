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

global LEToolboxInfo

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
addParameter(p, 'tOffset', 0, @isnumeric);
addParameter(p, 'hOffset', 0, @isnumeric);
addParameter(p, 'overlapFile', '', @ischar);

parse(p, lidarData, chTag, varargin{:});

switch p.Results.lidarNo
case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13}
    % all lidars

    % pretrigger removes for height
    lidarData.height = lidarData.height((p.Results.nPretrigger + 1):end) + p.Results.hOffset;
    lidarData.mTime = lidarData.mTime + p.Results.tOffset;

    for iCh = 1:length(chTag)

        sig = lidarData.(['sig', chTag{iCh}]);

        % deadtime correction
        if ~ isempty(p.Results.deadtime)

            if length(p.Results.deadtime) ~= length(chTag)
                errStruct.message = sprintf('Wrong configuration for deadtime.');
                errStruct.identifier = 'LEToolbox:Err003';
                error(errStruct);
            end

            sigCor = sig ./ (1 - p.Results.deadtime(iCh) .* sig);
        else
            sigCor = sig;
        end

        % nPretrigger remove
        sigCor = sigCor((p.Results.nPretrigger + 1):end, :);

        if p.Results.bgBins(2) > length(lidarData.height)
            errStruct.message = sprintf('Wrong configuration for bgBins.');
            errStruct.identifier = 'LEToolbox:Err003';
            error(errStruct);
        end

        % overlap correction
        if ~ isempty(p.Results.overlapFile)
            fid = fopen(fullfile(LEToolboxInfo.projectDir, 'lib', 'overlap', p.Results.overlapFile), 'r');
            dataTmp = textscan(fid, '%f%f', 'headerlines', 0, 'delimiter', '\t', 'MultipleDelimsAsOne', true);
            ovHeight = dataTmp{1};
            ovFunc = dataTmp{2};
            fclose(fid);

            % interpolate overlap
            ovFuncInterp = interp1(ovHeight, ovFunc, lidarData.height,'linear','extrap');
            sigCor = sigCor ./ ovFuncInterp;
        end

        % background correction
        bg = nanmean(sigCor(p.Results.bgBins(1):p.Results.bgBins(2), :), 1);
        sigCor = sigCor - repmat(bg, length(lidarData.height), 1);

        % range correction
        rcs = sigCor .* repmat(lidarData.height.^2, 1, length(lidarData.mTime));

        lidarData.(['sig', chTag{iCh}]) = sigCor;
        lidarData.(['bg', chTag{iCh}]) = bg;
        lidarData.(['rcs', chTag{iCh}]) = rcs;
    end

otherwise
    errStruct.message = sprintf('Wrong configuration for lidarNo (%d).', p.Results.lidarNo);
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

end