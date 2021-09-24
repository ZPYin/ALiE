function [sigGlue] = sigMergeREAL(sigH, sigL, height, mergeRange, slope, offset)
% sigMergeREAL description
% USAGE:
%    [sigGlue] = sigMergeREAL(params)
% INPUTS:
%    params
% OUTPUTS:
%    sigGlue
% EXAMPLE:
% HISTORY:
%    2021-09-20: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

weightL = (height <= mergeRange(1)) + ((height >= mergeRange(1)) & (height <= mergeRange(2))) .* ((height - mergeRange(1)) ./ (mergeRange(2) - mergeRange(1)));
weightH = 1 - weightL;

sigGlue = repmat(weightL, 1, size(sigH, 2)) .* (sigL * slope + offset) + repmat(weightH, 1, size(sigH, 2)) .* sigH;

end