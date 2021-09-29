function [data] = readCmaLidarData(file, varargin)
% READCMALIDARDATA read CMA standard binary lidar data.
% USAGE:
%    [data] = readCmaLidarData(file)
% INPUTS:
%    file: char
%        absolute path of the lidar data file.
% KEYWORDS:
%    flagDebug: logical
%        flag to control debugging message output (default: false).
%    nMaxBin: numeric
%        maximum bins to be exported.
%    nBin: numeric
%        number of bins in the lidar data file (default: 8000).
%    flagFilenameTime: logical
% OUTPUTS:
%    data: struct
%        mTime: datenum
%            measurement stop time.
%        longitude: double
%        latitude: double
%        asl: double
%        elevation_angle: double
%        height: double
%        nEffBin: double
%        metadata: struct
%        hBlindZone: double
%            height of blind zone for each channel. (m)
%        rawSignal: double (nCh x height)
%            raw signal.
% HISTORY:
%    2021-09-18: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'file', @ischar);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'flagFilenameTime', false, @islogical);
addParameter(p, 'nMaxBin', [], @isnumeric);
addParameter(p, 'nBin', [], @isnumeric);

parse(p, file, varargin{:});

%% parameter initialization
data = struct();
data.mTime = [];
data.height = [];

% determine maximum bin number
if p.Results.nMaxBin > p.Results.nBin
    errStruct.message = 'Wrong configuration for nMaxBin';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

% determine the existence of lidar data file
if exist(file, 'file') ~= 2
    warning('Lidar data does not exist: %s', file);
    return;
end

%% read data
% parse file metadata
[lidarType, siteNo, filenameTime, fileExt] = parseCmaLidarFilename(file);

if ~ strcmpi(fileExt, '.bin')
    warning('Invalid lidar data type: %s', file);
    return;
end

% debug message
if p.Results.flagDebug
    fprintf('Reading %s\n', file);
end

% read raw data
fileID = fopen(file, 'r', 'ieee-le');

fileHeader = fread(fileID, 14, 'uint8');
fread(fileID, 2, 'uint8');   % Lidar raw backscatter
verNo = fread(fileID, 2, 'uint8');   % data version number
fread(fileID, 4, 'uint8');   % site number
rawLon = fread(fileID, 2, 'uint8');   % longitude
rawLat = fread(fileID, 2, 'uint8');   % latitude
rawASL = fread(fileID, 2, 'uint8');   % above sea level. (m)
fread(fileID, 2, 'uint8');
fread(fileID, 2, 'uint8');   % detection mode 01: profiling
fread(fileID, 4, 'uint8');   % start time of the averaging. (seconds after 00:00)
rawStopTime = fread(fileID, 4, 'uint8');  % stop time of the averaging. (seconds after 00:00)
rawDate = fread(fileID, 2, 'uint8');   % Julian date: days after 1970-01-01
rawElevAng =fread(fileID, 2, 'uint8');   % elevation angle
fread(fileID, 2, 'uint8');
fread(fileID, 2, 'uint8');   % wavelength 1
fread(fileID, 2, 'uint8');   % wavelength 2
fread(fileID, 2, 'uint8');   % wavelength 3
rawChs = fread(fileID, 2, 'uint8');   % number of detection channels.
nCh = uint8_2_double(rawChs);
rawChInfo = fread(fileID, [16, 16], 'uint8');   % metadata of each channel

% decode channel metadata
ChNo = [];   % channel index
detectMode = [];   % detection mode: AD; PC; Merge
recWL = [];
ChType = [];   % channel type: elastic, Raman or polarization
hRes = [];   % range resolution. (m)
hFOV = [];   % height of blind zone. (m)
firstBin = [];   % pointer of first bin in binary file
nBin = [];   % number of bins
for iCh = 1:nCh
    [thisChNo, thisDetectMode, thisRecWL, thisChType, thisHRes, thisHFOV, thisFirstBin, thisNBin] = parseCmaLidarInfo(rawChInfo(:, iCh));

    ChNo = cat(2, ChNo, thisChNo);
    detectMode = cat(2, detectMode, thisDetectMode);
    recWL = cat(2, recWL, thisRecWL);
    ChType = cat(2, ChType, thisChType);
    hRes = cat(2, hRes, thisHRes);
    hFOV = cat(2, hFOV, thisHFOV);
    firstBin = cat(2, firstBin, thisFirstBin);
    nBin = cat(2, nBin, thisNBin);
end

if isempty(p.Results.nBin)
    nBin = max(nBin);
else
    nBin = p.Results.nBin;
end

rawBackscatter = fread(fileID, Inf, 'float32');   % backscatter signal
if length(rawBackscatter) >= 8000*16
    % filled with 8000 bins
    rawSignal = NaN(nCh, length(rawBackscatter) / 16);
    for iCh = 1:nCh
        rawSignal(iCh, :) = rawBackscatter(((iCh - 1) * length(rawBackscatter) / 16 + 1):(iCh * length(rawBackscatter) / 16));
    end
else
    % non-filled
    rawSignal = NaN(nCh, length(rawBackscatter) / nCh);
    for iCh = 1:nCh
        rawSignal(iCh, :) = rawBackscatter(((iCh - 1) * length(rawBackscatter) / nCh + 1):(iCh * length(rawBackscatter) / nCh));
    end
end

fclose(fileID);

% determine data validity
isSameBins = (length(unique(nBin)) == 1);
isSameHRes = (length(unique(hRes)) == 1);
if (~ isSameBins) || (~ isSameHRes)
    errStruct.message = 'Data with different settings';
    errStruct.identifier = 'LEToolbox:Err002';
    error(errStruct);
end

% extract data
if isempty(p.Results.nMaxBin)
    nMaxBin = unique(nBin);
else
    nMaxBin = p.Results.nMaxBin;
end
data.elevation_angle = uint8_2_double(rawElevAng) / 8 * 180 / 4096;
if ~ p.Results.flagFilenameTime
    data.mTime = datenum(1970, 1, 1) + uint8_2_double(rawDate) + datenum(0, 1, 0, 0, 0, uint8_2_double(rawStopTime));
else
    data.mTime = filenameTime;
end
% data.height = transpose(1:nMaxBin) * unique(hRes) * sin(data.elevation_angle ./ 180 * pi);   % (m)
data.height = transpose(1:nMaxBin) * unique(hRes) * sin(90 ./ 180 * pi);   % (m)
data.longitude = uint8_2_double(rawLon) / 8 * 180 / 4096;
data.latitude = uint8_2_double(rawLat) / 8 * 180 / 4096;
data.asl = uint8_2_double(rawASL);
data.nEffBin = unique(nBin);
data.hBlindZone = hFOV;
data.metadata.lidarType = lidarType;
data.metadata.siteNo = siteNo;
data.metadata.file_header = fileHeader;
data.metadata.version = uint8_2_double(verNo);

data.rawSignal = rawSignal(:, 1:nMaxBin);

end