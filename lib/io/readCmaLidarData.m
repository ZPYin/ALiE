function [data] = readCmaLidarData(file, varargin)
%READCMALIDARDATA read binary lidar data.
%Example:
%   [data] = readCmaLidarData(file)
%Inputs:
%   file: char
%       absolute path of the lidar data file.
%Outputs:
%   data: struct
%       metadata: struct
%       mTime: datenum
%           measurement stop time.
%       longitude: double
%       latitude: double
%       asl: double
%       elevation_angle: double
%       wavelength: array
%       nChs: double
%       chInfo: matrix (16 * channels)
%       backscatter: matrix (8000 * channels)
%History:
%   2021-02-07. First Edition by Zhenping
%Contact:
%   zp.yin@whu.edu.cn

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'file', @ischar);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, file, varargin{:});

data = struct();

if exist(file, 'file') ~= 2
    warning('Lidar data does not exist: %s', file);
    return;
end

%% read data

% parse file metadata
[lidarType, siteNo, ~, fileExt] = parse_lidar_filename(file);

if ~ strcmpi(fileExt, '.bin')
    warning('Invalid lidar data type: %s', file);
    return;
end

if p.Results.flagDebug
    fprintf('Reading %s\n', file);
end

% read raw data
fileID = fopen(file, 'r', 'ieee-le');

fileHeader = fread(fileID, 14, 'uint8');
fread(fileID, 2, 'uint8');   % Lidar raw backscatter
verNo = fread(fileID, 2, 'uint8');
fread(fileID, 4, 'uint8');   % site number
rawLon = fread(fileID, 2, 'uint8');
rawLat = fread(fileID, 2, 'uint8');
rawASL = fread(fileID, 2, 'uint8');
fread(fileID, 2, 'uint8');
fread(fileID, 2, 'uint8');   % detection mode 01: profiling
fread(fileID, 4, 'uint8');   % start time of the averaging. (seconds after 00:00)
rawStopTime = fread(fileID, 4, 'uint8');  % stop time of the averaging. (seconds after 00:00)
rawDate = fread(fileID, 2, 'uint8');   % Julian date: days after 1970-01-01
rawElevAng =fread(fileID, 2, 'uint8');
fread(fileID, 2, 'uint8');
rawTransWave1 = fread(fileID, 2, 'uint8');
rawTransWave2 = fread(fileID, 2, 'uint8');
rawTransWave3 = fread(fileID, 2, 'uint8');
rawChs = fread(fileID, 2, 'uint8');
rawChInfo = fread(fileID, [16, 16], 'uint8');

% obtain range bins
nBins = [];
if isempty(nBins)
    for iCh = 1:size(rawChInfo, 2)
        [thisChNo, ~, ~, ~, ~, ~, thisBins] = parse_chinfo_bits(rawChInfo(:, iCh));

        if (thisChNo <= 16) && (thisChNo >= 1)
            nBins = cat(2, nBins, thisBins);
        end
    end
end
rawBackscatter = fread(fileID, [max(nBins), 16], 'float32');

fclose(fileID);

% extract data
data.metadata.lidarType = lidarType;
data.metadata.siteNo = siteNo;
data.metadata.file_header = fileHeader;
data.metadata.version = uint8_2_double(verNo);
data.longitude = uint8_2_double(rawLon) / 8 * 180 / 4096;
data.latitude = uint8_2_double(rawLat) / 8 * 180 / 4096;
data.asl = uint8_2_double(rawASL);
data.elevation_angle = uint8_2_double(rawElevAng) / 8 * 180 / 4096;
data.mTime = datenum(1970, 1, 1) + uint8_2_double(rawDate) + ...
             datenum(0, 1, 0, 0, 0, uint8_2_double(rawStopTime));
data.wavelength = [uint8_2_double(rawTransWave1), ...
                   uint8_2_double(rawTransWave2), ...
                   uint8_2_double(rawTransWave3)];

data.nChs = uint8_2_double(rawChs);
data.chInfo = rawChInfo;
data.backscatter = rawBackscatter;

end