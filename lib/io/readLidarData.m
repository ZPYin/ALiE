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
oData.rawSignal = [];

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
        oData.rawSignal = cat(3, oData.rawSignal, reshape(lidarData.rawSignal, size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
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
        oData.rawSignal = cat(1, oData.rawSignal, reshape(lidarData.rawSignal, size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
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
        oData.rawSignal = cat(3, oData.rawSignal, reshape(lidarData.rawSignal, size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
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
        oData.rawSignal = cat(3, oData.rawSignal, reshape(lidarData.rawSignal, size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end

case 5
    % REAL

    % search files
    dataFiles = listfile(dataFolder, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        lidarData = readREAL(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = lidarData.height;
        oData.rawSignal = cat(3, oData.rawSignal, reshape(lidarData.rawSignal, size(lidarData.rawSignal, 1), size(lidarData.rawSignal, 2), 1));
    end

    otherwise
    error('LE:Err001', 'Unknown lidar data format %d', p.Results.dataFormat);
end

end