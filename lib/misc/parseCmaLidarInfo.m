function [chNo, detectMode, chType, hRes, hFOV, pFirstBin, nBins] = parseCmaLidarInfo(chInfoBits)
%PARSECMALIDARINFO parse the channel information from the channel information bits.
%Example:
%   [chNo, detectMode, chType, hRes, hFOV, pFirstBin, nBins] = parseCmaLidarInfo(chInfoBits)
%Inputs:
%   chInfoBits: array
%Outputs:
%   chNo: double
%       channel number.
%   detectMode: double
%       detection mode.
%       0: AD
%       1: PC
%       2: Merged
%   chType: double
%       channel type.
%       0: non-polarized
%       1: parallel polarized
%       2: cross polarized
%       3: Raman
%   hRes: double
%       range resolution. (m)
%   hFOV: double
%       minimum height with complete FOV. (m)
%   pFirstBin: double
%       location of the first bin in the bindary file.
%   nBins: double
%       number of range bins.
%Reference:
%   拉曼-米散射气溶胶激光雷达功能规格需求书.docx
%History:
%   2021-02-09. First Edition by Zhenping
%Contact:
%   zp.yin@whu.edu.cn

chNo = uint8_2_double(chInfoBits(1:2));
detectMode = uint8_2_double(chInfoBits(3:4));
chType = uint8_2_double(chInfoBits(5:6));
hRes = uint8_2_double(chInfoBits(7:8)) / 100;
hFOV = uint8_2_double(chInfoBits(9:10)) / 10;
pFirstBin = uint8_2_double(chInfoBits(11:14));
nBins = uint8_2_double(chInfoBits(15:16));

end