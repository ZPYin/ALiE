clc;
close all;
global LEToolboxInfo;

%% Parameter Definition
srcFiles = listfile(fullfile(LEToolboxInfo.projectDir, 'data', 'Airda'), '\w*.dat', 1);
stationNum = 54511;
deviceNumber = 'YLJ1';
lat = 29;
lon = 114;
alt = 14;
olHeight = 600;   % m

for iFile = 1:length(srcFiles)
    srcFile = srcFiles{iFile};

    %% Read Data
    srcData = readALADat(srcFile);
    srcData.recWL = [355, 355, 386, 407, 532, 532, 607, 1064];
    srcData.SigType = [1, 2, 3, 3, 1, 2, 3, 0];

    %% Write Data
    [ftYear, ftMonth, ftDay, ftHour, ftMin, ~] = datevec(srcData.mTime);
    intMinTime = datenum(ftYear, ftMonth, ftDay, ftHour, ftMin, 0);
    dstFile = fullfile(LEToolboxInfo.projectDir, 'data', 'Airda', sprintf('Z_CAWN_I_%d_%s_O_LIDAR_%s_L0.BIN', stationNum, datestr(intMinTime, 'yyyymmddHHMMSS'), deviceNumber));

    fid = fopen(dstFile, 'w');

    fwrite(fid, zeros(1, 7), 'ushort');
    fwrite(fid, zeros(1, 1), 'ushort');
    fwrite(fid, ones(1, 1), 'ushort');
    fwrite(fid, 1, 'uint');
    fwrite(fid, lon * 1e4, 'uint');
    fwrite(fid, lat * 1e4, 'uint');
    fwrite(fid, alt * 100, 'uint');
    fwrite(fid, zeros(1, 1), 'ushort');
    fwrite(fid, ones(1, 1), 'ushort');
    fwrite(fid, ftHour * 3600 + ftMin * 60, 'uint');
    fwrite(fid, ftHour * 3600 + (ftMin + 1) * 60 - 1, 'uint');
    fwrite(fid, floor(intMinTime - datenum(1970, 1, 1)), 'ushort');
    fwrite(fid, 90 / 8 * 180 / 4096, 'ushort');
    fwrite(fid, zeros(1, 1), 'ushort');
    fwrite(fid, [355, 532, 1064], 'ushort');
    fwrite(fid, length(srcData.channelLabel), 'ushort');

    for iCh = 1:length(srcData.channelLabel)
        fwrite(fid, iCh, 'ushort');
        fwrite(fid, bitshift(1, 14) + srcData.recWL(iCh), 'ushort');
        fwrite(fid, srcData.SigType(iCh), 'ushort');
        fwrite(fid, srcData.hRes(iCh) * 100, 'ushort');
        fwrite(fid, olHeight * 10, 'ushort');
        fwrite(fid, 60 + 16 * length(srcData.channelLabel) + size(srcData.rawSignal, 1) * 4 * (iCh - 1) + 1, 'uint');
        fwrite(fid, size(srcData.rawSignal, 1), 'ushort');
    end

    for iCh = 1:length(srcData.channelLabel)
        for iBin = 1:size(srcData.rawSignal, 1)
            fwrite(fid, srcData.rawSignal(iBin, iCh), 'float');
        end
    end

    fclose(fid);
end