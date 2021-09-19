function [data] = readCmaLidarData(file, chTag, varargin)
% READCMALIDARDATA read CMA standard binary lidar data.
% USAGE:
%    [data] = readCmaLidarData(file, chTag)
% INPUTS:
%    file: char
%        absolute path of the lidar data file.
%    chTag: cell
%        channel identifier for each channel.
%        355e; 355p; 355s; 387; 407; 532e; 532p; 532s; 607; 1064e; 1064p; 1064s
% KEYWORDS:
%    flagDebug: logical
%        flag to control debugging message output (default: false).
%    nMaxBin: numeric
%        maximum bins to be exported.
%    nBin: numeric
%        number of bins in the lidar data file (default: 8000).
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
%        sig355: double
%            elastic signal at 355 nm.
%        sig355P: double
%        sig355S: double
%        sig387: double
%        sig407: double
%        sig532: double
%        sig532P: double
%        sig532S: double
%        sig607: double
%        sig1064: double
%        sig1064P: double
%        sig1064S: double
% HISTORY:
%    2021-09-18: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'file', @ischar);
addRequired(p, 'chTag', @iscell);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'nMaxBin', [], @isnumeric);
addParameter(p, 'nBin', 8000, @isnumeric);

parse(p, file, chTag, varargin{:});

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
[lidarType, siteNo, ~, fileExt] = parseCmaLidarFilename(file);

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
rawChInfo = fread(fileID, [16, nCh], 'uint8');   % metadata of each channel
rawBackscatter = fread(fileID, [p.Results.nBin, nCh], 'float32');   % backscatter signal

% decode channel metadata
ChNo = [];   % channel index
detectMode = [];   % detection mode: AD; PC; Merge
ChType = [];   % channel type: elastic, Raman or polarization
hRes = [];   % range resolution. (m)
hFOV = [];   % height of blind zone. (m)
firstBin = [];   % pointer of first bin in binary file
nBin = [];   % number of bins
for iCh = 1:nCh
    [thisChNo, thisDetectMode, thisChType, thisHRes, thisHFOV, thisFirstBin, thisNBin] = parseCmaLidarInfo(rawChInfo(:, iCh));

    ChNo = cat(2, ChNo, thisChNo);
    detectMode = cat(2, detectMode, thisDetectMode);
    ChType = cat(2, ChType, thisChType);
    hRes = cat(2, hRes, thisHRes);
    hFOV = cat(2, hFOV, thisHFOV);
    firstBin = cat(2, firstBin, thisFirstBin);
    nBin = cat(2, nBin, thisNBin);
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
data.mTime = datenum(1970, 1, 1) + uint8_2_double(rawDate) + datenum(0, 1, 0, 0, 0, uint8_2_double(rawStopTime));
data.height = transpose(1:nMaxBin) * unique(hRes) * sin(data.elevation_angle ./ 180 * pi);   % (m)
data.longitude = uint8_2_double(rawLon) / 8 * 180 / 4096;
data.latitude = uint8_2_double(rawLat) / 8 * 180 / 4096;
data.asl = uint8_2_double(rawASL);
data.nEffBin = unique(nBin);
data.hBlindZone = hFOV;
data.metadata.lidarType = lidarType;
data.metadata.siteNo = siteNo;
data.metadata.file_header = fileHeader;
data.metadata.version = uint8_2_double(verNo);

if length(chTag) ~= nCh
    errStruct.message = 'Wrong configuration for chTag';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

% determine channel type
for iCh = 1:nCh
    switch lower(chTag{iCh})
    case '355e'
        data.sig355 = rawBackscatter(1:nMaxBin, iCh);
    case '355p'
        data.sig355P = rawBackscatter(1:nMaxBin, iCh);
    case '355s'
        data.sig355S = rawBackscatter(1:nMaxBin, iCh);
    case '387'
        data.sig387 = rawBackscatter(1:nMaxBin, iCh);
    case '407'
        data.sig407 = rawBackscatter(1:nMaxBin, iCh);
    case '532e'
        data.sig532 = rawBackscatter(1:nMaxBin, iCh);
    case '532p'
        data.sig532P = rawBackscatter(1:nMaxBin, iCh);
    case '532s'
        data.sig532S = rawBackscatter(1:nMaxBin, iCh);
    case '607'
        data.sig607 = rawBackscatter(1:nMaxBin, iCh);
    case '1064e'
        data.sig1064 = rawBackscatter(1:nMaxBin, iCh);
    case '1064p'
        data.sig1064P = rawBackscatter(1:nMaxBin, iCh);
    case '1064s'
        data.sig1064S = rawBackscatter(1:nMaxBin, iCh);
    otherwise
        errStruct.message = sprintf('Wrong configuration for chTag: %s', chTag{iCh});
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end
end

end