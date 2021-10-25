global LEToolboxInfo

results = runtests(fullfile(LEToolboxInfo.projectDir, 'lib', 'tests'), ...
    'IncludeSubfolders', true);