function [fh] = displayLidarProfile(inData, chTag, varargin)
% DISPLAYLIDARPROFILE description
%
% USAGE:
%    [fh] = displayLidarProfile(inData, chTag, varargin)
%
% INPUTS:
%    inData: struct
%    chTag: cell
%
% KEYWORDS:
%    hRange: 2-element array
%    sigRange: 2-element array
%    rcsRange: 2-element array
%    bgRange: 2-element array
%    bgBins: 2-element array
%    gliding_window: numeric
%    figTitle: char
%    figFile: char
%
% OUTPUTS:
%    fh: figure handle
%
% HISTORY:
%    2021-09-18: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'inData', @isstruct);
addRequired(p, 'chTag', @iscell);
addParameter(p, 'hRange', [0, 20000], @isnumeric);
addParameter(p, 'sigRange', [1e-4, 10], @isnumeric);
addParameter(p, 'rcsRange', [1e4, 1e8], @isnumeric);
addParameter(p, 'bgRange', [-0.01, 0.01], @isnumeric);
addParameter(p, 'bgBins', [], @isnumeric);
addParameter(p, 'gliding_window', 1, @isnumeric);
addParameter(p, 'figTitle', '', @ischar);
addParameter(p, 'figFile', '', @ischar);

parse(p, inData, chTag, varargin{:});

fh = figure('Position', [0, 10, 800, 400], 'Units', 'Pixels', 'Color', 'w');

figPos = subfigPos([0.1, 0.15, 0.86, 0.75], 1, 3, 0.04, 0);

% raw signal
subplot('Position', figPos(1, :), 'Units', 'Normalized');

lineInstance = [];
for iCh = 1:length(chTag)
    sig = smooth(inData.rawSignal(iCh, :), p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    p1 = semilogx(sig, inData.height, 'DisplayName', chTag{iCh}); hold on;
    lineInstance = cat(1, lineInstance, p1);
end

text(1.7, 1.07, p.Results.figTitle, 'FontSize', 14, ...
    'FontWeight', 'Bold', ...
    'Units', 'Normalized', ...
    'HorizontalAlignment', 'Center', ...
    'Color', 'k');
hold on;

xlabel('Signal (a.u.)');
ylabel('Height (m)')

xlim(p.Results.sigRange);
ylim(p.Results.hRange);

set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'FontSize', 12, ...
         'Layer', 'Top', ...
         'LineWidth', 2, ...
         'Box', 'on');
legend(lineInstance, 'Location', 'NorthEast');

% range-corrected signal
subplot('Position', figPos(2, :), 'Units', 'Normalized');

if isempty(p.Results.bgBins)
    bgInd = (length(inData.height) - 500):(length(inData.height));
else
    bgInd = p.Results.bgBins(1):p.Results.bgBins(2);
end

for iCh = 1:length(chTag)
    sig = smooth((inData.rawSignal(iCh, :) - ...
                  nanmean(inData.rawSignal(iCh, bgInd), 2)) .* ...
            transpose(inData.height).^2, p.Results.gliding_window);
    sig(sig <= 0) = NaN;
    semilogx(sig, inData.height, 'Color', lineInstance(iCh).Color); hold on;
end

xlabel('rcs (a.u.)');
ylabel('')

xlim(p.Results.rcsRange);
ylim(p.Results.hRange);

set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'YTickLabel', '', ...
         'FontSize', 12, ...
         'Layer', 'Top', ...
         'LineWidth', 2, ...
         'Box', 'on');

% background signal
subplot('Position', figPos(3, :), 'Units', 'Normalized');

for iCh = 1:length(chTag)
    sig = smooth(inData.rawSignal(iCh, :) - ...
                    nanmean(inData.rawSignal(iCh, bgInd), 2), ...
                p.Results.gliding_window);
    plot(sig, inData.height, 'Color', lineInstance(iCh).Color); hold on;
end

plot([0, 0], p.Results.hRange, '--k', 'LineWidth', 2);

xlabel('Sig no bg (a.u.)');
ylabel('')

xlim(p.Results.bgRange);
ylim(p.Results.hRange);

set(gca, 'XMinorTick', 'on', ...
         'YMinorTick', 'on', ...
         'YTickLabel', '', ...
         'FontSize', 12, ...
         'Layer', 'Top', ...
         'LineWidth', 2, ...
         'Box', 'on');

if ~ isempty(p.Results.figFile)
    export_fig(gcf, p.Results.figFile, '-r300');
end

end