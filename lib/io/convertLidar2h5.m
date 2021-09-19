function convertLidar2h5(inData, oFile)
% convertLidar2h5 description
% USAGE:
%    convertLidar2h5(inData, oFile)
% INPUTS:
%    params
% OUTPUTS:
%    output
% EXAMPLE:
% HISTORY:
%    2021-09-18: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

h5init(oFile);
hdf5writedata(oFile, '/time', datenum_2_unix_timestamp(inData.mTime), 'dataAttr', struct('standard_name', 'time', 'Units', 'seconds since 1970-01-01 00:00:00 LT', 'calendar', 'julian'), 'flagArray', true);
hdf5writedata(oFile, '/height', inData.height, 'dataAttr', struct('short_name',' height'), 'flagArray', true);

if ~ isempty(inData.sig355)
    hdf5writedata(oFile, '/sig355', inData.sig355, 'dataAttr', struct('short_name', 'raw_signal_355'));
    h5_attach_scale(oFile, '/sig355', '/height', 1);
    h5_attach_scale(oFile, '/sig355', '/time', 0);
end

if ~ isempty(inData.sig355P)
    hdf5writedata(oFile, '/sig355P', inData.sig355P, 'dataAttr', struct('short_name', 'raw_signal_parallel_355'));
    h5_attach_scale(oFile, '/sig355P', '/height', 1);
    h5_attach_scale(oFile, '/sig355P', '/time', 0);
end

if ~ isempty(inData.sig355S)
    hdf5writedata(oFile, '/sig355S', inData.sig355S, 'dataAttr', struct('short_name', 'raw_signal_cross_355'));
    h5_attach_scale(oFile, '/sig355S', '/height', 1);
    h5_attach_scale(oFile, '/sig355S', '/time', 0);
end

if ~ isempty(inData.sig387)
    hdf5writedata(oFile, '/sig387', inData.sig387, 'dataAttr', struct('short_name', 'raw_signal_387'));
    h5_attach_scale(oFile, '/sig387', '/height', 1);
    h5_attach_scale(oFile, '/sig387', '/time', 0);
end

if ~ isempty(inData.sig407)
    hdf5writedata(oFile, '/sig407', inData.sig407, 'dataAttr', struct('short_name', 'raw_signal_407'));
    h5_attach_scale(oFile, '/sig407', '/height', 1);
    h5_attach_scale(oFile, '/sig407', '/time', 0);
end

if ~ isempty(inData.sig532)
    hdf5writedata(oFile, '/sig532', inData.sig532, 'dataAttr', struct('short_name', 'raw_signal_532'));
    h5_attach_scale(oFile, '/sig532', '/height', 1);
    h5_attach_scale(oFile, '/sig532', '/time', 0);
end

if ~ isempty(inData.sig532P)
    hdf5writedata(oFile, '/sig532P', inData.sig532P, 'dataAttr', struct('short_name', 'raw_signal_parallel_532'));
    h5_attach_scale(oFile, '/sig532P', '/height', 1);
    h5_attach_scale(oFile, '/sig532P', '/time', 0);
end

if ~ isempty(inData.sig532S)
    hdf5writedata(oFile, '/sig532S', inData.sig532S, 'dataAttr', struct('short_name', 'raw_signal_cross_532'));
    h5_attach_scale(oFile, '/sig532S', '/height', 1);
    h5_attach_scale(oFile, '/sig532S', '/time', 0);
end

if ~ isempty(inData.sig607)
    hdf5writedata(oFile, '/sig607', inData.sig607, 'dataAttr', struct('short_name', 'raw_signal_607'));
    h5_attach_scale(oFile, '/sig607', '/height', 1);
    h5_attach_scale(oFile, '/sig607', '/time', 0);
end

if ~ isempty(inData.sig1064)
    hdf5writedata(oFile, '/sig1064', inData.sig1064, 'dataAttr', struct('short_name', 'raw_signal_1064'));
    h5_attach_scale(oFile, '/sig1064', '/height', 1);
    h5_attach_scale(oFile, '/sig1064', '/time', 0);
end

if ~ isempty(inData.sig1064P)
    hdf5writedata(oFile, '/sig1064P', inData.sig1064P, 'dataAttr', struct('short_name', 'raw_signal_parallel_1064'));
    h5_attach_scale(oFile, '/sig1064P', '/height', 1);
    h5_attach_scale(oFile, '/sig1064P', '/time', 0);
end

if ~ isempty(inData.sig1064S)
    hdf5writedata(oFile, '/sig1064S', inData.sig1064S, 'dataAttr', struct('short_name', 'raw_signal_cross_1064'));
    h5_attach_scale(oFile, '/sig1064S', '/height', 1);
    h5_attach_scale(oFile, '/sig1064S', '/time', 0);
end

end