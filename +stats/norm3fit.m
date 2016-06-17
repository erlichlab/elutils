function [mu C] = norm3fit(W, box, step)
% function [mu C] = norm3fit(W, box, step)
%
% W:    3D matrix of functional values (weights)
% box:  [xmin ymin zmin xlen ylen zlen]
% step: [xstep ystep zstep]
%
% returns the mean and covariance matrix

W = W/sum(W(:));

[X Y Z] = ndgrid(box(1):step(1):box(1)+box(4), ...
	               box(2):step(2):box(2)+box(5), ...
				   box(3):step(3):box(3)+box(6));

mu = [sum(X(:).*W(:)) sum(Y(:).*W(:)) sum(Z(:).*W(:))];

varx  = sum((X(:) - mu(1)).^2 .* W(:));
vary  = sum((Y(:) - mu(2)).^2 .* W(:));
varz  = sum((Z(:) - mu(3)).^2 .* W(:));
varxy = sum((X(:) - mu(1)).*(Y(:) - mu(2)) .* W(:));
varxz = sum((X(:) - mu(1)).*(Z(:) - mu(3)) .* W(:));
varyz = sum((Y(:) - mu(2)).*(Z(:) - mu(3)) .* W(:));

C = [varx   varxy  varxz; ...
	 varxy  vary   varyz; ...
	 varxz  varyz  varz]; 