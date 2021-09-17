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
    dataFiles = listfile(inDataPath, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        lidarData = readWHUCL1064(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = height;
        oData.sig1064 = cat(1, oData.sig1064, lidarData.rawSignal);
    end

case 2
    % WHU non-standard 1064 nm lidar

    % search files
    dataFiles = listfile(inDataPath, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        lidarData = readWHU1064_2(dataFiles{iFile}, varargin{:});

        oData.mTime = cat(2, oData.mTime, lidarData.mTime);
        oData.height = height;
        oData.sig1064 = cat(1, oData.sig1064, lidarData.rawSignal);
    end

case 3
    % CMA standard data format

    % search files
    dataFiles = listfile(inDataPath, p.Results.dataFilePattern);
    fprintf('[%s] %d data files were found!\n', tNow, length(dataFiles));

    for iFile = 1:length(dataFiles)
        [thisLidarType, thisSiteNo, thisFileTime, thisFileExt] = parseCmaLidarFilename(dataFiles{iFIle}, varargin{:});

        lidarData = readCmaLidarData(dataFiles{iFile}, varargin{:});
        
    end
case 4
otherwise
    error('LE:Err001', 'Unknown lidar data format %d', p.Results.dataFormat);
end

end