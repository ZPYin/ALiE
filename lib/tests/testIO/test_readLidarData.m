global LEToolboxInfo

dataFile1 = fullfile(LEToolboxInfo.projectDir, 'data', 'CMA_Lidar_Data', 'AL02_L0103_54399_Lidar_20200525000405.bin');
dataFile2 = fullfile(LEToolboxInfo.projectDir, 'data', 'CMA_Lidar_Data', 'AL01_L0102_54511_Lidar_20200528044900.bin');

fprintf('Tested function: readLidarData\n');
fprintf('Test dataset: \n%s\n%s\n', dataFile1, dataFile2);

try
    %% read data
    oData1 = readCmaLidarData(dataFile1, 'nBin', 8000);
    oData2 = readCmaLidarData(dataFile2, 'nBin', 4096);
catch
    oData1 = [];
    oData2 = [];
end

assert(~ isempty(oData1));
assert(~ isempty(oData2));