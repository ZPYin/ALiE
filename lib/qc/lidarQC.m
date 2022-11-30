function [lidarData] = lidarQC(inLidarData, chTag)

lidarData = struct();
nChannels = (length(fieldnames(inLidarData)) - 2) / 3;
lidarData.longitude = 0;
lidarData.latitude = 0;
lidarData.altitude = 0;
lidarData.elevation_angle = 90;
lidarData.azimuth_angle = 0;
lidarData.start_time = inLidarData.mTime(1);
lidarData.stop_time = inLidarData.mTime(end);
lidarData.time = inLidarData.mTime;
lidarData.height = inLidarData.height;
lidarData.channelBit = zeros(1, nChannels);
lidarData.rec_wavelength = 355 * ones(1, nChannels);
lidarData.flagInvalidData = false(length(inLidarData.mTime), length(inLidarData.height));
lidarData.dataScore = 100 * ones(length(inLidarData.mTime), length(inLidarData.height), nChannels);
lidarData.rawSignal = NaN(length(inLidarData.mTime), length(inLidarData.height), nChannels);
lidarData.background = NaN(length(inLidarData.mTime), nChannels);
lidarData.temperature = 300 * ones(length(inLidarData.mTime), length(inLidarData.height));
lidarData.pressure = 1e5 * ones(length(inLidarData.mTime), length(inLidarData.height));
lidarData.shots = 1e5 * ones(1, length(inLidarData.mTime));
lidarData.measurement_type = 2;
lidarData.digitizer_mode = zeros(1, nChannels);

for iCh = 1:nChannels
    lidarData.rawSignal(:, :, iCh) = transpose(inLidarData.(['sig', chTag{iCh}]));
    lidarData.background(:, iCh) = inLidarData.(['bg', chTag{iCh}]);
end

end