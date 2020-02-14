function model = draw(win, model, layers, texturesById)

global GL

%% begin drawing
% Screen('BeginOpenGL', win);
try
% glClear(GL.COLOR_BUFFER_BIT); %clear the colour buffer
glUseProgram(model.glsl); % use our shader
glBindVertexArray(model.vao); % bind our VAO
% ensure all textures are loaded

[texids, idToLayer] = unique({layers.textureId});
for ti = 1:numel(texids)
  id = texids{ti};
  layer = layers(idToLayer(ti));
  if ~texturesById.isKey(id)
    texturesById(id) = vis.loadLayerTextures(layer);
  elseif id(1) == '~' % dynamic texture, reload it each time
    vis.reloadLayerTexture(layer, texturesById(id));
  end
end
% load model view projection transforms
% constant for each projection
glUniformMatrix4fv(model.modelIdx, 1, GL.FALSE, model.model);
glUniform1i(model.texIdx, 0);
lastTexId = [];
for li = 1:numel(layers)
  layer = layers(li);
  if any(cellfun('isempty', struct2cell(layer))) || ~layer.show
    continue
  end
  switch layer.blending
    case {'none' ''}
      glBlendFunc(GL.ONE, GL.ZERO);
    case {'dst' 'destination'}
      glBlendFunc(GL.DST_ALPHA, GL.ONE_MINUS_DST_ALPHA);
    case {'src' 'source'}
      glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
    case {'1-src' '1-source'}
      glBlendFunc(GL.ONE_MINUS_SRC_ALPHA, GL.SRC_ALPHA);
  end
  %glColorMask(layer.colourMask(1), layer.colourMask(2),...
  %  layer.colourMask(3), layer.colourMask(4));
  moglcore('glColorMask', layer.colourMask(1), layer.colourMask(2),...
    layer.colourMask(3), layer.colourMask(4));
  %glUniform2fv(model.posIdx, 1, layer.pos);
  %moglcore('glUniform2fv', model.posIdx, 1, single(layer.pos));
  %mat4 view = rot3(zax, posRad.y)*rot3(yax, posRad.x)*rot3(xax, viewRad);
  view = rotRadZ(-deg2rad(layer.pos(2)))*rotRadY(-deg2rad(layer.pos(1)))*rotRadX(deg2rad(layer.viewAngle));
  moglcore('glUniformMatrix4fv', model.viewIdx, 1, GL.FALSE, single(view));
%   glUniform1f(model.viewAngleIdx, layer.viewAngle);
  %glUniform2fv(model.texAngleIdx, 1, layer.texAngle);
  moglcore('glUniform1f', model.texAngleIdx, single(layer.texAngle));
  %glUniform2fv(model.texSizeIdx, 1, layer.size);
  moglcore('glUniform2fv', model.texSizeIdx, 1, single(layer.size));
  %glUniform2fv(model.texOffsetIdx, 1, layer.texOffset);
  moglcore('glUniform2fv', model.texOffsetIdx, 1, single(layer.texOffset));
  %glUniform4fv(model.minColourIdx, 1, layer.minColour);
  moglcore('glUniform4fv', model.minColourIdx, 1, single(layer.minColour));
  %glUniform4fv(model.maxColourIdx, 1, layer.maxColour);
  moglcore('glUniform4fv', model.maxColourIdx, 1, single(layer.maxColour));
  % load texture if different from previous
  texId = layer.textureId;
  if ~strcmp(lastTexId, texId) || texId(1) == '~'
    lastTexId = layer.textureId;
    moglcore('glBindTexture', GL.TEXTURE_2D, texturesById(lastTexId));
  end
%   moglcore('glBindTexture', GL.TEXTURE_2D, texturesById(layer.textureId));
  for si = 1:numel(model.screens)
    % changes per projection
    scr = model.screens(si);
    %glViewport(scr.bounds(1), scr.bounds(2), w, h);
    moglcore('glViewport', scr.bounds(1), model.winSize(2) - scr.bounds(2) - scr.h, scr.w, scr.h);
    %glUniformMatrix4fv(model.projectionIdx, 1, GL.FALSE, scr.projection);
    moglcore('glUniformMatrix4fv', model.projectionIdx, 1, GL.FALSE, single(scr.projection));
    %glDrawElements(GL.TRIANGLES, numel(model.tridx), GL.UNSIGNED_SHORT, 0);
    moglcore('glDrawElements', GL.TRIANGLES, numel(model.tridx), GL.UNSIGNED_SHORT, 0);
  end
end
% glBindVertexArray(0);
% glUseProgram(0);
catch ex
  Screen('EndOpenGL', win);
  rethrow(ex);
end
% Screen('EndOpenGL', win);