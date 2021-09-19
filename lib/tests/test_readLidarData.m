clc;

%% Parameter initialization
projectDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));
dataFile1 = fullfile(projectDir, 'data', 'CMA_Lidar_Data', 'AL02_L0103_54399_Lidar_20200525000405.bin');
dataFile2 = fullfile(projectDir, 'data', 'CMA_Lidar_Data', 'AL01_L0102_54511_Lidar_20200528044900.bin');

fprintf('Tested function: readLidarData\n');
fprintf('Test dataset: \n%s\n%s\n', dataFile1, dataFile2);

%% read data
oData1 = readCmaLidarData(dataFile1, {'532P', '532S', '355e', '607', '1064e'}, 'nBin', 8000);
oData2 = readCmaLidarData(dataFile2, {'532P', '532S'}, 'nBin', 4096);

fprintf('Pass!!!\n');