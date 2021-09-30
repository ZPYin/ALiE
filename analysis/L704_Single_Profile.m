clc;

%% Parameter initialization
lidarType1 = 'L0102';
dataFormat1 = 3;
chTag1 = {'355p', '355s', '532p', '532s', '387', '407', '607', '1064e'};
dataFile1 = 'D:\Data\CMA_Lidar_Comparison\externalChk\L7\AL02_L0102_54511_Lidar_20210927093733.bin';

%% read data
oData1 = readLidarData(fileparts(dataFile1), 'dataFormat', dataFormat1, 'dataFilePattern', rmext(basename(dataFile1)), 'nMaxBin', 1700, 'nBin', 1800);

%% data visualization
displayLidarProfile(oData1, chTag1, 'figTitle', lidarType1, 'sigRange', [1e2, 1e9], 'rcsRange', [1e6, 1e14], 'bgRange', [-10, 10], 'gliding_window', 10);