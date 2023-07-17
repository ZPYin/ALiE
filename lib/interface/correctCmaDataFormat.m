function [isSuccess] = correctCmaDataFormat(folder, dataType, varargin)
% CORRECTCMADATAFORMAT correct CMA data files with wrong format.
%
% USAGE:
%    [isSuccess] = correctCmaDataFormat(folder, dataType, varargin)
%
% INPUTS:
%    folder: char
%        data folder.
%    dataType: char
%        data type identifier
%        'HR': data from HR
%
% KEYWORDS:
%    filePat: char
%    searchDepth: numeric
%    debug: logical
%
% OUTPUTS:
%    isSuccess
%
% HISTORY:
%    2021-10-20: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'folder', @ischar);
addRequired(p, 'dataType', @ischar);
addParameter(p, 'filePat', '.*', @ischar);
addParameter(p, 'searchDepth', 1, @isnumeric);
addParameter(p, 'debug', false, @islogical);

parse(p, folder, dataType, varargin{:});

%% search files
dataFiles = listfile(folder, p.Results.filePat, p.Results.searchDepth);

%% correct files
switch lower(dataType)

case 'hr'
    %% correct HR data
    for iFile = 1:length(dataFiles)
        if p.Results.debug
            fprintf('Reading %s\n', dataFiles{iFile});
        end

        % tmpName = [tempname, '.bin'];
        [thisPath, thisFilename, thisExt] = fileparts(dataFiles{iFile});
        tmpName = fullfile(thisPath, ['correct_', thisFilename, thisExt]);
        fidOri = fopen(dataFiles{iFile}, 'r', 'ieee-le');
        fidDst = fopen(tmpName, 'w', 'ieee-le');

        % read headers
        fwrite(fidDst, fread(fidOri, 54, 'uint8'), 'uint8');

        % channel information
        rawChInfo = fread(fidOri, [16, 16], 'uint8');
        fwrite(fidDst, rawChInfo, 'uint8');
        % [thisChNo, thisDetectMode, thisRecWL, thisChType, thisHRes, thisHBlindZone, thisFirstBin, thisNBin] = parseCmaLidarInfo(rawChInfo(:, 1));

        % lidar data
        rawBackscatter = fread(fidOri, Inf, 'float32');
        tmpBackscatter = rawBackscatter;
        tmpBackscatter(8001:10000) = tmpBackscatter(2001:4000);
        tmpBackscatter(2001:4000) = 0;
        tmpBackscatter(32001:128000) = 0;
        fwrite(fidDst, tmpBackscatter, 'float32');

        % close files
        fclose(fidOri);
        fclose(fidDst);
        % movefile(tmpName, dataFiles{iFile});
    end

    isSuccess = true;

otherwise
    isSuccess = false;
    error('Unknown data type %s', dataType);
end


end