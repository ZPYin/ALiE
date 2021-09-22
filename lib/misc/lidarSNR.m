function [snr0] = lidarSNR(sig, bg, varargin)
% lidarSNR description
% USAGE:
%    [snr0] = lidarSNR(sig, bg, varargin)
% INPUTS:
%    sig, bg, varargin
% OUTPUTS:
%    snr0
% EXAMPLE:
% HISTORY:
%    2021-09-21: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'sig', @isnumeric);
addRequired(p, 'bg', @isnumeric);
addParameter(p, 'bgBins', [], @isnumeric);

parse(p, sig, bg, varargin{:});

if isempty(p.Results.bgBins)
    bgBins = [length(sig) - 500, length(sig)];
else
    bgBins = p.Results.bgBins;
end

snr0 = NaN(size(sig));
if bg > 0
    ratio = nanstd(sig(bgBins(1):bgBins(2))) / sqrt(bg);

    flagZero = (sig + bg) <= 0;
    snr0(~ flagZero) = sig(~ flagZero) ./ (ratio .* sqrt(sig(~ flagZero) + bg));
    snr0(flagZero) = 0;
else
    tot = sig + bg;
    tot(tot <= 0) = NaN;
    snr0 = sig / ADSigStd(tot, 5);
end

snr0(isnan(snr0)) = 0;

end