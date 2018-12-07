function cPI = consolidated_PI(diagrams, sigma, resolution, sample)
	disp('computing consolidated PI');
	points = cat(1, diagrams{:});

	if length(points) > sample
		points = points(randsample(1:size(points, 1), sample), :);
	end
	disp([min(points(:,1)), min(points(:,2))]);
	
	points = [points(:,1) - min(points(:,1)), points(:,2) - min(points(:,1))];
	disp([min(points(:,1)), min(points(:,2))]);
	
	bp_points = [points(:,1), points(:, 2) - points(:, 1)];
	persistence_limits = [quantile(bp_points(:,2),0.005), quantile(bp_points(:,2),0.995)];

	cPI = new_make_PIs({points}, resolution, sigma, @constant_one, persistence_limits);
end
