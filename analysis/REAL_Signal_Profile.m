clc;

%% Parameter initialization
lidarType1 = 'REAL';
dataFormat1 = 5;
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\REAL\2021-09-23\S001-NAP001-Test CMA-001-210923-081127.dat';

fprintf('Tested function: displayLidarProfile\n');
fprintf('Test dataset: \n%s\n', dataFile1);

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'chTag', {'532P', '532S', '607'}, 'nMaxBin', 2048, 'nBin', 2000);

%% data visualization

% test
displayLidarProfile(oData1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e5], 'rcsRange', [1e6, 1e10], 'bgRange', [-10, 10], 'gliding_window', 10);

fprintf('Pass!!!\n');