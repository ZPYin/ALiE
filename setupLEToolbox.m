% change encoding
currentCharacterEncoding = slCharacterEncoding();
slCharacterEncoding('UTF-8');

rootDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(rootDir, 'lib')));
addpath(genpath(fullfile(rootDir, 'include')));
addpath(genpath(fullfile(rootDir, 'data')));

global LEToolboxInfo
LEToolboxInfo.programVersion = '1.3';
LEToolboxInfo.updateDate = datenum(2023, 7, 17);
LEToolboxInfo.institute = 'INAST';
LEToolboxInfo.author = 'Zhenping Yin';
LEToolboxInfo.email = 'zp.yin@whu.edu.cn';
LEToolboxInfo.institute_logo = fullfile(rootDir, 'image', 'logo_cma.png');
LEToolboxInfo.projectDir = rootDir;