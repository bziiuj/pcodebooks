classdef PersistenceImageAsFilter < PersistenceRepresentation
	%PERSISTENCEIMAGE

	properties
		resolution
		sigma
		weightingFunction
		persistenceLimits;
	end
  
	methods
		function obj = PersistenceImageAsFilter(resolution, sigma, weightingFunction)
			obj = obj@PersistenceRepresentation();

			obj.resolution = resolution;
			obj.weightingFunction = weightingFunction;
			obj.sigma = sigma;
			obj.feature_size = obj.resolution^2;
		end

		function setup(obj)
			% add path to @kde library
		end

		function obj = fit(obj, diagrams, persistenceLimits)
			disp('Persistence Image does not need fitting.');
		end

		function repr = predict(obj, diagrams, persistenceLimits)
			obj.persistenceLimits = persistenceLimits;

			all_points = cat(1, diagrams{:});
			max_b_p = [max(all_points(:,1)), max(all_points(:,2) - all_points(:,1))]; 

%             rangeEdges = linspace(persistenceLimits(1), ...
%                 persistenceLimits(2), obj.resolution + 1);
%             interval = rangeEdges(2) - rangeEdges(1);
			rangeEdgesX = linspace(0, max_b_p(1), obj.resolution);
			intervalX = rangeEdgesX(2) - rangeEdgesX(1);
			rangeEdgesY = linspace(persistenceLimits(1), ...
				 persistenceLimits(2), obj.resolution);
            intervalY = rangeEdgesY(2) - rangeEdgesY(1);
% 			histogramSigma = (max(persistenceLimits(2), max_b_p(1))/obj.resolution);
			histogramSigma = obj.sigma * max(persistenceLimits(2), max_b_p(1));

            repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
                diagram = diagrams{i};
				diagram = [diagram(:,1), diagram(:,2)-diagram(:,1)];
				histogram = hist3(diagram, ...
					'edges', {rangeEdgesX, rangeEdgesY});
				histogram = imgaussfilt(histogram, histogramSigma);
				repr{i} = histogram;

% 				subplot(2, 1, 1);
% 				plot(diagram(:, 1), diagram(:, 2), 'b.');
%  				xlim([0, max_b_p(1)]); 
% 				ylim([persistenceLimits(1), persistenceLimits(2)]);
% 				subplot(2, 1, 2);
% 				imagesc(transpose(repr{i}));
% 				set(gca,'YDir','normal')
            end
		end
		
		function sufix = getSufix(obj)
			if strcmp(func2str(obj.weightingFunction), 'constant_one')
				ff = 'const';
			elseif strcmp(func2str(obj.weightingFunction), 'linear_ramp')
				ff = 'lin';
			else
				error('unknown weightning function');
			end
			sufix = ['r', num2str(obj.resolution), '_s', num2str(100*obj.sigma),'_', ff];
		end

	end
end
