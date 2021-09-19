fprintf('Setting up lidar evaluation toolbox!\n');
fprintf('Author: Zhenping Yin\n');
fprintf('Email: zp.yin@whu.edu.cn\n');
fprintf('WeChat: ZPYin07\n');

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(rootDir, 'lib')));
addpath(genpath(fullfile(rootDir, 'include')));

global LEToolboxInfo
LEToolbox.programVersion = '0.1';
LEToolbox.updateDate = datenum(2021, 9, 19);
LEToolbox.institute = 'CMA';
LEToolbox.author = 'Zhenping Yin';
LEToolbox.email = 'zp.yin@whu.edu.cn';
LEToolbox.institute_logo = 'logo_cma.png';

fprintf('Success!!!\n');