function lidarData = lidarPreprocess(lidarData, chTag, varargin)
% LIDARPREPROCESS lidar signal pre-process.
% USAGE:
%    lidarData = lidarPreprocess(lidarData, chTag)
% INPUTS:
%    lidarData: struct
%    chTag: cell
% KEYWORDS:
%    deadtime: numeric (1 x nChs)
%        deadtime. (ns)
%    bgBins: numeric (2 x nChs)
%    nPretrigger: numeric
%    bgCorFile: char
%    lidarNo: numeric
%    flagDebug: logical
%    tOffset: numeric
%        time offset. (days)
%    hOffset: numeric
%        height offset. (m)
%    overlapFile: char
% OUTPUTS:
%    lidarData: struct
%        rcsxxx, bgxxx, sigxxx
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

case 11
    % REAL

    %% parameter initialization (only for REAL data)
    % mergeRange = [1230, 1260; 1230, 1260; 1000, 1500];   % height range for signal merge. (m)
    mergeRange = [1300, 2500; 1300, 2500; 1000, 1500];   % height range for signal merge. (m)
    mergeSlope = [16.9612, 586.4, 1];   % normalization ratio for 532S, 532P, 607 (High / Low)
    mergeOffset = [0, 0, 0];

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

            sigCor = sig ./ (1 - p.Results.deadtime(iCh) * 1e-9 .* sig);
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
            dataTmp = textscan(fid, '%f%f', 'headerlines', 0, 'delimiter', ' ', 'MultipleDelimsAsOne', true);
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

    % signal merge
    lidarData.sig532s = sigMergeREAL(lidarData.sig532sh, lidarData.sig532sl, lidarData.height, mergeRange(1, :), mergeSlope(1), mergeOffset(1));
    lidarData.sig532p = sigMergeREAL(lidarData.sig532ph, lidarData.sig532pl, lidarData.height, mergeRange(2, :), mergeSlope(2), mergeOffset(2));
    lidarData.sig607 = sigMergeREAL(lidarData.sig607h, lidarData.sig607l, lidarData.height, mergeRange(3, :), mergeSlope(3), mergeOffset(3));
    lidarData.bg532s = lidarData.bg532sh;
    lidarData.bg532p = lidarData.bg532ph;
    lidarData.bg607 = lidarData.bg607h;
    lidarData.rcs532s = lidarData.sig532s .* repmat(lidarData.height.^2, 1, length(lidarData.mTime));
    lidarData.rcs532p = lidarData.sig532p .* repmat(lidarData.height.^2, 1, length(lidarData.mTime));
    lidarData.rcs607 = lidarData.sig607 .* repmat(lidarData.height.^2, 1, length(lidarData.mTime));
    lidarData.mergeRange = mergeRange;
    lidarData.mergeOffset = mergeOffset;
    lidarData.mergeSlope = mergeSlope;

case {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13}

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

            sigCor = sig ./ (1 - p.Results.deadtime(iCh) * 1e-9 .* sig);
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
            dataTmp = textscan(fid, '%f%f', 'headerlines', 0, 'delimiter', ' ', 'MultipleDelimsAsOne', true);
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