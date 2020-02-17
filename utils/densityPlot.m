function densityPlot(points, limits, res, scale)
	if nargin < 3
		res = [30 30];
	end
	X = linspace(limits(1), limits(2), res(1));
	Y = linspace(limits(3), limits(4), res(2));
	[X, Y] = meshgrid(X, Y);
	X = reshape(X, [res(1)*res(2), 1]);
	Y = reshape(Y, [res(1)*res(2), 1]);
	
	[f, xi] = ksdensity(points, [X,Y]);
	if nargin > 3
		f = scale * f / max(f);
	end
	[~, c] = contourf(reshape(xi(:,1), res), reshape(xi(:,2), res), reshape(f, res), 25, ':');
	c.LineWidth = 0.00001;
% 	
% 	if nargin > 2
% 		title(name);
% 	end
end