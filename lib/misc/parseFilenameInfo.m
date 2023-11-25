function [fileInfo] = parseFilenameInfo(fileStr, varargin)
% PARSEFILENAMEINFO parse filename information.
%
% USAGE:
%    [fileInfo] = parseFilenameInfo(fileStr)
%
% INPUTS:
%    fileStr: char
%        filename char array.
%
% OUTPUTS:
%    fileInfo: struct
%        stationNumber: numeric
%        createTime: datenum
%        fileType: char
%        deviceIdent: char
%        equipType: char
%        dataType: char
%
% HISTORY:
%    2023-03-12: first edition by Zhenping
% .. Authors: - zp.yin@whu.edu.cn

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'fileStr', @ischar);
addParameter(p, 'debug', false, @islogical);

parse(p, fileStr, varargin{:});

[~, filename, ~] = fileparts(fileStr);
subStrs = strsplit(filename, '_');

invalidDataFile = (~ strcmp(subStrs{1}, 'Z')) || (~ strcmp(subStrs{2}, 'CAWN')) || (~ strcmp(subStrs{3}, 'I')) || (~ strcmp(subStrs{7}, 'LIDAR'));

if (invalidDataFile)
    warning('Invalid CMA data file.');
end

fileInfo = struct();
fileInfo.stationNumber = str2double(subStrs{4});
fileInfo.createTime = datenum(subStrs{5}, 'yyyymmddHHMMSS');
fileInfo.fileType = subStrs{6};
fileInfo.deviceIdent = subStrs{7};
fileInfo.equipType = subStrs{8};
fileInfo.dataType = subStrs{9};

end