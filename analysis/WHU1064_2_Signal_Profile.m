clc;

%% Parameter initialization
lidarType1 = 'WHU1064_2';
dataFormat1 = 2;
chTag1 = {'1064e'};
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\WHU1064_2\25\20210925-200410-000.00-090.00-0030-02500-20.00-01-114.209999-30.309999-0000-000-00.txt';

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'nMaxBin', 1200, 'nBin', 1300);

%% data visualization
displayLidarProfile(oData1, chTag1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e9], 'rcsRange', [1e6, 1e14], 'bgRange', [-10, 10], 'gliding_window', 10, 'hRange', [0, 10000]);