function [x, y, z, u, v, tridx] = uniSphereTriangles(r, n)
%vis.uniSphereTriangles UV sphere mapping
%   Returns the UV sphere mesh coordinates (x,y,z), the UV texture map
%   (u,v) and the indices of each triangle on the sphere.  The sphere is a
%   unit sphere

% [el, az] = ndgrid(...
%   linspace(-pi/2, pi/2, nRings+1),...
%   linspace(-pi, pi, nSectors+1));
% 
% x = cos(el).*cos(az);
% y = cos(el).*sin(az);
% z = sin(el);

[x, y, z] = sphere(2*n); % create a 2n-sphere, then remove even rows
even = 2:2:2*n;
x(even,:) = [];
y(even,:) = [];
z(even,:) = [];
% rescale by radius
x = r*x;
y = r*y;
z = r*z;

% base index
[basejj, baseii] = ndgrid(1:size(x, 2), 1:size(x, 1));
baseii = baseii(:)';
basejj = basejj(:)';

tri1offsets = [0, 0; 1 1; 0 1]; %NE triangle of square
tri2offsets = [0, 0; 1 0; 1 1]; %SW triangle of square

% tridx = [indices(tri1offsets)];
nTris = 2*numel(x); % two triangles per sector
tridx = zeros(3, nTris);
tridx(:,1:2:nTris) = indices(tri1offsets);
tridx(:,2:2:nTris) = indices(tri2offsets);

[v, u] = ndgrid(linspace(0, 1, size(x, 1)), linspace(-.5, .5, size(x, 2)));

% elev = linspace(-pi/2, pi/2, n + 1)';
% r = cos(elev);
% u = bsxfun(@times, u, r);

u = u + 0.5;

function idx = indices(offsets)
  ii = bsxfun(@plus, baseii, offsets(:,1));
  jj = bsxfun(@plus, basejj, offsets(:,2));
  idx = (n + 1)*(jj - 1) + ii; % convert to 1D index
end


end

