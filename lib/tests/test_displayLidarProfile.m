clc;

%% Parameter initialization
projectDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
lidarType1 = 'L0103';
lidarType2 = 'WHU1064';
dataFormat1 = 3;
dataFormat2 = 1;
dataFile1 = fullfile(projectDir, 'data', 'CMA_Lidar_Data', 'AL02_L0103_54399_Lidar_20200525000405.bin');
dataFile2 = fullfile(projectDir, 'data', 'WHU1064', 'S001-NAP001-Standard-001-210909-015909.dat');

fprintf('Tested function: displayLidarProfile\n');
fprintf('Test dataset: \n%s\n%s\n', dataFile1, dataFile2);

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'chTag', {'532P', '532S', '355e', '607', '1064e'}, 'nMaxBin', 8000, 'nBin', 8000);
oData2 = readLidarData(fileparts(dataFile2), 'dataFormat', dataFormat2, 'dataFilePattern', rmext(basename(dataFile2)));

%% data visualization

% test
displayLidarProfile(oData1, 'figTitle', lidarType1);
displayLidarProfile(oData2, 'figTitle', lidarType2, 'sigRange', [1e2, 1e5], 'rcsRange', [1e6, 1e10], 'bgRange', [-10, 10], 'gliding_window', 10);

fprintf('Pass!!!\n');