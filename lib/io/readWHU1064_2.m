function [oData] = readWHU1064_2(file, varargin)
% READWHU1064_2 read data of Wuhan University ceilometer at 1064 nm.
% USAGE:
%    [oData] = readWHU1064_2(file)
% INPUTS:
%    file: char
%        absolute paht of data file.
% KEYWORDS:
%    flagDebug: logical
%    nMaxBin: numeric
% OUTPUTS:
%    oData: struct
%        height: array
%        rawSignal: matrix
%        mTime: numeric
% HISTORY:
%    2021-09-06: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'file', @ischar);
addParameter(p, 'flagDebug', false, @islogical)
addParameter(p, 'nMaxBin', 1300, @isnumeric)

parse(p, file, varargin{:});

if exist(file, 'file') ~= 2
    error('Data file does not exist.\n%s', file);
end

[~, fileBasename, ~] = fileparts(file);
mTime = datenum(fileBasename(1:15), 'yyyymmdd-HHMMSS');

if p.Results.flagDebug
    fprintf('Reading %s\n', file);
end

fid = fopen(file, 'r');

lidarData = textscan(fid, '%f%f', 'HeaderLines', 0, 'Delimiter', '\t');

fclose(fid);

if length(lidarData{1}) < p.Results.nMaxBin
    errStruct.message = sprintf('Wrong configuration for nMaxBin. nMaxBin is too large (%f > %f)', p.Results.nMaxBin, length(lidarData{1}));
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

oData = struct;
oData.height = lidarData{1}(1:p.Results.nMaxBin);   % distance. (m)
oData.rawSignal = transpose(lidarData{2}(1:p.Results.nMaxBin));
oData.mTime = mTime;

end