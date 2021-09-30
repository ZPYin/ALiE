clc;

%% Parameter initialization
lidarType1 = 'REAL';
dataFormat1 = 5;
chTag1 = {'532sh', '532ph', '532sl', '532pl', '607l', '607h'};
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\REAL\2021-09-23\S001-NAP001-Test CMA-001-210923-081127.dat';

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'nMaxBin', 2048, 'nBin', 2000);

%% data visualization
displayLidarProfile(oData1, chTag1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e9], 'rcsRange', [1e6, 1e14], 'bgRange', [-10, 10], 'gliding_window', 10);