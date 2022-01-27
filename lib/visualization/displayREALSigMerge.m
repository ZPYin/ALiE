function displayREALSigMerge(height, mTime, sigH, sigL, mergeRange, varargin)
% DISPLAYREALSIGMERGE display REAL merged signal.
% USAGE:
%    displayREALSigMerge(height, mTime, sigH, sigL, mergeRange)
% INPUTS:
%    height: numeric
%    mTime: numeric
%    sigH: matrix (height x time)
%    sigL: matrix (height x time)
%    mergeRange: 2-element array
%        signal merge range. (m)
% KEYWORDS:
%    channelTag: char
%        channel tag. (e.g., '532s')
%    cRange: 2-element array
%        range corrected signal range.
%    hRange: 2-element array
%        height range. (m)
%    figFolder: char
%        figure exported folder.
%    mergeOffset: 2-element array
%        offset for signal merge.
%    mergeSlope
%        slope for signal merge
% HISTORY:
%    2021-09-20: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'height', @isnumeric);
addRequired(p, 'mTime', @isnumeric);
addRequired(p, 'sigH', @isnumeric);
addRequired(p, 'sigL', @isnumeric);
addRequired(p, 'mergeRange', @isnumeric);
addParameter(p, 'channelTag', '', @ischar);
addParameter(p, 'cRange', [0, 1000], @isnumeric);
addParameter(p, 'hRange', [0, 10000], @isnumeric);
addParameter(p, 'figFolder', '', @ischar);
addParameter(p, 'mergeOffset', [], @isnumeric);
addParameter(p, 'mergeSlope', [], @isnumeric);

parse(p, height, mTime, sigH, sigL, mergeRange, varargin{:});

if ~ isempty(p.Results.mergeOffset)
    sigMerge = sigMergeREAL(sigH, sigL, height, mergeRange, ...
        p.Results.mergeSlope, p.Results.mergeOffset);
end

%% linear fit plot
hInd = (height >= mergeRange(1)) & (height <= mergeRange(2));
sigHPoint = reshape(sigH(hInd, :), [], 1);
sigLPoint = reshape(sigL(hInd, :), [], 1);

[slope, offset, slope_1sigma, offset_1sigma] = linfit(sigLPoint, sigHPoint);

figure('Position', [0, 10, 400, 300], 'Units', 'Pixels', 'Color', 'w');
scatter(sigLPoint, sigHPoint, 25, 'Marker', '.'); hold on;
plot([min(sigLPoint), max(sigLPoint)], [min(sigLPoint), max(sigLPoint)] * slope + offset, '--k');

xlabel(sprintf('REAL Low %s', p.Results.channelTag));
ylabel(sprintf('REAL High %s', p.Results.channelTag));

set(gca, 'layer', 'top', 'box', 'on', 'LineWidth', 2);
text(0.4, 0.2, ...
    sprintf('sigH = %f*sigL + %f\nslope: %f+-%f\noffset: %f+-%f\n', slope, offset, slope, slope_1sigma, offset, offset_1sigma), ...
    'Units', 'Normalized');

if ~ isempty(p.Results.figFolder)
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('REAL_%s_linearfit.%s', p.Results.channelTag, 'png')), '-r300');
end

%% signal
figure('Position', [0, 10, 300, 400], 'Units', 'Pixels', 'Color', 'w');

sigHPrf = nanmean(sigH, 2);
sigLPrf = nanmean(sigL, 2);
sigHPrf(sigHPrf <= 0) = NaN;
sigLPrf(sigLPrf <= 0) = NaN;
if ~ isempty(p.Results.mergeOffset)
    sigPrf = nanmean(sigMerge, 2);
    sigPrf(sigPrf <= 0) = NaN;
else
    sigPrf = NaN(size(sigHPrf));
end

p1 = semilogx(sigHPrf, height, '-r', ...
    'LineWidth', 1, ...
    'DisplayName', sprintf('High %s', p.Results.channelTag));
hold on;
p2 = semilogx(sigLPrf, height, '-g', ...
    'LineWidth', 1, ...
    'DisplayName', sprintf('Low %s', p.Results.channelTag));
p3 = semilogx(sigPrf, height, '-k', ...
    'LineWidth', 1, ...
    'DisplayName', sprintf('Merge %s', p.Results.channelTag));
p4 = semilogx((sigLPrf * p.Results.mergeSlope + p.Results.mergeOffset), height, '-.g', ...
    'LineWidth', 2, ...
    'DisplayName', sprintf('Low %s (fit)', p.Results.channelTag));

xlabel(sprintf('REAL %s (signal)', p.Results.channelTag));
ylabel('Height (m)');

xlim(p.Results.cRange);
ylim(p.Results.hRange);

legend([p1, p2, p3, p4], 'Location', 'NorthEast');

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'layer', 'top', 'box', 'on');

if ~ isempty(p.Results.figFolder)
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('REAL_%s_signal_profile.%s', p.Results.channelTag, 'png')), '-r300');
end

end