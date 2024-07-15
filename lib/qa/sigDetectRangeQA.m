function [score] = sigDetectRangeQA(detectRange, varargin)
% SIGDETECTRANGEQA detection range assessment with scores.
%
% USAGE:
%    [score] = sigDetectRangeQA(detectRange)
%
% INPUTS:
%    detectRange: isnumeric
%        detection range. (km)
% KEYWORDS:
%    product: ischar
%        product type: temperature (default) or water_vapor or crosstalk_temperature
%    isDayTime: islogical
%        day time flag. (default value: false)
%
% OUTPUTS:
%    score: numeric
%
% HISTORY:
%    2024-07-15: first edition by Zhenping
% .. Authors: - zp.yin@whu.edu.cn

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'detectRange', @isnumeric);
addParameter(p, 'isDayTime', false, @islogical);
addParameter(p, 'product', 'temperature', @ischar);

parse(p, detectRange, varargin{:});

switch p.Results.product

case 'temperature'
    if p.Results.isDayTime
        func = @(x) ((x >= 2) & (x < 3)) .* ((x - 2) / (3 - 2) .* (60 - 0)) + ...
                    ((x >= 3) & (x < 4)) .* ((x - 3) / (4 - 3) .* (80 - 60) + 60) + ...
                    ((x >= 4) & (x < 6)) .* ((x - 4) / (6 - 4) .* (100 - 80) + 80) + ...
                    (x >= 6) .* 100;
    else
        func = @(x) ((x >= 5) & (x < 7)) .* ((x - 5) / (7 - 5) .* (60 - 0)) + ...
                    ((x >= 7) & (x < 8)) .* ((x - 7) / (8 - 7) .* (80 - 60) + 60) + ...
                    ((x >= 8) & (x < 10)) .* ((x - 8) / (10 - 8) .* (100 - 80) + 80) + ...
                    (x >= 10) .* 100;
    end

    score = func(detectRange);

case 'water_vapor'
    if p.Results.isDayTime
        func = @(x) ((x >= 1) & (x < 2)) .* ((x - 1) / (2 - 1) .* (60 - 0)) + ...
                    ((x >= 2) & (x < 3)) .* ((x - 2) / (3 - 2) .* (80 - 60) + 60) + ...
                    ((x >= 3) & (x < 4)) .* ((x - 3) / (4 - 3) .* (100 - 80) + 80) + ...
                    (x >= 4) .* 100;
    else
        func = @(x) ((x >= 1) & (x < 3)) .* ((x - 1) / (3 - 1) .* (60 - 0)) + ...
                    ((x >= 3) & (x < 5)) .* ((x - 3) / (5 - 3) .* (80 - 60) + 60) + ...
                    ((x >= 5) & (x < 7)) .* ((x - 5) / (7 - 5) .* (100 - 80) + 80) + ...
                    (x >= 7) .* 100;
    end

    score = func(detectRange);

case 'crosstalk_temperature'

    func = @(x) ((x < 0.01) & (x >= 0.005)) .* ((x - 0.01) / (0.005 - 0.01) .* (30 - 0) + 30) + ...
                ((x < 0.005) & (x >= 0.002)) .* ((x - 0.005) / (0.002 - 0.005) .* (80 - 60) + 60) + ...
                ((x < 0.002) & (x >= 0.001)) .* ((x - 0.002) / (0.001 - 0.002) .* (100 - 80) + 80) + ...
                (x <= 0.001) * 100;
    score = func(detectRange);

otherwise
    error('Unknown product:%s', p.Results.product);
end

end