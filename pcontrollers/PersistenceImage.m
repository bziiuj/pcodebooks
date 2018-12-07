classdef PersistenceImage < PersistenceRepresentation
	%PERSISTENCEIMAGE

	properties
		resolution
		sigma
		weightingFunction
		parallel
		persistenceLimits;
	end
  
	methods
		function obj = PersistenceImage(resolution, sigma, ...
			weightingFunction)
			obj = obj@PersistenceRepresentation();

			obj.resolution = resolution;
			obj.sigma = sigma;
			obj.weightingFunction = weightingFunction;
			obj.parallel = false;
			obj.feature_size = obj.resolution^2;
		end

		function setup(obj)
			PI_path = which('PersistenceImage');
			[filepath, name, ext] = fileparts(PI_path);
			addpath(strcat(filepath,'/../../PersistenceImages/matlab_code'));
			%addpath('../PersistenceImages/matlab_code')
		end

		function obj = fit(obj, diagrams, persistenceLimits)
			obj.persistenceLimits = persistenceLimits;
			disp('Persistence Image does not need fitting.');
		end

		function repr = predict(obj, diagrams, persistenceLimits)
			obj.persistenceLimits = persistenceLimits;
			% diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];
			% weightsLimits = [diagramLimits(1)/2, diagramLimits(2) - diagramLimits(1)];

	%			if useold
	%				% Parameters for weight function
	%				weightsLimits = [0, diagramLimits(2) - diagramLimits(1)];
	%				repr = newmake_PIs(diagrams, obj.resolution, obj.sigma, ...
	%					obj.weightingFunction, weightsLimits, 1);
	%			else
%				% Parameters for weight function
%				weightsLimits = [0, diagramLimits(2) - diagramLimits(1)];
%				% Lower bound for birth and upper bound for persistence. Other points will be rejected.
%				diagramLimitsPersist = [diagramLimits(1), ...
%					diagramLimits(2) - diagramLimits(1)];
%
%				repr = new_make_PIs(diagrams, obj.resolution, obj.sigma, ...
%				obj.weightingFunction, weightsLimits, 1, ...
%				diagramLimitsPersist, obj.parallel);
			ndiag = length(diagrams);
			repr = cell(ndiag, 1);
			
			if obj.parallel
				all_points = cat(1, diagrams{:});
				max_b_p = [max(all_points(:,1)), max(all_points(:,2) - all_points(:,1))]; 
				
				patch_size = 25;
				patches = ceil(ndiag/patch_size);
				prepr = cell(patches, 1);
				parfor p = 1:patches
					lidx = min((p-1) * patch_size + 1, ndiag);
					ridx = min(p * patch_size, ndiag);
					prepr{p} = new_make_PIs(diagrams(lidx:ridx), obj.resolution, obj.sigma, ...
						obj.weightingFunction, persistenceLimits, 1, max_b_p);
				end
				repr = cat(1, prepr{:});
			else
				repr = new_make_PIs(diagrams, obj.resolution, obj.sigma, ...
					obj.weightingFunction, persistenceLimits, 1);
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

function cutted = remove_exceeding_points(diagrams, limits)
	% limits = [min_birth, max_pers];
	n = length(diagrams);
	for i=1:n
		points = b_p_data{j,i,d};
		points = points(find(points(:,1) >= type_params(d, 1)),:);
		points = points(find(points(:,2) <= type_params(d, 2)),:);
		b_p_data{j,i,d} = points;
	end
end
