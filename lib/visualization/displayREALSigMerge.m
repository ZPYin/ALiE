function [fh] = displayREALSigMerge(height, mTime, sigH, sigL, mergeRange, varargin)
% displayREALSigMerge description
% USAGE:
%    [fh] = displayREALSigMerge(params)
% INPUTS:
%    params
% OUTPUTS:
%    fh
% EXAMPLE:
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
addParameter(p, 'figFolder', '', @ischar);

parse(p, height, mTime, sigH, sigL, mergeRange, varargin{:});

%% display signal color plot
figure('Color', 'w');

subplot(211);
p1 = pcolor(mTime, height, sigH); hold on;
p1.EdgeColor = 'None';

xlabel('Time (LT)');
ylabel('Height (m)');
title(sprintf('REAL High %s', p.Results.channelTag));

xlim([mTime(1), mTime(end)]);
ylim([height(1), height(end)]);
colormap('jet');

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'layer', 'top', 'box', 'on', 'LineWidth', 2);
datetick(gca, 'x', 'HH:MM', 'keeplimits', 'keepticks');

colorbar();

subplot(212);
p1 = pcolor(mTime, height, sigL); hold on;
p1.EdgeColor = 'None';

xlabel('Time (LT)');
ylabel('Height (m)');
title(sprintf('REAL Low %s', p.Results.channelTag));

xlim([mTime(1), mTime(end)]);
ylim([height(1), height(end)]);
caxis(p.Results.cRange);
colormap('jet');

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'layer', 'top', 'box', 'on', 'LineWidth', 2);
datetick(gca, 'x', 'HH:MM', 'keeplimits', 'keepticks');

colorbar();

if ~ isempty(p.Results.figFolder)
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('REAL_%s_signal_colorplot.%s', p.Results.figTitle, 'png')), '-r300');
end

%% linear fit plot
hInd = (height >= mergeRange(1)) & (height <= mergeRange(2));
sigHPoint = reshape(sigH(hInd, :), [], 1);
sigLPoint = reshape(sigL(hInd, :), [], 1);

[slope, offset, slope_1sigma, offset_1sigma] = linfit(sigLPoint, sigHPoint);

figure('Color', 'w');
p1 = scatter(sigLPoint, sigHPoint, 25, 'Marker', '.'); hold on;
p2 = plot([min(sigLPoint), max(sigLPoint)], [min(sigLPoint), max(sigLPoint)] * slope + offset, '--k');

xlabel(sprintf('REAL Low %s', p.Results.channelTag));
ylabel(sprintf('REAL High %s', p.Results.channelTag));

set(gca, 'layer', 'top', 'box', 'on', 'LineWidth', 2);
text(0.4, 0.2, sprintf('sigH = %f*sigL + %f\nslope: %f+-%f\noffset: %f+-%f\n', slope, offset, slope, slope_1sigma, offset, offset_1sigma), 'Units', 'Normalized');

if ~ isempty(p.Results.figFolder)
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('REAL_%s_linearfit.%s', p.Results.figTitle, 'png')), '-r300');
end

%% signal
figure('Color', 'w');

sigHPrf = nanmean(sigH, 2);
sigLPrf = nanmean(sigL, 2);
sigHPrf(sigHPrf <= 0) = NaN;
sigLPrf(sigLPrf <= 0) = NaN;

p1 = semilogx(sigHPrf, height, '-r', 'LineWidth', 1, 'DisplayName', sprintf('High %s', p.Results.channelTag)); hold on;
p2 = semilogx(sigLPrf, height, '-k', 'LineWidth', 1, 'DisplayName', sprintf('Low %s', p.Results.channelTag));

xlabel(sprintf('REAL %s', p.Results.channelTag));
ylabel('Height (m)');

xlim([1e-1, 1e6]);
ylim([0, 10000]);

legend([p1, p2], 'Location', 'NorthEast');

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'layer', 'top', 'box', 'on');

if ~ isempty(p.Results.figFolder)
    export_fig(gcf, fullfile(p.Results.figFolder, sprintf('REAL_%s_signal_profile.%s', p.Results.figTitle, 'png')), '-r300');
end

end