function [lidarType, siteNo, fileTime, fileExt] = parseCmaLidarFilename(file, varargin)
% PARSECMALIDARFILENAME parse metadata from the filename.
% USAGE:
%    lidarType = parseCmaLidarFilename('AL01_L0108_54419_Lidar_20200101000023.bin')
% INPUTS:
%    file: char
%        absolute path or filename of the lidar data.
%        i.e., 'AL01_L0108_54419_Lidar_20200101000023.bin'
% KEYWORDS:
%    flagDebug: logical
% OUTPUTS:
%    lidarType: char
%        lidar type. (i.e., 'AL01_L0108')
%    siteNo: char
%        label of the observation site. (i.e., '54419')
%    fileTime: datenum
%        file created time.
%    fileExt: char
%        file extension. (i.e., '.bin')
% HISTORY:
%    2021-09-24: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'file', @ischar);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, file, varargin{:});

lidarType = '';
siteNo = '';
fileTime = [];
fileExt = '';

if length(file) < 36
    warning('Invalid filename for lidar data: %s', file);
    return;
end

[~, filename, fileExt] = fileparts(file);

if ~ strcmpi(fileExt, '.bin')
    warning('binary file is expected. %s.', file);
end

fileTime = datenum(filename((end - 13):end), 'yyyymmddHHMMSS');
instrument = filename((end - 19):(end - 15));

if ~ strcmpi(instrument, 'lidar')
    warning('Invalid filename for lidar data: %s', file);
    return
end

siteNo = filename((end - 25):(end - 21));
lidarType = filename(1:(end - 27));

end