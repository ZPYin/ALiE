fprintf('Setting up lidar evaluation toolbox!\n');
fprintf('Author: Zhenping Yin\n');
fprintf('Email: zp.yin@whu.edu.cn\n');
fprintf('WeChat: ZPYin07\n');

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(rootDir, 'lib')));
addpath(genpath(fullfile(rootDir, 'include')));

global LEToolboxInfo
LEToolboxInfo.programVersion = '1.0';
LEToolboxInfo.updateDate = datenum(2021, 10, 25);
LEToolboxInfo.institute = 'CMA';
LEToolboxInfo.author = 'Zhenping Yin';
LEToolboxInfo.email = 'zp.yin@whu.edu.cn';
LEToolboxInfo.institute_logo = fullfile(rootDir, 'image', 'logo_cma.png');
LEToolboxInfo.projectDir = rootDir;
LEToolboxInfo.flagWaterMark = true;

fprintf('Success!!!\n');