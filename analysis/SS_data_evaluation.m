clc;

%% Parameter initialization
lidarType1 = 'L0109';
dataFormat1 = 3;
chTag1 = {'532p', '532s'};
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\externalChk\ǳ���Ƽ���Ҫ����ĺ������Lidar_20210929\Lidar_20210929\AL01_L0109_54597_Lidar_20210929000100.bin';

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'nMaxBin', 1000, 'nBin', 1000);

%% data visualization
displayLidarProfile(oData1, chTag1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e9], 'rcsRange', [1e6, 1e14], 'bgRange', [-10, 10], 'gliding_window', 10);