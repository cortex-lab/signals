function [layer, img] = circLayer(pos, dims, orientation)
% TODO Document

%% circle
if length(dims) == 1; dims = [dims dims]; end
border = 0.05;

% upsample
radius = round(dims(1) * (0.9^(dims(1)-23)+1));
y = round(dims(2) * (0.9^(dims(2)-23)+1));

[xx, yy] = meshgrid(1:radius, 1:y);

dd = sqrt(xx.^2 + yy.^2);
img = taper(dd) + taper(-dd) - 1; % Border anti-aliasing
img = single([rot90(img,2), flipud(img); fliplr(img), img]); % Put quarters together

  function y = taper(x)
    y = -2*(x - radius*(1 - 0.5*border))./(radius*border);
    y = 0.5*(erf(y) + 1);
  end

%% set layer properties
layer = vis.emptyLayer(); % create new layer
layer.interpolation = 'linear';
layer.texOffset = pos;
layer.texAngle = orientation;
layer.size = dims;
layer.isPeriodic = false;
end