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
    hdf5writedata(oFile, '/sig355e', inData.sig355, 'dataAttr', struct('short_name', 'raw_signal_355'));
    h5_attach_scale(oFile, '/sig355e', '/height', 1);
    h5_attach_scale(oFile, '/sig355e', '/time', 0);
end

if ~ isempty(inData.sig355P)
    hdf5writedata(oFile, '/sig355p', inData.sig355P, 'dataAttr', struct('short_name', 'raw_signal_parallel_355'));
    h5_attach_scale(oFile, '/sig355p', '/height', 1);
    h5_attach_scale(oFile, '/sig355p', '/time', 0);
end

if ~ isempty(inData.sig355S)
    hdf5writedata(oFile, '/sig355s', inData.sig355S, 'dataAttr', struct('short_name', 'raw_signal_cross_355'));
    h5_attach_scale(oFile, '/sig355s', '/height', 1);
    h5_attach_scale(oFile, '/sig355s', '/time', 0);
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
    hdf5writedata(oFile, '/sig532e', inData.sig532, 'dataAttr', struct('short_name', 'raw_signal_532'));
    h5_attach_scale(oFile, '/sig532e', '/height', 1);
    h5_attach_scale(oFile, '/sig532e', '/time', 0);
end

if ~ isempty(inData.sig532P)
    hdf5writedata(oFile, '/sig532p', inData.sig532P, 'dataAttr', struct('short_name', 'raw_signal_parallel_532'));
    h5_attach_scale(oFile, '/sig532p', '/height', 1);
    h5_attach_scale(oFile, '/sig532p', '/time', 0);
end

if ~ isempty(inData.sig532S)
    hdf5writedata(oFile, '/sig532s', inData.sig532S, 'dataAttr', struct('short_name', 'raw_signal_cross_532'));
    h5_attach_scale(oFile, '/sig532s', '/height', 1);
    h5_attach_scale(oFile, '/sig532s', '/time', 0);
end

if ~ isempty(inData.sig607)
    hdf5writedata(oFile, '/sig607', inData.sig607, 'dataAttr', struct('short_name', 'raw_signal_607'));
    h5_attach_scale(oFile, '/sig607', '/height', 1);
    h5_attach_scale(oFile, '/sig607', '/time', 0);
end

if ~ isempty(inData.sig1064)
    hdf5writedata(oFile, '/sig1064e', inData.sig1064, 'dataAttr', struct('short_name', 'raw_signal_1064'));
    h5_attach_scale(oFile, '/sig1064e', '/height', 1);
    h5_attach_scale(oFile, '/sig1064e', '/time', 0);
end

if ~ isempty(inData.sig1064P)
    hdf5writedata(oFile, '/sig1064p', inData.sig1064P, 'dataAttr', struct('short_name', 'raw_signal_parallel_1064'));
    h5_attach_scale(oFile, '/sig1064p', '/height', 1);
    h5_attach_scale(oFile, '/sig1064p', '/time', 0);
end

if ~ isempty(inData.sig1064S)
    hdf5writedata(oFile, '/sig1064s', inData.sig1064S, 'dataAttr', struct('short_name', 'raw_signal_cross_1064'));
    h5_attach_scale(oFile, '/sig1064s', '/height', 1);
    h5_attach_scale(oFile, '/sig1064s', '/time', 0);
end

end