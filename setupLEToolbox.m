fprintf('Setting up lidar evaluation toolbox!\n');
fprintf('Author: Zhenping Yin\n');
fprintf('Email: zp.yin@whu.edu.cn\n');
fprintf('WeChat: ZPYin07\n');

% change encoding
currentCharacterEncoding = slCharacterEncoding();
slCharacterEncoding('UTF-8');

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(rootDir, 'lib')));
addpath(genpath(fullfile(rootDir, 'include')));

global LEToolboxInfo
LEToolboxInfo.programVersion = '1.3';
LEToolboxInfo.updateDate = datenum(2023, 7, 17);
LEToolboxInfo.institute = 'INAST';
LEToolboxInfo.author = 'Zhenping Yin';
LEToolboxInfo.email = 'zp.yin@whu.edu.cn';
LEToolboxInfo.institute_logo = fullfile(rootDir, 'image', 'logo_cma.png');
LEToolboxInfo.projectDir = rootDir;

fprintf('Success!!!\n');