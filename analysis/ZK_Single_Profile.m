clc;

%% Parameter initialization
lidarType1 = 'L0601';
dataFormat1 = 3;
chTag1 = {'532p', '532s'};
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\externalChk\bin�ļ�\bin�ļ�\27��08�㵽27��20��\AL01_55461_00601_Lidar_20210927080018.bin';

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'nMaxBin', 2000, 'nBin', 2000);

%% data visualization
displayLidarProfile(oData1, chTag1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e9], 'rcsRange', [1e6, 1e14], 'bgRange', [-10, 10], 'gliding_window', 10);