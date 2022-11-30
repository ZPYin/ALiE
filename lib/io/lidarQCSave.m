function lidarQCSave(file, lidarData, varargin)

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'file', @ischar);
addRequired(p, 'lidarData', @isstruct);
addParameter(p, 'instrument', 'YLJ1', @ischar);
addParameter(p, 'instrument_ID', '0', @ischar);
addParameter(p, 'location', 'Beijing', @ischar);
addParameter(p, 'location_ID', '', @ischar);
addParameter(p, 'data_collector', '', @ischar);
addParameter(p, 'data_collector_email', '', @ischar);
addParameter(p, 'PI', '', @ischar);
addParameter(p, 'PI_email', '', @ischar);
addParameter(p, 'processor_name', '', @ischar);
addParameter(p, 'processor_version', '', @ischar);
addParameter(p, 'instrument_configuration_file', '', @ischar);
addParameter(p, 'campaign_configuration_file', '', @ischar);

parse(p, file, lidarData, varargin{:});

mode = netcdf.getConstant('NETCDF4');
mode = bitor(mode, netcdf.getConstant('CLASSIC_MODEL'));
mode = bitor(mode, netcdf.getConstant('CLOBBER'));
ncID = netcdf.create(file, mode);

% define dimensions
dimID_height = netcdf.defDim(ncID, 'height', length(lidarData.height));
dimID_time = netcdf.defDim(ncID, 'time', length(lidarData.time));
dimID_channel = netcdf.defDim(ncID, 'channel', length(lidarData.channelBit));
dimID_constant = netcdf.defDim(ncID, 'constant', 1);

% define variables
varID_altitude = netcdf.defVar(ncID, 'altitude', 'NC_FLOAT', dimID_constant);
varID_longitude = netcdf.defVar(ncID, 'longitude', 'NC_FLOAT', dimID_constant);
varID_latitude = netcdf.defVar(ncID, 'latitude', 'NC_FLOAT', dimID_constant);
varID_elevation_angle = netcdf.defVar(ncID, 'elevation_angle', 'NC_FLOAT', dimID_constant);
varID_azimuth_angle = netcdf.defVar(ncID, 'azimuth_angle', 'NC_FLOAT', dimID_constant);
varID_start_time = netcdf.defVar(ncID, 'start_time', 'NC_DOUBLE', dimID_constant);
varID_stop_time = netcdf.defVar(ncID, 'stop_time', 'NC_DOUBLE', dimID_constant);
varID_time = netcdf.defVar(ncID, 'time', 'NC_DOUBLE', dimID_time);
varID_height = netcdf.defVar(ncID, 'height', 'NC_FLOAT', dimID_height);
varID_channelBit = netcdf.defVar(ncID, 'channelBit', 'NC_BYTE', dimID_channel);
varID_rec_wavelength = netcdf.defVar(ncID, 'rec_wavelength', 'NC_FLOAT', dimID_channel);
varID_flagInvalidData = netcdf.defVar(ncID, 'flagInvalidData', 'NC_BYTE', [dimID_time, dimID_height]);
varID_dataScore = netcdf.defVar(ncID, 'dataScore', 'NC_BYTE', [dimID_time, dimID_height, dimID_channel]);
varID_rawSignal = netcdf.defVar(ncID, 'rawSignal', 'NC_FLOAT', [dimID_time, dimID_height, dimID_channel]);
varID_temperature = netcdf.defVar(ncID, 'temperature', 'NC_FLOAT', [dimID_time, dimID_height]);
varID_pressure = netcdf.defVar(ncID, 'pressure', 'NC_FLOAT', [dimID_time, dimID_height]);
varID_shots = netcdf.defVar(ncID, 'shots', 'NC_INT', [dimID_time]);
varID_measurement_type = netcdf.defVar(ncID, 'measurement_type', 'NC_BYTE', [dimID_constant]);
varID_digitizer_mode = netcdf.defVar(ncID, 'digitizer_mode', 'NC_BYTE', [dimID_channel]);

% define the filling value
% netcdf.defVarFill(ncID, varID_rawSignal, false, missing_value);

% define the data compression
netcdf.defVarDeflate(ncID, varID_rawSignal, true, true, 5);
netcdf.defVarDeflate(ncID, varID_dataScore, true, true, 5);
netcdf.defVarDeflate(ncID, varID_flagInvalidData, true, true, 5);
netcdf.defVarDeflate(ncID, varID_temperature, true, true, 5);
netcdf.defVarDeflate(ncID, varID_pressure, true, true, 5);

% leave define mode
netcdf.endDef(ncID);

% write data to .nc file
netcdf.putVar(ncID, varID_altitude, lidarData.altitude);
netcdf.putVar(ncID, varID_latitude, lidarData.latitude);
netcdf.putVar(ncID, varID_longitude, lidarData.longitude);
netcdf.putVar(ncID, varID_elevation_angle, lidarData.elevation_angle);
netcdf.putVar(ncID, varID_azimuth_angle, lidarData.azimuth_angle);
netcdf.putVar(ncID, varID_start_time, datenum_2_unix_timestamp(lidarData.start_time));
netcdf.putVar(ncID, varID_stop_time, datenum_2_unix_timestamp(lidarData.stop_time));
netcdf.putVar(ncID, varID_time, datenum_2_unix_timestamp(lidarData.time));
netcdf.putVar(ncID, varID_height, lidarData.height);
netcdf.putVar(ncID, varID_channelBit, int8(lidarData.channelBit));
netcdf.putVar(ncID, varID_rec_wavelength, lidarData.rec_wavelength);
netcdf.putVar(ncID, varID_flagInvalidData, int8(lidarData.flagInvalidData));
netcdf.putVar(ncID, varID_dataScore, int8(lidarData.dataScore));
netcdf.putVar(ncID, varID_rawSignal, lidarData.rawSignal);
netcdf.putVar(ncID, varID_temperature, lidarData.temperature);	
netcdf.putVar(ncID, varID_pressure, lidarData.pressure);
netcdf.putVar(ncID, varID_shots, lidarData.shots);
netcdf.putVar(ncID, varID_measurement_type, int8(lidarData.measurement_type));
netcdf.putVar(ncID, varID_digitizer_mode, int8(lidarData.digitizer_mode));

% re enter define mode
netcdf.reDef(ncID);

%% write attributes to the variables

% altitude
netcdf.putAtt(ncID, varID_altitude, 'unit', 'm');
netcdf.putAtt(ncID, varID_altitude, 'long_name', 'Height of lidar above mean sea level');
netcdf.putAtt(ncID, varID_altitude, 'standard_name', 'altitude');

% longitude
netcdf.putAtt(ncID, varID_longitude, 'unit', 'degrees_east');
netcdf.putAtt(ncID, varID_longitude, 'long_name', 'Longitude of the site');
netcdf.putAtt(ncID, varID_longitude, 'standard_name', 'longitude');
netcdf.putAtt(ncID, varID_longitude, 'axis', 'X');

% latitude
netcdf.putAtt(ncID, varID_latitude, 'unit', 'degrees_north');
netcdf.putAtt(ncID, varID_latitude, 'long_name', 'Latitude of the site');
netcdf.putAtt(ncID, varID_latitude, 'standard_name', 'latitude');
netcdf.putAtt(ncID, varID_latitude, 'axis', 'Y');

% elevation angle
netcdf.putAtt(ncID, varID_elevation_angle, 'unit', 'degrees');
netcdf.putAtt(ncID, varID_elevation_angle, 'long_name', 'elevation angle of lidar device');
netcdf.putAtt(ncID, varID_elevation_angle, 'standard_name', 'elevation_angle');

% azimuth angle
netcdf.putAtt(ncID, varID_azimuth_angle, 'unit', 'degrees');
netcdf.putAtt(ncID, varID_azimuth_angle, 'long_name', 'azimuth angle of lidar device');
netcdf.putAtt(ncID, varID_azimuth_angle, 'standard_name', 'azimuth_angle');

% start time
netcdf.putAtt(ncID, varID_start_time, 'unit', 'seconds since 1970-01-01 00:00:00 UTC');
netcdf.putAtt(ncID, varID_start_time, 'long_name', 'start time of the measurement');
netcdf.putAtt(ncID, varID_start_time, 'standard_name', 'start_time');
netcdf.putAtt(ncID, varID_start_time, 'calendar', 'julian');

% stop time
netcdf.putAtt(ncID, varID_stop_time, 'unit', 'seconds since 1970-01-01 00:00:00 UTC');
netcdf.putAtt(ncID, varID_stop_time, 'long_name', 'stop time of the measurement');
netcdf.putAtt(ncID, varID_stop_time, 'standard_name', 'stop_time');
netcdf.putAtt(ncID, varID_stop_time, 'calendar', 'julian');

% time
netcdf.putAtt(ncID, varID_time, 'unit', 'seconds since 1970-01-01 00:00:00 UTC');
netcdf.putAtt(ncID, varID_time, 'long_name', 'Time UTC');
netcdf.putAtt(ncID, varID_time, 'standard_name', 'time');
netcdf.putAtt(ncID, varID_time, 'axis', 'T');
netcdf.putAtt(ncID, varID_time, 'calendar', 'julian');

% height
netcdf.putAtt(ncID, varID_height, 'unit', 'm');
netcdf.putAtt(ncID, varID_height, 'long_name', 'Height above the ground');
netcdf.putAtt(ncID, varID_height, 'standard_name', 'height');
netcdf.putAtt(ncID, varID_height, 'axis', 'Z');

% channel bit
netcdf.putAtt(ncID, varID_channelBit, 'unit', '');
netcdf.putAtt(ncID, varID_channelBit, 'long_name', 'channel type (00000000): first bit: elastic (true); second bit: Raman (true); third bit: water vapor (true); forth bit: cross (true); fifth bit: near-range (true); sixth bit: rotational Raman (true).');
netcdf.putAtt(ncID, varID_channelBit, 'standard_name', 'channelBit');

% receving wavelength
netcdf.putAtt(ncID, varID_rec_wavelength, 'unit', 'nm');
netcdf.putAtt(ncID, varID_rec_wavelength, 'long_name', 'central wavelength of each channel');
netcdf.putAtt(ncID, varID_rec_wavelength, 'standard_name', 'wavelength');

% receving wavelength
netcdf.putAtt(ncID, varID_rec_wavelength, 'unit', 'nm');
netcdf.putAtt(ncID, varID_rec_wavelength, 'long_name', 'central wavelength of each channel');
netcdf.putAtt(ncID, varID_rec_wavelength, 'standard_name', 'wavelength');

% invalid data
netcdf.putAtt(ncID, varID_flagInvalidData, 'unit', '');
netcdf.putAtt(ncID, varID_flagInvalidData, 'long_name', 'invalid data identifier');
netcdf.putAtt(ncID, varID_flagInvalidData, 'standard_name', 'invalid_data_mask');

% dataScore
netcdf.putAtt(ncID, varID_dataScore, 'unit', '');
netcdf.putAtt(ncID, varID_dataScore, 'long_name', 'data score for each data point. (0~100)');
netcdf.putAtt(ncID, varID_dataScore, 'standard_name', 'dataScore');

% rawSignal
netcdf.putAtt(ncID, varID_rawSignal, 'unit', '');
netcdf.putAtt(ncID, varID_rawSignal, 'long_name', 'raw signal after data quality control');
netcdf.putAtt(ncID, varID_rawSignal, 'standard_name', 'raw_signal');

% temperature
netcdf.putAtt(ncID, varID_temperature, 'unit', 'K');
netcdf.putAtt(ncID, varID_temperature, 'long_name', 'atmospheric temperature');
netcdf.putAtt(ncID, varID_temperature, 'standard_name', 'temperature');

% pressure
netcdf.putAtt(ncID, varID_pressure, 'unit', 'Pa');
netcdf.putAtt(ncID, varID_pressure, 'long_name', 'atmospheric pressure');
netcdf.putAtt(ncID, varID_pressure, 'standard_name', 'pressure');

% measurement type
netcdf.putAtt(ncID, varID_measurement_type, 'unit', '');
netcdf.putAtt(ncID, varID_measurement_type, 'long_name', 'measurement type: 0: abnormal; 1: calibration; 2: normal');
netcdf.putAtt(ncID, varID_measurement_type, 'standard_name', 'measurement type');

% digitizer mode
netcdf.putAtt(ncID, varID_digitizer_mode, 'unit', '');
netcdf.putAtt(ncID, varID_digitizer_mode, 'long_name', 'digitizer mode: 0: PMT; 1: APD');
netcdf.putAtt(ncID, varID_digitizer_mode, 'standard_name', 'digitizer mode');

varID_global = netcdf.getConstant('GLOBAL');
netcdf.putAtt(ncID, varID_global, 'instrument', p.Results.instrument);
netcdf.putAtt(ncID, varID_global, 'instrument_ID', p.Results.instrument_ID);
netcdf.putAtt(ncID, varID_global, 'location', p.Results.location);
netcdf.putAtt(ncID, varID_global, 'location_ID', p.Results.location_ID);
netcdf.putAtt(ncID, varID_global, 'data_collector', p.Results.data_collector);
netcdf.putAtt(ncID, varID_global, 'data_collector_email', p.Results.data_collector_email);
netcdf.putAtt(ncID, varID_global, 'PI', p.Results.PI);
netcdf.putAtt(ncID, varID_global, 'PI_email', p.Results.PI_email);
netcdf.putAtt(ncID, varID_global, 'processor_name', p.Results.processor_name);
netcdf.putAtt(ncID, varID_global, 'processor_version', p.Results.processor_version);
netcdf.putAtt(ncID, varID_global, 'instrument_configuration_file', p.Results.instrument_configuration_file);
netcdf.putAtt(ncID, varID_global, 'campaign_configuration_file', p.Results.campaign_configuration_file);
netcdf.putAtt(ncID, varID_global, 'history', sprintf('Last processing time at %s by %s', tNow, mfilename));

% close file
netcdf.close(ncID);

end