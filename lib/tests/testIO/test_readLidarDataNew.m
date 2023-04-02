global LEToolboxInfo

dataFile1 = fullfile(LEToolboxInfo.projectDir, 'data', 'bdb-56146', 'Z_CAWN_I_53772_20230225000000_O_LIDAR_YLJ2_L0.BIN');
dataFile2 = fullfile(LEToolboxInfo.projectDir, 'data', 'bdb-56146', 'Z_CAWN_I_53772_20230225000100_O_LIDAR_YLJ2_L0.BIN');

fprintf('Tested function: read_CMA_L0\n');
fprintf('Test dataset: \n%s\n%s\n', dataFile1, dataFile2);

try
    %% read data
    oData1 = read_CMA_L0(dataFile1, 'nMaxBin', 1900);
    oData2 = read_CMA_L0(dataFile2, 'nMaxBin', 1900);
catch
    oData1 = [];
    oData2 = [];
end

assert(~ isempty(oData1));
assert(~ isempty(oData2));