function [oData] = readWHU1064(file, varargin)
% READWHU1064 read data of Wuhan University (WHU) ceilometer at 1064 nm.
% USAGE:
%    [oData] = readWHU1064(file)
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
addParameter(p, 'flagDebug', false, @islogical);

parse(p, file, varargin{:});

if exist(file, 'file') ~= 2
    error('Data file does not exist.\n%s', file);
end

mTime = datenum(file((end-16):(end-4)), 'yymmdd-HHMMSS') + datenum(0, 1, 0, 8, 0, 0);

if p.Results.flagDebug
    fprintf('Reading %s\n', file);
end

fid = fopen(file, 'r');

lidarData = textscan(fid, '%f', 'HeaderLines', 19, 'Delimiter', ' ');

fclose(fid);

oData = struct;
oData.height = ((1:length(lidarData{1})) - 1) * 15 + 7.5;   % distance. (m)
oData.rawSignal = lidarData{1};
oData.mTime = mTime;

end