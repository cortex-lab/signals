function P = planeProjection(centre, dims, viewAngle)
%PLANEPROJECTION Plane projection transformation matrix
%   P = PLANEPROJECTION(centre, dims, viewAngle) returns a projection
%   matrix given a flat screen projection, where the screen has 'centre',
%   (x,y,z) relative to plane orthogonal from viewing point, 'dims' in
%   physical units (cm), and 'viewAngle' (rad), (azi,elv) from view along
%   orthogonal.

%% Build view rotation matrices
Raz = rotRadY(viewAngle(1));
Rel = rotRadX(-viewAngle(2));

%% build perspective matrix
% fairly extreme z-clipping distances
fzNear = 10e-3;
fzFar = 10e4;
fzz = fzFar + fzNear;
fzw = 2*fzFar*fzNear;
fzs = 1/(fzNear - fzFar);

perspective = [
  centre(3)      0     centre(1)    0
  0       centre(3)    centre(2)    0
  0              0           fzz    fzw
  0              0            -1    0
  ];
 
% transform to convert xy physical units and fz range to clip space 
rescale = diag([2/dims(1) 2/dims(2) fzs 1]);
% final camera -> clip transform
P = single(rescale*perspective*Rel*Raz);

end

