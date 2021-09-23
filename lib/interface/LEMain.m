clc; close all;

%% initialization
configFile = 'D:\Coding\Matlab\lidar_evaluation_1064\config\comparison_config_20210910.yml';
% configFile = 'D:\Coding\Matlab\lidar_evaluation_1064\config\data_colorplot_config.yml';
flagDebug = false;
flagReadData = false;
flagInternalChk = false;
flagExternalChk = true;
flagQL = false;

if flagReadData
    convertLidarData(configFile, 'flagDebug', flagDebug);
end

if flagInternalChk
    internal_check(configFile, 'flagDebug', flagDebug);
end

if flagExternalChk
    external_check(configFile, 'flagDebug', flagDebug);
end

if flagQL
    displayQL(configFile, 'flagDebug', flagDebug);
end