function convertLidar2h5(inData, oFile, chTag, varargin)
% CONVERTLIDAR2H5 convert lidar data to HDF5 format.
% USAGE:
%    convertLidar2h5(inData, oFile, chTag)
% INPUTS:
%    inData: struct
%    oFile: char
%    chTag: cell
% HISTORY:
%    2021-09-18: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'inData', @isstruct);
addRequired(p, 'oFile', @ischar);
addRequired(p, 'chTag', @iscell);

parse(p, inData, oFile, chTag, varargin{:});

if size(inData.rawSignal, 1) ~= length(chTag)
    errStruct.message = 'Wrong configuration for chTag';
    errStruct.identifier = 'LEToolbox:Err003';
    error(errStruct);
end

% write time and height
h5init(oFile);
hdf5writedata(oFile, '/time', datenum_2_unix_timestamp(inData.mTime), 'dataAttr', struct('standard_name', 'time', 'Units', 'seconds since 1970-01-01 00:00:00 LT', 'calendar', 'julian'), 'flagArray', true);
hdf5writedata(oFile, '/height', inData.height, 'dataAttr', struct('short_name',' height'), 'flagArray', true);

% write lidar data
for iCh = 1:size(inData.rawSignal, 1)
    hdf5writedata(oFile, sprintf('/sig%s', chTag{iCh}), squeeze(inData.rawSignal(iCh, :, :)), 'dataAttr', struct('short_name', sprintf('signal_%s', chTag{iCh})));
    h5_attach_scale(oFile, sprintf('/sig%s', chTag{iCh}), '/height', 1);
    h5_attach_scale(oFile, sprintf('/sig%s', chTag{iCh}), '/time', 0);
end

end