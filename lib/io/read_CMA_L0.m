function [lidarData, chTag] = read_CMA_L0(dataFile, varargin)
% READ_CMA_L0 read CMA Level0 data (²¹¶Ì°å¹¤³Ì)
%
% USAGE:
%    [lidarData] = read_CMA_L0(dataFile)
%
% INPUTS:
%    dataFile: char
%        absolute path of data file.
%
% KEYWORDS:
%    flagDebug: logical
%        flagDebug mode.
%    nMaxBin: numeric
%        number of range bins read out from data file.
%    visible: char
%        whether to display figure of signal.
%
% OUTPUTS:
%    lidarData: struct
%        fileTime
%        product
%        version
%        deviceNumber
%        longtitude
%        latitude
%        elevation
%        scanMode
%        startTime
%        endTime
%        elevationAngle
%        wavelength1
%        wavelength2
%        wavelength3
%        numChannel
%        channelIndex
%        digitier
%            0: AD; 1: PC; 2: ÈÚºÏ
%        recWavelength
%        type
%            1: ·ÇÆ«Õñ; 2: Æ«Õñ; 3: Æ«ÕñS; 4: À­Âü
%        resolution
%        overlap
%        nBin
%        rawSignal: bin * channel
%    chTag: cell
%        channel label.
%
% HISTORY:
%    2023-03-13: first edition by Zhenping
% .. Authors: - zp.yin@whu.edu.cn

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'dataFile', @ischar);
addParameter(p, 'nMaxBin', 2000, @isnumeric);
addParameter(p, 'flagDebug', false, @islogical);
addParameter(p, 'visible', 'off', @ischar);

parse(p, dataFile, varargin{:});

if p.Results.flagDebug
    fprintf('Reading %s\n', dataFile);
end

%% Parse Filename Info
fileInfo = parseFilenameInfo(dataFile);

%% Read Data
isNotDataL0 = ~ strcmp(fileInfo.dataType, 'L0');
if isNotDataL0
    warning('Not expected Level0 data.');
    return;
end

lidarData = struct();

fid = fopen(dataFile, 'r');
fread(fid, 7, 'short');
lidarData.product = fread(fid, 1, 'ushort');
lidarData.version = fread(fid, 1, 'ushort');
lidarData.deviceNumber = fread(fid, 1, 'uint');
lidarData.longtitude = fread(fid, 1, 'uint') / 1e4;
lidarData.latitude = fread(fid, 1, 'uint') / 1e4;
lidarData.elevation = fread(fid, 1, 'uint') / 1e2;
fread(fid, 1, 'ushort');
lidarData.scanMode = fread(fid, 1, 'ushort');
startTime = fread(fid, 1, 'uint');
endTime = fread(fid, 1, 'uint');
date = fread(fid, 1, 'ushort');
lidarData.startTime = datenum(1970, 1, 1) + date + datenum(0, 1, 0, 0, 0, startTime);
lidarData.endTime = datenum(1970, 1, 1) + date + datenum(0, 1, 0, 0, 0, endTime);
lidarData.elevationAngle = fread(fid, 1, 'ushort') / 8 * (180 / 4096);
fread(fid, 1, 'ushort');
lidarData.wavelength1 = fread(fid, 1, 'ushort');
lidarData.wavelength2 = fread(fid, 1, 'ushort');
lidarData.wavelength3 = fread(fid, 1, 'ushort');
lidarData.numChannel = fread(fid, 1, 'ushort');
lidarData.fileTime = fileInfo.createTime;

lidarData.channelIndex = [];
lidarData.digitier = [];
lidarData.recWavelength = [];
lidarData.type = [];
lidarData.resolution = [];
lidarData.overlap = [];
lidarData.nBin = [];

for iCh = 1:lidarData.numChannel
    lidarData.channelIndex = cat(2, lidarData.channelIndex, fread(fid, 1, 'ushort'));
    tmp = fread(fid, 1, 'ushort');
    tmp1 = dec2bin(tmp, 16);
    lidarData.digitier = cat(2, lidarData.digitier, bin2dec(tmp1(1:2)));
    lidarData.recWavelength = cat(2, lidarData.recWavelength, bin2dec(tmp1(3:end)));
    lidarData.type = cat(2, lidarData.type, fread(fid, 1, 'ushort'));
    lidarData.resolution =  fread(fid, 1, 'ushort') / 100;
    lidarData.overlap = cat(2, lidarData.overlap, fread(fid, 1, 'ushort') / 10);
    a= fread(fid, 1, 'uint');
    nBin = fread(fid, 1, 'ushort');

    if p.Results.nMaxBin > nBin
        errStruct.message = sprintf('Wrong configuration for nMaxBin (> %d)', nBin);
        errStruct.identifier = 'LEToolbox:Err003';
        error(errStruct);
    end

    lidarData.nBin = p.Results.nMaxBin;
end

chTag = cell(0);
for iCh = 1:lidarData.numChannel
    chTypeIndenfier = '';

    switch lidarData.type(iCh)
    case 0
        chTypeIndenfier = 'e';
    case 1
        chTypeIndenfier = 'p';
    case 2
        chTypeIndenfier = 's';
    case 3
        chTypeIndenfier = '';
    otherwise
        errStruct.message = 'Data with unknown channel type';
        errStruct.identifier = 'LEToolbox:Err002';
        error(errStruct);
    end

    chTag = cat(2, chTag, sprintf('%d%s', lidarData.recWavelength(iCh), chTypeIndenfier));
end

lidarData.rawSignal = nan(p.Results.nMaxBin, lidarData.numChannel);
for iCh = 1:lidarData.numChannel
    rawSignal = fread(fid, nBin, 'float');
    lidarData.rawSignal(:, iCh) = rawSignal(1:p.Results.nMaxBin, :);
end

fclose(fid);

%% Display
if strcmp(p.Results.visible, 'on')
    figure('Position', [0, 10, 350, 400], 'Units', 'Pixels', 'Color', 'w');

    for iCh = 1:lidarData.numChannel
        typeStr = {'·ÇÆ«Õñ', 'Æ«Õñ', 'Æ«ÕñS', 'À­Âü'};

        plot(lidarData.rawSignal(:, iCh), lidarData.resolution * (1:lidarData.nBin), 'LineWidth', 2, 'DisplayName', sprintf('%d-%s', lidarData.recWavelength(iCh), typeStr{lidarData.type(iCh) + 1})); hold on;
    end

    ylabel('¸ß¶È (Ã×)');
    xlabel('ÐÅºÅ');

    set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Box', 'on');
    legend('Location', 'NorthEast');
end

end