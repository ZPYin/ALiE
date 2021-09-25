function [oData] = readREAL(file, varargin)
% READREAL read data of Wuhan University (WHU) ceilometer at 1064 nm.
% USAGE:
%    [oData] = readREAL(file)
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
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'nMaxBin', 2500, @isnumeric);

parse(p, file, varargin{:});

if exist(file, 'file') ~= 2
    errStruct.message = sprintf('REAL data file does not exist!\n%s', file);
    errStruct.identifier = 'LEToolbox:Err004';
    error(errStruct);
end

mTime = datenum(file((end-16):(end-4)), 'yymmdd-HHMMSS') + datenum(0, 1, 0, 8, 0, 0);

if p.Results.flagDebug
    fprintf('Reading %s\n', file);
end

%% read data
fid = fopen(file, 'r');

for iLine = 1:14
    fgetl(fid);
end

thisLine = fgetl(fid);
binWidthCell = strsplit(thisLine, '	');
binWidth = str2double(binWidthCell{1});

thisLine = fgetl(fid);
nPulseCell = strsplit(thisLine, '	');
nPulse = str2double(nPulseCell{1});

lidarData = textscan(fid, '%f%f%f%f%f%f', 'HeaderLines', 3, 'Delimiter', '\t');

fclose(fid);

sig532SH = lidarData{1};
sig532PH = lidarData{2};
sig532SL = lidarData{3};
sig532PL = lidarData{4};
sig607L = lidarData{5};
sig607H = lidarData{6};

%% deadtime correction
PC2PCR = 1 / (binWidth * 1e-9 * nPulse);
rawSignal = transpose([sig532SH, sig532PH, sig532SL, sig532PL, sig607L, sig607H]) .* PC2PCR;
height = (transpose(1:length(sig532SH)) - 56) * (binWidth * 0.3 / 2) - (binWidth * 0.3 / 4);   % distance. (m)

oData = struct;
oData.height = height;
oData.mTime = mTime;
oData.rawSignal = rawSignal;

end