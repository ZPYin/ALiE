clc;

%% Parameter initialization
lidarType1 = 'L0110';
dataFormat1 = 3;
chTag1 = {'532p', '532s'};
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\L0110\RayleighFit_09_21\20210921\AL01_L0110_54424_Lidar_20210921000023.bin';

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'nMaxBin', 4000, 'nBin', 5000);

%% data visualization
displayLidarProfile(oData1, chTag1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e9], 'rcsRange', [1e6, 1e14], 'bgRange', [-10, 10], 'gliding_window', 10);