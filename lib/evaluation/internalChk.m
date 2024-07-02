function internalChk(config, varargin)
% INTERNALCHK lidar internal check.
%
% USAGE:
%    internalChk(config)
%
% INPUTS:
%    config: struct
%
% KEYWORDS:
%    flagDebug: logical
%
% HISTORY:
%    2021-09-22: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'config', @isstruct);
addParameter(p, 'flagDebug', false, @islogical);

parse(p, config, varargin{:});

%% log output
logFile = fullfile(config.resultPath, 'lidar_internal_check.log');
diaryon(logFile);

if isfield(config.internalChkCfg, 'lidarList')
    lidarType = config.internalChkCfg.lidarList;
else
    lidarType = fieldnames(config.internalChkCfg);
end

for iLidar = 1:length(lidarType)

    lidarConfig = config.internalChkCfg.(lidarType{iLidar});
    reportFile = fullfile(config.resultPath, sprintf('%s_internal_check_report.txt', lidarType{iLidar}));
    fid = fopen(reportFile, 'w');
    fprintf(fid, '# Evaluation Report for %s\n', lidarType{iLidar});
    fclose(fid);

    fprintf('[%s] Internal check for %s\n', tNow, lidarType{iLidar});

    % check lidar data file
    h5Filename = fullfile(config.dataSavePath, sprintf('%s_lidar_data.h5', lidarType{iLidar}));
    if exist(h5Filename, 'file') ~= 2
        warning('No lidar data for %s', lidarType{iLidar});
    end

    %% read lidar data
    lidarData = struct();
    lidarData.mTime = unix_timestamp_2_datenum(h5read(h5Filename, '/time'));
    lidarData.height = h5read(h5Filename, '/height');
    for iCh = 1:length(lidarConfig.chTag)
        if p.Results.flagDebug
            fprintf('Reading lidar data of %s\n', lidarConfig.chTag{iCh});
        end

        lidarData.(['sig', lidarConfig.chTag{iCh}]) = h5read(h5Filename, sprintf('/sig%s', lidarConfig.chTag{iCh}));
    end

    %% pre-process
    lidarData = lidarPreprocess(lidarData, lidarConfig.chTag, ...
        'deadtime', lidarConfig.preprocessCfg.deadTime, ...
        'bgBins', lidarConfig.preprocessCfg.bgBins, ...
        'nPretrigger', lidarConfig.preprocessCfg.nPretrigger, ...
        'bgCorFile', lidarConfig.preprocessCfg.bgCorFile, ...
        'lidarNo', lidarConfig.lidarNo, ...
        'flagDebug', p.Results.flagDebug, ...
        'tOffset', datenum(0, 1, 0, 0, lidarConfig.preprocessCfg.tOffset, 0), ...
        'hOffset', lidarConfig.preprocessCfg.hOffset, ...
        'overlapFile', lidarConfig.preprocessCfg.overlapFile);

    %% backscatter retrieval check
    if ~ isfield(lidarConfig, 'flagRetrievalChk')
        lidarConfig.flagRetrievalChk = false;
    end

    if lidarConfig.flagRetrievalChk
        fprintf('[%s] Start retrieval test!\n', tNow);

        if ~ isfield(lidarConfig, 'retrievalChkCfg')
            warning('retrievalChkCfg must be set for retrieval test!');
        else
            retrievalChk(lidarConfig, reportFile, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% detection ability check
    if ~ isfield(lidarConfig, 'flagDetectRangeChk')
        lidarConfig.flagDetectRangeChk = false;
    end

    if lidarConfig.flagDetectRangeChk
        fprintf('[%s] Start detection range test!\n', tNow);

        if ~ isfield(lidarConfig, 'detectRangeChkCfg')
            warning('detectRangeChkCfg must be set for retrieval test!');
        else
            detectRangeChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% quadrant check
    if ~ isfield(lidarConfig, 'flagQuadrantChk')
        lidarConfig.flagQuadrantChk = false;
    end

    if lidarConfig.flagQuadrantChk
        fprintf('[%s] Start telecover test!\n', tNow);

        if ~ isfield(lidarConfig, 'quadrantChkCfg')
            warning('quadrantChkCfg must be set for telecover test!');
        else
            quadrantChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% continuous operation check
    if ~ isfield(lidarConfig, 'contOptChkCfg')
        lidarConfig.contOptChkCfg = false;
    end

    if lidarConfig.flagContOptChk
        fprintf('[%s] Start continuous operation test!\n', tNow);

        if ~ isfield(lidarConfig, 'contOptChkCfg')
            warning('contOptChkCfg must be set for continuous operation test!');
        else
            contOptChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% background noise check
    if ~ isfield(lidarConfig, 'flagBgNoiseChk')
        lidarConfig.flagBgNoiseChk = false;
    end

    if lidarConfig.flagBgNoiseChk
        fprintf('[%s] Start background noise test!\n', tNow);

        if ~ isfield(lidarConfig, 'bgNoiseChkCfg')
            warning('bgNoiseChkCfg must be set for background noise test!');
        else
            bgNoiseChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% Rayleigh fit check
    if ~ isfield(lidarConfig, 'flagRayleighChk')
        lidarConfig.flagRayleighChk = false;
    end

    if lidarConfig.flagRayleighChk
        fprintf('[%s] Start Rayleigh test!\n', tNow);

        if ~ isfield(lidarConfig, 'RayleighChkCfg')
            warning('RayleighChkCfg must be set for Rayleigh test!');
        else
            RayleighChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% Saturation check
    if ~ isfield(lidarConfig, 'flagSaturationChk')
        lidarConfig.flagSaturationChk = false;
    end

    if lidarConfig.flagSaturationChk
        fprintf('[%s] Start Saturation test!\n', tNow);

        if ~ isfield(lidarConfig, 'saturationChkCfg')
            warning('saturationChkCfg must be set for saturation test!');
        else
            saturationChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% Water Vapor check
    if ~ isfield(lidarConfig, 'flagWVChk')
        lidarConfig.flagWVChk = false;
    end

    if lidarConfig.flagWVChk
        fprintf('[%s] Start water vapor test!\n', tNow);

        if ~ isfield(lidarConfig, 'wvChkCfg')
            warning('wvChkCfg must be set for water vapor test!');
        else
            wvChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end

    %% Temperature check
    if ~ isfield(lidarConfig, 'flagTempChk')
        lidarConfig.flagTempChk = false;
    end

    if lidarConfig.flagTempChk
        fprintf('[%s] Start temperature test!\n', tNow);

        if ~ isfield(lidarConfig, 'tempChkCfg')
            warning('tempChkCfg must be set for temperature test!');
        else
            tempChk(lidarData, lidarConfig, reportFile, lidarType{iLidar}, ...
                'figFolder', config.resultPath, ...
                'figFormat', config.figFormat);
        end

        fprintf('[%s] Finish!\n', tNow);
    end
end

diaryoff;

end