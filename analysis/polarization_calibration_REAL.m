caliRange_REAL = [0, 12000];
caliRangeSlot_REAL = [1000, 4000];

height = GainRatioS2.Distm;
sigLP = GainRatioS2.SegnalePL;
sigLS = GainRatioS2.SegnaleSL;
gainRatio = sqrt(sigLP ./ sigLS);

% REAL
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (height >= caliRange_REAL(1)) & (height <= caliRange_REAL(2));
gainRatio_REAL = nanmean(gainRatio(isHCali));
gainRatioStd_REAL = nanstd(gainRatio(isHCali));
fprintf('Gainratio REAL: %f+-%f\n', gainRatio_REAL, gainRatioStd_REAL);
p1 = plot(height(isHCali), gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([height(1), height(end)], [1, 1] * gainRatio_REAL, '--k');
p3 = plot([height(1), height(end)], [1, 1] * gainRatioStd_REAL + gainRatio_REAL, '-.k');
p4 = plot([height(1), height(end)], [-1, -1] * gainRatioStd_REAL + gainRatio_REAL, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('REAL');

xlim(caliRange_REAL);
ylim([0, 0.6]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('REAL_gaintio_full.png'), '-r300');

% REAL (slot)
figure('Position', [0, 10, 500, 300], 'Units', 'Pixels', 'Color', 'w');

isHCali = (height >= caliRangeSlot_REAL(1)) & (height <= caliRangeSlot_REAL(2));
gainRatio_REAL = nanmean(gainRatio(isHCali));
gainRatioStd_REAL = nanstd(gainRatio(isHCali));
fprintf('Gainratio REAL: %f+-%f\n', gainRatio_REAL, gainRatioStd_REAL);
p1 = plot(height(isHCali), gainRatio(isHCali), '-', 'Color', [65, 105, 226]/255, 'Linewidth', 2); hold on;
p2 = plot([height(2), height(end)], [1, 1] * gainRatio_REAL, '--k');
p3 = plot([height(2), height(end)], [1, 1] * gainRatioStd_REAL + gainRatio_REAL, '-.k');
p4 = plot([height(2), height(end)], [-1, -1] * gainRatioStd_REAL + gainRatio_REAL, '-.k');

xlabel('Height (m)');
ylabel('Gain ratio');
title('REAL');

xlim(caliRangeSlot_REAL);
ylim([0, 0.6]);

set(gca, 'XMinorTick', 'on', 'YMinorTick', 'on', 'Linewidth', 2, 'Box', 'on', 'Layer', 'top');
export_fig(gcf, fullfile('REAL_gaintio_slot.png'), '-r300');