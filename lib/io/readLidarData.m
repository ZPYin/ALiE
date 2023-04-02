function [oData, chTag] = readLidarData(dataFolder, varargin)
% READLIDARDATA read lidar data.
% USAGE:
%    [oData] = readLidarData(dataFolder)
% INPUTS:
%    dataFolder: char
% KEYWORDS:
%    dataFilenamePattern: char
%    dataFormat: char
%    flagDebug: logical
%    nMaxBin: numeric
%    nBin: numeric
%    flagFilenameTime: logical
% OUTPUTS:
%    oData: struct
%    chTag: cell
% HISTORY:
%    2021-09-10: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'dataFolder', @ischar);
addParameter(p, 'dataFilePattern', '.*', @ischar);
addParameter(p, 'dataFormat', 1, @isnumeric);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'nMaxBin', 8000, @isnumeric);
addParameter(p, 'nBin', 8000, @isnumeric);
addParameter(p, 'flagFilenameTime', false, @islogical);

parse(p, dataFolder, varargin{:});

% read data
oData = struct();
oData.mTime = [];
oData.height = [];
oData.rawSignal = [];
chTag = cell(0);

switch p.Results.dataFormat

case 1
    % WHU standard 1064 nm lidar data

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        if iFile <= 1
            fprintf('[%s] Wait until reading finishes!\n', tNow);
        end

        lidarData = readWHU1064(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.rawSignal = cat(3, oData.rawSignal, ...
            reshape(lidarData.rawSignal, ...
                size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end
    chTag = {'1064e'};

case 2
    % WHU non-standard 1064 nm lidar

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        if iFile <= 1
            fprintf('[%s] Wait until reading finishes!\n', tNow);
        end

        lidarData = readWHU1064_2(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.rawSignal = cat(3, oData.rawSignal, ...
            reshape(lidarData.rawSignal, ...
                size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end
    chTag = {'1064e'};

case 3
    % CMA standard data format (old)

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        if iFile <= 1
            fprintf('[%s] Wait until reading finishes!\n', tNow);
        end

        [lidarData, chTag] = readCmaLidarData(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.rawSignal = cat(3, oData.rawSignal, ...
            reshape(lidarData.rawSignal, ...
                size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end

case 4
    % Dasun visibility lidar

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        if iFile <= 1
            fprintf('[%s] Wait until reading finishes!\n', tNow);
        end

        lidarData = readDasun1064Pol(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.rawSignal = cat(3, oData.rawSignal, ...
            reshape(lidarData.rawSignal, ...
                size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end
    chTag = {'1064p', '1064s'};

case 5
    % REAL

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        if iFile <= 1
            fprintf('[%s] Wait until reading finishes!\n', tNow);
        end

        lidarData = readREAL(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.rawSignal = cat(3, oData.rawSignal, ...
            reshape(lidarData.rawSignal, ...
                size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end

    chTag = {'532sh', '532ph', '532sl', '532pl', '607l', '607h'};

case 6
    % CMA standard data format (2021 new)

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)

        if iFile <= 1
            fprintf('[%s] Wait until reading finishes!\n', tNow);
        end

        [lidarData, chTag] = read_CMA_L0(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.fileTime);
        oData.height = (1:lidarData.nBin) * lidarData.resolution;
        oData.rawSignal = cat(3, oData.rawSignal, ...
            reshape(transpose(lidarData.rawSignal), ...
                size(lidarData.rawSignal, 2), size(lidarData.rawSignal, 1), 1));
    end

otherwise
    error('LE:Err001', 'Unknown lidar data format %d', p.Results.dataFormat);
end

end