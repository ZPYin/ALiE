% Convert the EARLINET test data (ASCII) to NetCDF4 files
%
% Author: Zhenping Yin
% UpdateTime: 2024-05-20

clc;
close all;

%% Parameter Definition
oriDataPath = 'C:\Users\zhenp\Documents\Coding\Matlab\ALiE\data\EARLINET_test_dataset\ASCII';   % the original data path (of EARLINET ASCII files)
dstDataPath = 'C:\Users\zhenp\Documents\Coding\Matlab\ALiE\data\EARLINET_test_dataset\NC';   % the destination data path (of converted NC files)

%% Read Data

% 355 elastic signal
files355 = listfile(fullfile(oriDataPath, '355'), '\w*txt', 1);
height355 = [];
sig355 = [];
for iFile = 1:length(files355)
    fid = fopen(files355{iFile}, 'r');

    dataTmp = textscan(fid, '%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);

    fclose(fid);

    height355 = dataTmp{1};
    sig355 = cat(2, sig355, dataTmp{2});
end

% 532 elastic signal
files532 = listfile(fullfile(oriDataPath, '532'), '\w*txt', 1);
height532 = [];
sig532 = [];
for iFile = 1:length(files532)
    fid = fopen(files532{iFile}, 'r');

    dataTmp = textscan(fid, '%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);

    fclose(fid);

    height532 = dataTmp{1};
    sig532 = cat(2, sig532, dataTmp{2});
end

% 1064 elastic signal
files1064 = listfile(fullfile(oriDataPath, '1064'), '\w*txt', 1);
height1064 = [];
sig1064 = [];
for iFile = 1:length(files1064)
    fid = fopen(files1064{iFile}, 'r');

    dataTmp = textscan(fid, '%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);

    fclose(fid);

    height1064 = dataTmp{1};
    sig1064 = cat(2, sig1064, dataTmp{2});
end

% 386 elastic signal
files386 = listfile(fullfile(oriDataPath, 'Raman1'), '\w*txt', 1);
height386 = [];
sig386 = [];
for iFile = 1:length(files386)
    fid = fopen(files386{iFile}, 'r');

    dataTmp = textscan(fid, '%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);

    fclose(fid);

    height386 = dataTmp{1};
    sig386 = cat(2, sig386, dataTmp{2});
end

% 607 elastic signal
files607 = listfile(fullfile(oriDataPath, 'Raman2'), '\w*txt', 1);
height607 = [];
sig607 = [];
for iFile = 1:length(files607)
    fid = fopen(files607{iFile}, 'r');

    dataTmp = textscan(fid, '%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);

    fclose(fid);

    height607 = dataTmp{1};
    sig607 = cat(2, sig607, dataTmp{2});
end

% aerosol optical properties
filesSlv355 = fullfile(oriDataPath, 'Solutions', 'aerowv1.000.txt');
filesSlv532 = fullfile(oriDataPath, 'Solutions', 'aerowv2.000.txt');
filesSlv1064 = fullfile(oriDataPath, 'Solutions', 'aerowv3.000.txt');

fid = fopen(filesSlv355, 'r');
dataTmp355 = textscan(fid, '%f%f%f%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);
fclose(fid);

fid = fopen(filesSlv532, 'r');
dataTmp532 = textscan(fid, '%f%f%f%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);
fclose(fid);

fid = fopen(filesSlv1064, 'r');
dataTmp1064 = textscan(fid, '%f%f%f%f%f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 9);
fclose(fid);

heightSlv355 = dataTmp355{1};
pressure = dataTmp355{2};
temperature = dataTmp355{3};
aExt355 = dataTmp355{4};
aLR355 = dataTmp355{5};
aExt532 = dataTmp532{4};
aLR532 = dataTmp532{5};
aExt1064 = dataTmp1064{4};
aLR1064 = dataTmp1064{5};

%% Signal Preprocessing

% background subtract
sigNoBg355 = sig355 - repmat(mean(sig355((end - 50):(end - 5), :), 1), size(sig355, 1), 1);
sigNoBg532 = sig532 - repmat(mean(sig532((end - 50):(end - 5), :), 1), size(sig355, 1), 1);
sigNoBg1064 = sig1064 - repmat(mean(sig1064((end - 50):(end - 5), :), 1), size(sig355, 1), 1);
sigNoBg386 = sig386 - repmat(mean(sig386((end - 50):(end - 5), :), 1), size(sig355, 1), 1);
sigNoBg607 = sig607 - repmat(mean(sig607((end - 50):(end - 5), :), 1), size(sig355, 1), 1);

%% Save as NC file

%% signal
mode = netcdf.getConstant('NETCDF4');
mode = bitor(mode, netcdf.getConstant('CLASSIC_MODEL'));
mode = bitor(mode, netcdf.getConstant('CLOBBER'));
ncID = netcdf.create(fullfile(dstDataPath, 'EARLINET-Test-Signal.nc'), mode);

% define dimensions
dimID_height = netcdf.defDim(ncID, 'height', length(height355));
dimID_prfIdx = netcdf.defDim(ncID, 'prfIdx', size(sig355, 2));

% define variables
varID_sig355 = netcdf.defVar(ncID, 'signal_355', 'NC_FLOAT', [dimID_height, dimID_prfIdx]);
varID_sig532 = netcdf.defVar(ncID, 'signal_532', 'NC_FLOAT', [dimID_height, dimID_prfIdx]);
varID_sig386 = netcdf.defVar(ncID, 'signal_386', 'NC_FLOAT', [dimID_height, dimID_prfIdx]);
varID_sig607 = netcdf.defVar(ncID, 'signal_607', 'NC_FLOAT', [dimID_height, dimID_prfIdx]);
varID_sig1064 = netcdf.defVar(ncID, 'signal_1064', 'NC_FLOAT', [dimID_height, dimID_prfIdx]);
varID_pressure = netcdf.defVar(ncID, 'pressure', 'NC_FLOAT', dimID_height);
varID_temperature = netcdf.defVar(ncID, 'temperature', 'NC_FLOAT', dimID_height);
varID_height = netcdf.defVar(ncID, 'height', 'NC_FLOAT', dimID_height);
varID_prfIdx = netcdf.defVar(ncID, 'profile_ID', 'NC_FLOAT', dimID_prfIdx);

% leave define mode
netcdf.endDef(ncID);

% write data to NC file
netcdf.putVar(ncID, varID_sig355, sigNoBg355);
netcdf.putVar(ncID, varID_sig386, sigNoBg386);
netcdf.putVar(ncID, varID_sig532, sigNoBg532);
netcdf.putVar(ncID, varID_sig607, sigNoBg607);
netcdf.putVar(ncID, varID_sig1064, sigNoBg1064);
netcdf.putVar(ncID, varID_height, height355);
netcdf.putVar(ncID, varID_prfIdx, 1:size(sig355, 2));
netcdf.putVar(ncID, varID_temperature, temperature);
netcdf.putVar(ncID, varID_pressure, pressure);

% re-enter define mode
netcdf.reDef(ncID);

netcdf.putAtt(ncID, varID_sig355, 'unit', 'photon count');
netcdf.putAtt(ncID, varID_sig355, 'description', 'simulated receiving signal at 355 nm elastic channel');

netcdf.putAtt(ncID, varID_sig532, 'unit', 'photon count');
netcdf.putAtt(ncID, varID_sig532, 'description', 'simulated receiving signal at 532 nm elastic channel');

netcdf.putAtt(ncID, varID_sig1064, 'unit', 'photon count');
netcdf.putAtt(ncID, varID_sig1064, 'description', 'simulated receiving signal at 1064 nm elastic channel');

netcdf.putAtt(ncID, varID_sig386, 'unit', 'photon count');
netcdf.putAtt(ncID, varID_sig386, 'description', 'simulated receiving signal at 386 nm Raman channel');

netcdf.putAtt(ncID, varID_sig607, 'unit', 'photon count');
netcdf.putAtt(ncID, varID_sig607, 'description', 'simulated receiving signal at 607 nm Raman channel');

netcdf.putAtt(ncID, varID_height, 'unit', 'm');
netcdf.putAtt(ncID, varID_height, 'description', 'height above ground');

netcdf.putAtt(ncID, varID_prfIdx, 'unit', '');
netcdf.putAtt(ncID, varID_prfIdx, 'description', 'profile index');

netcdf.putAtt(ncID, varID_pressure, 'unit', 'hPa');
netcdf.putAtt(ncID, varID_pressure, 'description', 'atmospheric pressure');

netcdf.putAtt(ncID, varID_temperature, 'unit', 'degree celsius');
netcdf.putAtt(ncID, varID_temperature, 'description', 'atmospheric temperature');

% write global attributes
varID_global = netcdf.getConstant('GLOBAL');
netcdf.putAtt(ncID, varID_global, 'License', 'CF-1.0');
netcdf.putAtt(ncID, varID_global, 'Data_Originator', 'EARLINET');
netcdf.putAtt(ncID, varID_global, 'Contact', 'zp.yin@whu.edu.cn');
netcdf.putAtt(ncID, varID_global, 'UpdateTime', '2024-05-20');
netcdf.putAtt(ncID, varID_global, 'Disclaimer', 'Only for internal usage');

% close NC file
netcdf.close(ncID);

%% solution
mode = netcdf.getConstant('NETCDF4');
mode = bitor(mode, netcdf.getConstant('CLASSIC_MODEL'));
mode = bitor(mode, netcdf.getConstant('CLOBBER'));
ncID = netcdf.create(fullfile(dstDataPath, 'EARLINET-Test-Solution.nc'), mode);

% define dimensions
dimID_height = netcdf.defDim(ncID, 'height', length(height355));

% define variables
varID_aExt355 = netcdf.defVar(ncID, 'aerosol_extinction_coefficient_355', 'NC_FLOAT', dimID_height);
varID_aBsc355 = netcdf.defVar(ncID, 'aerosol_backscatter_coefficient_355', 'NC_FLOAT', dimID_height);
varID_aLR355 = netcdf.defVar(ncID, 'lidar_ratio_355', 'NC_FLOAT', dimID_height);
varID_aExt532 = netcdf.defVar(ncID, 'aerosol_extinction_coefficient_532', 'NC_FLOAT', dimID_height);
varID_aBsc532 = netcdf.defVar(ncID, 'aerosol_backscatter_coefficient_532', 'NC_FLOAT', dimID_height);
varID_aLR532 = netcdf.defVar(ncID, 'lidar_ratio_532', 'NC_FLOAT', dimID_height);
varID_aExt1064 = netcdf.defVar(ncID, 'aerosol_extinction_coefficient_1064', 'NC_FLOAT', dimID_height);
varID_aBsc1064 = netcdf.defVar(ncID, 'aerosol_backscatter_coefficient_1064', 'NC_FLOAT', dimID_height);
varID_aLR1064 = netcdf.defVar(ncID, 'lidar_ratio_1064', 'NC_FLOAT', dimID_height);
varID_height = netcdf.defVar(ncID, 'height', 'NC_FLOAT', dimID_height);

% leave define mode
netcdf.endDef(ncID);

% write data to NC file
netcdf.putVar(ncID, varID_aExt355, aExt355);
netcdf.putVar(ncID, varID_aBsc355, aExt355 ./ aLR355);
netcdf.putVar(ncID, varID_aLR355, aLR355);
netcdf.putVar(ncID, varID_aExt532, aExt532);
netcdf.putVar(ncID, varID_aBsc532, aExt532 ./ aLR532);
netcdf.putVar(ncID, varID_aLR532, aLR532);
netcdf.putVar(ncID, varID_aExt1064, aExt1064);
netcdf.putVar(ncID, varID_aBsc1064, aExt1064 ./ aLR1064);
netcdf.putVar(ncID, varID_aLR1064, aLR1064);
netcdf.putVar(ncID, varID_height, height355);

% re-enter define mode
netcdf.reDef(ncID);
netcdf.putAtt(ncID, varID_aExt355, 'unit', 'm^{-1}');
netcdf.putAtt(ncID, varID_aExt355, 'description', 'aerosol extinction coefficient at 355 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aBsc355, 'unit', 'm^{-1}sr^{-1}');
netcdf.putAtt(ncID, varID_aBsc355, 'description', 'aerosol backscatter coefficient at 355 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aLR355, 'unit', 'sr');
netcdf.putAtt(ncID, varID_aLR355, 'description', 'lidar ratio at 355 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aExt532, 'unit', 'm^{-1}');
netcdf.putAtt(ncID, varID_aExt532, 'description', 'aerosol extinction coefficient at 532 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aBsc532, 'unit', 'm^{-1}sr^{-1}');
netcdf.putAtt(ncID, varID_aBsc532, 'description', 'aerosol backscatter coefficient at 532 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aLR532, 'unit', 'sr');
netcdf.putAtt(ncID, varID_aLR532, 'description', 'lidar ratio at 532 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aExt1064, 'unit', 'm^{-1}');
netcdf.putAtt(ncID, varID_aExt1064, 'description', 'aerosol extinction coefficient at 1064 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aBsc1064, 'unit', 'm^{-1}sr^{-1}');
netcdf.putAtt(ncID, varID_aBsc1064, 'description', 'aerosol backscatter coefficient at 1064 nm (true values for validation)');

netcdf.putAtt(ncID, varID_aLR1064, 'unit', 'sr');
netcdf.putAtt(ncID, varID_aLR1064, 'description', 'lidar ratio at 1064 nm (true values for validation)');

netcdf.putAtt(ncID, varID_height, 'unit', 'm');
netcdf.putAtt(ncID, varID_height, 'description', 'height above ground');

% write global attributes
varID_global = netcdf.getConstant('GLOBAL');
netcdf.putAtt(ncID, varID_global, 'License', 'CF-1.0');
netcdf.putAtt(ncID, varID_global, 'Data_Originator', 'EARLINET');
netcdf.putAtt(ncID, varID_global, 'Contact', 'zp.yin@whu.edu.cn');
netcdf.putAtt(ncID, varID_global, 'UpdateTime', '2024-05-20');
netcdf.putAtt(ncID, varID_global, 'Disclaimer', 'Only for internal usage');

% close NC file
netcdf.close(ncID);