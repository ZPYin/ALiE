function [oData] = readWHU1064_2(file, varargin)
% readWHU1064_2 read data of Wuhan University ceilometer at 1064 nm.
% USAGE:
%    [oData] = readWHU1064_2(file)
% INPUTS:
%    file: char
%        absolute paht of data file.
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

oData = struct;
oData.height = lidarData{1};   % distance. (m)
oData.rawSignal = lidarData{2};
oData.mTime = mTime;

end