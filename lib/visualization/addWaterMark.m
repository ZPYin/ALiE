function [ax] = addWaterMark(wmImgPath, wmRelPos, varargin)
% ADDWATERMARK add watermark to current figure.
%
% USAGE:
%    [ax] = addWaterMark(wmImgPath, wmRelPos)
%
% INPUTS:
%    wmImgPath: char
%        absolute path of watermark image.
%    wmRelPos: 4-element array
%        [left, bottom, width, height] of the watermark.
%
% KEYWORDS:
%    transparency: numeric
%        transparency. (0 for fully transparent)
%
% OUTPUTS:
%    ax: axes handle.
%
% HISTORY:
%    2021-10-09: first edition by Zhenping
% .. Authors: - zhenping@tropos.de

p = inputParser;
p.KeepUnmatched = true;

addRequired(p, 'wmImgPath', @ischar);
addRequired(p, 'wmRelPos', @isnumeric);
addParameter(p, 'transparency', 0.2, @isnumeric);

parse(p, wmImgPath, wmRelPos, varargin{:});

[wm, ~, imgAlpha] = imread(wmImgPath);
wm1 = wm;
imgAlpha = double(imgAlpha);
imgAlpha(imgAlpha > 0.01) = p.Results.transparency;

axPre = gca;
pos = get(gca, 'position');

pos_new = [pos(1) + pos(3) * (wmRelPos(1) - wmRelPos(3) / 2), pos(2) + pos(4) * (wmRelPos(2) - wmRelPos(4) / 2), pos(3) * wmRelPos(3), pos(4) * wmRelPos(4)];
axes_new = axes('position', pos_new);
axes(axes_new);
hold on;
imgHandle = imshow(wm1, []);
set(axes_new, 'handlevisibility', 'off', ...
    'visible', 'off');
imgHandle.AlphaData = imgAlpha;

end