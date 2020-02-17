function show_pcodebook(centers, points, labels, name, csz)
	sz = 6;	
	if nargin > 1
		scatter(points(:,1), points(:,2), sz, labels, 'filled');
		hold on;
	end
	
	if nargin > 4
		scatter(centers(:,1), centers(:,2), csz*10+0.1, 1:length(centers), 'filled');
	else
		scatter(centers(:,1), centers(:,2), sz*10, 1:length(centers), 'filled');
	end
	
	voronoi(centers(:,1), centers(:,2))
	if nargin > 4
		title(name);
	end
end