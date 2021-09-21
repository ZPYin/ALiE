function [oData] = readREAL(file, varargin)
% readREAL read data of Wuhan University (WHU) ceilometer at 1064 nm.
% USAGE:
%    [oData] = readREAL(file)
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
addParameter(p, 'nMaxBin', 2500, @isnumeric);

parse(p, file, varargin{:});

if exist(file, 'file') ~= 2
    error('Data file does not exist.\n%s', file);
end

%% Parameter initialization
nPretrigger = 55;
deadtime = [3.5, 3.5, 3.5, 3.5, 3.5, 30.4];
bgRange = [25000, 30000];   % height range for background calculation. (m)

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
sig532SHCor = (sig532SH * PC2PCR) ./ (1 - deadtime(1) * 1e-9 * sig532SH .* PC2PCR) ./ PC2PCR;
sig532PHCor = (sig532PH * PC2PCR) ./ (1 - deadtime(2) * 1e-9 * sig532PH .* PC2PCR) ./ PC2PCR;
sig532SLCor = (sig532SL * PC2PCR) ./ (1 - deadtime(3) * 1e-9 * sig532SL .* PC2PCR) ./ PC2PCR;
sig532PLCor = (sig532PL * PC2PCR) ./ (1 - deadtime(4) * 1e-9 * sig532PL .* PC2PCR) ./ PC2PCR;
sig607LCor = (sig607L * PC2PCR) ./ (1 - deadtime(5) * 1e-9 * sig607L .* PC2PCR) ./ PC2PCR;
sig607HCor = (sig607H * PC2PCR) ./ (1 - deadtime(6) * 1e-9 * sig607H .* PC2PCR) ./ PC2PCR;

%% remove pre-triggers
if (p.Results.nMaxBin + nPretrigger) > length(sig532PHCor)
    errStruct.message = sprintf('Wrong configuration for nMaxBin. nMaxBin is too large (%f > %f)', p.Results.nMaxBin, length(lidarData{1}) - nPretrigger);
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end
sig532SHCor = sig532SHCor((nPretrigger + 1):(nPretrigger + p.Results.nMaxBin));
sig532PHCor = sig532PHCor((nPretrigger + 1):(nPretrigger + p.Results.nMaxBin));
sig532SLCor = sig532SLCor((nPretrigger + 1):(nPretrigger + p.Results.nMaxBin));
sig532PLCor = sig532PLCor((nPretrigger + 1):(nPretrigger + p.Results.nMaxBin));
sig607LCor = sig607LCor((nPretrigger + 1):(nPretrigger + p.Results.nMaxBin));
sig607HCor = sig607HCor((nPretrigger + 1):(nPretrigger + p.Results.nMaxBin));
height = transpose(1:length(sig532SHCor)) * (binWidth * 0.3 / 2) - (binWidth * 0.3 / 4);   % distance. (m)

%% remove background
bgInd = (height >= bgRange(1)) & (height <= bgRange(2));
bg532SH = nanmean(sig532SHCor(bgInd));
bg532PH = nanmean(sig532PHCor(bgInd));
bg532SL = nanmean(sig532SLCor(bgInd));
bg532PL = nanmean(sig532PLCor(bgInd));
bg607L = nanmean(sig607LCor(bgInd));
bg607H = nanmean(sig607HCor(bgInd));
sig532SHNoBG = sig532SHCor - bg532SH;
sig532PHNoBG = sig532PHCor - bg532PH;
sig532SLNoBG = sig532SLCor - bg532SL;
sig532PLNoBG = sig532PLCor - bg532PL;
sig607LNoBG = sig607LCor - bg607L;
sig607HNoBG = sig607HCor - bg607H;

oData = struct;
oData.height = height;
oData.mTime = mTime;
oData.sig532SHNoBG = sig532SHNoBG;
oData.sig532PHNoBG = sig532PHNoBG;
oData.sig532SLNoBG = sig532SLNoBG;
oData.sig532PLNoBG = sig532PLNoBG;
oData.sig607LNoBG = sig607LNoBG;
oData.sig607HNoBG = sig607HNoBG;
oData.bg532SH = bg532SH;
oData.bg532PH = bg532PH;
oData.bg532SL = bg532SL;
oData.bg532PL = bg532PL;
oData.bg607L = bg607L;
oData.bg607H = bg607H;

end