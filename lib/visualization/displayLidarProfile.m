function [fh] = displayLidarProfile(inData, varargin)
% displayLidarProfile description
% USAGE:
%    [fh] = displayLidarProfile(inData, varargin)
% INPUTS:
%    inData, varargin
% OUTPUTS:
%    fh
% EXAMPLE:
% HISTORY:
%    2021-09-18: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'inData', @isstruct);
addParameter(p, 'hRange', [0, 20000], @isnumeric);
addParameter(p, 'sigRange', [1e-4, 10], @isnumeric);
addParameter(p, 'rcsRange', [1e4, 1e8], @isnumeric);
addParameter(p, 'bgRange', [-0.01, 0.01], @isnumeric);
addParameter(p, 'bgBins', [], @isnumeric);
addParameter(p, 'gliding_window', 1, @isnumeric);
addParameter(p, 'figTitle', '', @ischar);
addParameter(p, 'figFile', '', @ischar);

parse(p, inData, varargin{:});

%% parameter initialization
lineColors = [65, 105, 226; ...   % 355 elastic
              124, 104, 238; ...   % 355 parallel
              102, 51, 152; ...   % 355 cross
              140, 110, 50; ...   % 387
              176, 196, 223; ...   % 407
              46, 138, 87; ...   % 532 elastic
              0, 255, 127; ...   % 532 parallel
              0, 128, 129; ...   % 532 cross
              119, 136, 152; ...   % 607
              220, 20, 59; ...   % 1064 elastic
              255, 106, 180; ...   % 1064 parallel
              253, 219, 236] / 255;   % 1064 cross

fh = figure('Position', [0, 10, 800, 400], 'Units', 'Pixels', 'Color', 'w');

figPos = subfigPos([0.1, 0.15, 0.86, 0.75], 1, 3, 0.04, 0);

% raw signal
subplot('Position', figPos(1, :), 'Units', 'Normalized');

lineInstance = [];
if ~ isempty(inData.sig355)
    sig = smooth(inData.sig355, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(1, :), 'DisplayName', '355 E'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig355P)
    sig = smooth(inData.sig355P, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(2, :), 'DisplayName', '355 P'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig355S)
    sig = smooth(inData.sig355S, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(3, :), 'DisplayName', '355 S'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig387)
    sig = smooth(inData.sig387, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(4, :), 'DisplayName', '387'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig407)
    sig = smooth(inData.sig407, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(5, :), 'DisplayName', '407 E'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig532)
    sig = smooth(inData.sig532, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(6, :), 'DisplayName', '532 E'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig532P)
    sig = smooth(inData.sig532P, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(7, :), 'DisplayName', '532 P'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig532S)
    sig = smooth(inData.sig532S, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(8, :), 'DisplayName', '532 S'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig607)
    sig = smooth(inData.sig607, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(9, :), 'DisplayName', '607'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig1064)
    sig = smooth(inData.sig1064, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(10, :), 'DisplayName', '1064 E'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig1064P)
    sig = smooth(inData.sig1064P, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(11, :), 'DisplayName', '1064 P'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

if ~ isempty(inData.sig1064S)
    sig = smooth(inData.sig1064S, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'Color', lineColors(12, :), 'DisplayName', '1064S'); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

text(1.7, 1.07, p.Results.figTitle, 'FontSize', 14, 'FontWeight', 'Bold', 'Units', 'Normalized', 'HorizontalAlignment', 'Center', 'Color', 'k');
hold on;

xlabel('Signal (a.u.)');
ylabel('Height (m)')

xlim(p.Results.sigRange);
ylim(p.Results.hRange);

set(gca, 'XMinorTick', 'on', 'XMinorTick', 'on', 'FontSize', 12, 'Layer', 'Top', 'LineWidth', 2, 'Box', 'on');
legend(lineInstance, 'Location', 'NorthEast');

% range-corrected signal
subplot('Position', figPos(2, :), 'Units', 'Normalized');

if isempty(p.Results.bgBins)
    bgInd = (length(inData.height) - 500):(length(inData.height));
else
    bgInd = p.Results.bgBins(1):p.Results.bgBins(2);
end

if ~ isempty(inData.sig355)
    sig = smooth((inData.sig355 - nanmean(inData.sig355(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(1, :)); hold on;
end

if ~ isempty(inData.sig355P)
    sig = smooth((inData.sig355P - nanmean(inData.sig355P(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(2, :)); hold on;
end

if ~ isempty(inData.sig355S)
    sig = smooth((inData.sig355S - nanmean(inData.sig355S(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(3, :)); hold on;
end

if ~ isempty(inData.sig387)
    sig = smooth((inData.sig387 - nanmean(inData.sig387(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(4, :)); hold on;
end

if ~ isempty(inData.sig407)
    sig = smooth((inData.sig407 - nanmean(inData.sig407(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(5, :)); hold on;
end

if ~ isempty(inData.sig532)
    sig = smooth((inData.sig532 - nanmean(inData.sig532(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(6, :)); hold on;
end

if ~ isempty(inData.sig532P)
    sig = smooth((inData.sig532P - nanmean(inData.sig532P(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(7, :)); hold on;
end

if ~ isempty(inData.sig532S)
    sig = smooth((inData.sig532S - nanmean(inData.sig532S(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(8, :)); hold on;
end

if ~ isempty(inData.sig607)
    sig = smooth((inData.sig607 - nanmean(inData.sig607(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(9, :)); hold on;
end

if ~ isempty(inData.sig1064)
    sig = smooth((inData.sig1064 - nanmean(inData.sig1064(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(10, :)); hold on;
end

if ~ isempty(inData.sig1064P)
    sig = smooth((inData.sig1064P - nanmean(inData.sig1064P(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(11, :)); hold on;
end

if ~ isempty(inData.sig1064S)
    sig = smooth((inData.sig1064S - nanmean(inData.sig1064S(bgInd))) .* inData.height.^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineColors(12, :)); hold on;
end

xlabel('rcs (a.u.)');
ylabel('')

xlim(p.Results.rcsRange);
ylim(p.Results.hRange);

set(gca, 'XMinorTick', 'on', 'XMinorTick', 'on', 'YTickLabel', '', 'FontSize', 12, 'Layer', 'Top', 'LineWidth', 2, 'Box', 'on');

% background signal
subplot('Position', figPos(3, :), 'Units', 'Normalized');

if ~ isempty(inData.sig355)
    sig = smooth((inData.sig355 - nanmean(inData.sig355(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(1, :)); hold on;
end

if ~ isempty(inData.sig355P)
    sig = smooth((inData.sig355P - nanmean(inData.sig355P(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(2, :)); hold on;
end

if ~ isempty(inData.sig355S)
    sig = smooth((inData.sig355S - nanmean(inData.sig355S(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(3, :)); hold on;
end

if ~ isempty(inData.sig387)
    sig = smooth((inData.sig387 - nanmean(inData.sig387(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(4, :)); hold on;
end

if ~ isempty(inData.sig407)
    sig = smooth((inData.sig407 - nanmean(inData.sig407(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(5, :)); hold on;
end

if ~ isempty(inData.sig532)
    sig = smooth((inData.sig532 - nanmean(inData.sig532(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(6, :)); hold on;
end

if ~ isempty(inData.sig532P)
    sig = smooth((inData.sig532P - nanmean(inData.sig532P(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(7, :)); hold on;
end

if ~ isempty(inData.sig532S)
    sig = smooth((inData.sig532S - nanmean(inData.sig532S(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(8, :)); hold on;
end

if ~ isempty(inData.sig607)
    sig = smooth((inData.sig607 - nanmean(inData.sig607(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(9, :)); hold on;
end

if ~ isempty(inData.sig1064)
    sig = smooth((inData.sig1064 - nanmean(inData.sig1064(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(10, :)); hold on;
end

if ~ isempty(inData.sig1064P)
    sig = smooth((inData.sig1064P - nanmean(inData.sig1064P(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(11, :)); hold on;
end

if ~ isempty(inData.sig1064S)
    sig = smooth((inData.sig1064S - nanmean(inData.sig1064S(bgInd))), p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineColors(12, :)); hold on;
end

plot([0, 0], p.Results.hRange, '--k', 'LineWidth', 2);

xlabel('bg (a.u.)');
ylabel('')

xlim(p.Results.bgRange);
ylim(p.Results.hRange);

set(gca, 'XMinorTick', 'on', 'XMinorTick', 'on', 'YTickLabel', '', 'FontSize', 12, 'Layer', 'Top', 'LineWidth', 2, 'Box', 'on');

if ~ isempty(p.Results.figFile)
    export_fig(gcf, p.Results.figFile, '-r300');
end

end