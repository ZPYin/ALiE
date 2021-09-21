function [oData] = readLidarData(dataFolder, varargin)
% READLIDARDATA read lidar data.
% USAGE:
%    [oData] = readLidarData(dataFolder)
% INPUTS:
%    dataFolder, varargin
% OUTPUTS:
%    oData
% EXAMPLE:
% HISTORY:
%    2021-09-10: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'dataFolder', @ischar);
addParameter(p, 'dataFilePattern', '.*', @ischar);
addParameter(p, 'dataFormat', 1, @isnumeric);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'chTag', {}, @iscellstr);
addParameter(p, 'nMaxBin', 8000, @isnumeric);
addParameter(p, 'nBin', 8000, @isnumeric);

parse(p, dataFolder, varargin{:});

% read data
oData = struct();
oData.mTime = [];
oData.height = [];
oData.sig355 = [];
oData.sig355P = [];
oData.sig355S = [];
oData.sig387 = [];
oData.sig407 = [];
oData.sig532 = [];
oData.sig532P = [];
oData.sig532S = [];
oData.sig607 = [];
oData.sig1064 = [];
oData.sig1064P = [];
oData.sig1064S = [];

switch p.Results.dataFormat

case 1
    % WHU standard 1064 nm lidar data

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        lidarData = readWHU1064(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.sig1064 = cat(2, oData.sig1064, lidarData.sig1064);
    end

case 2
    % WHU non-standard 1064 nm lidar

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        lidarData = readWHU1064_2(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.sig1064 = cat(2, oData.sig1064, lidarData.sig1064);
    end

case 3
    % CMA standard data format

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        lidarData = readCmaLidarData(dataFiles{iFile}, p.Results.chTag, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;

        if isfield(lidarData, 'sig355')
            oData.sig355 = cat(2, oData.sig355, lidarData.sig355);
        end
        if isfield(lidarData, 'sig355P')
            oData.sig355P = cat(2, oData.sig355P, lidarData.sig355P);
        end
        if isfield(lidarData, 'sig355S')
            oData.sig355S = cat(2, oData.sig355S, lidarData.sig355S);
        end
        if isfield(lidarData, 'sig387')
            oData.sig387 = cat(2, oData.sig387, lidarData.sig387);
        end
        if isfield(lidarData, 'sig407')
            oData.sig407 = cat(2, oData.sig407, lidarData.sig407);
        end
        if isfield(lidarData, 'sig532')
            oData.sig532 = cat(2, oData.sig532, lidarData.sig532);
        end
        if isfield(lidarData, 'sig532P')
            oData.sig532P = cat(2, oData.sig532P, lidarData.sig532P);
        end
        if isfield(lidarData, 'sig532S')
            oData.sig532S = cat(2, oData.sig532S, lidarData.sig532S);
        end
        if isfield(lidarData, 'sig607')
            oData.sig607 = cat(2, oData.sig607, lidarData.sig607);
        end
        if isfield(lidarData, 'sig1064')
            oData.sig1064 = cat(2, oData.sig1064, lidarData.sig1064);
        end
        if isfield(lidarData, 'sig1064P')
            oData.sig1064P = cat(2, oData.sig1064P, lidarData.sig1064P);
        end
        if isfield(lidarData, 'sig1064S')
            oData.sig1064S = cat(2, oData.sig1064S, lidarData.sig1064S);
        end
    end

case 4
    % Dasun visibility lidar

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        lidarData = readDasun1064Pol(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.sig1064P = cat(2, oData.sig1064P, lidarData.sig1064P);
        oData.sig1064S = cat(2, oData.sig1064S, lidarData.sig1064S);
    end

case 5
    % REAL
    mergeRange = [1000, 2000];   % height range for signal merge. (m)
    mergeSlope = [1, 1, 1];   % normalization ratio for 532S, 532P, 607 (High / Low)
    mergeOffset = [0, 0, 0];

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    sig532SHNoBG = [];
    sig532PHNoBG = [];
    sig532SLNoBG = [];
    sig532PLNoBG = [];
    sig607LNoBG = [];
    sig607HNoBG = [];
    bg532SH = [];
    bg532PH = [];
    bg532SL = [];
    bg532PL = [];
    bg607L = [];
    bg607H = [];
    for iFile = 1:length(dataFiles)
        lidarData = readREAL(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        sig532SHNoBG = cat(2, sig532SHNoBG, lidarData.sig532SHNoBG);
        sig532PHNoBG = cat(2, sig532PHNoBG, lidarData.sig532PHNoBG);
        sig532SLNoBG = cat(2, sig532SLNoBG, lidarData.sig532SLNoBG);
        sig532PLNoBG = cat(2, sig532PLNoBG, lidarData.sig532PLNoBG);
        sig607LNoBG = cat(2, sig607LNoBG, lidarData.sig607LNoBG);
        sig607HNoBG = cat(2, sig607HNoBG, lidarData.sig607HNoBG);
        bg532SH = cat(2, bg532SH, lidarData.bg532SH);
        bg532PH = cat(2, bg532PH, lidarData.bg532PH);
        bg532SL = cat(2, bg532SL, lidarData.bg532SL);
        bg532PL = cat(2, bg532PL, lidarData.bg532PL);
        bg607L = cat(2, bg607L, lidarData.bg607L);
        bg607H = cat(2, bg607H, lidarData.bg607H);
    end

    % diagnose signal merge
    if p.Results.flagDebug

        displayREALSigMerge(oData.height, oData.mTime, sig532SHNoBG, sig532SLNoBG, mergeRange, 'channelTag', '532S');
        displayREALSigMerge(oData.height, oData.mTime, sig532PHNoBG, sig532PLNoBG, mergeRange, 'channelTag', '532P');
        displayREALSigMerge(oData.height, oData.mTime, sig607HNoBG, sig607LNoBG, mergeRange, 'channelTag', '607');
    end

    % signal merge
    oData.sig532S = sigMergeREAL(sig532SHNoBG, sig532SLNoBG, bg532SH, bg532SL, oData.height, mergeRange, mergeSlope(1), mergeOffset(1));
    oData.sig532P = sigMergeREAL(sig532PHNoBG, sig532PLNoBG, bg532PH, bg532PL, oData.height, mergeRange, mergeSlope(2), mergeOffset(2));
    oData.sig607 = sigMergeREAL(sig607HNoBG, sig607LNoBG, bg607H, bg607L, oData.height, mergeRange, mergeSlope(3), mergeOffset(3));

otherwise
    error('LE:Err001', 'Unknown lidar data format %d', p.Results.dataFormat);
end

end