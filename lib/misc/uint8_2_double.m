function [oData] = uint8_2_double(iData)
%UINT8_2_DOUBLE convert uint8 array to double integer.
%Example:
%   [oData] = uint8_2_double([1, 2]])
%   >> 513
%Inputs:
%   iData: array
%       uint8 array.
%Outputs:
%   oData: integer
%History:
%   2021-02-07. First Edition by Zhenping
%Contact:
%   zp.yin@whu.edu.cn

iData = reshape(iData, 1, length(iData));
oData = iData(end:-1:1) * transpose((256 .^ (((length(iData) - 1):-1:0))));

end