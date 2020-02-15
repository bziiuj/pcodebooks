classdef PersistenceImage < PersistenceRepresentation
	%PERSISTENCEIMAGE

	properties
		resolution
		sigma
		birthLimits
		persLimits
	end
  
	methods
		function obj = PersistenceImage(resolution, sigma, varargin)
			obj = obj@PersistenceRepresentation();
			obj.resolution = resolution;
			obj.sigma = sigma;
			obj.feature_size = obj.resolution^2;

			obj.options = struct('weightingfunction', 'lin', ...
				'parallel', false, 'norm', false);
			obj.options = named_options(obj.options, varargin{:});
		end

		function setup(obj) %#ok<MANU>
			PI_path = which('PersistenceImage');
			[filepath, ~, ~] = fileparts(PI_path);
			addpath(strcat(filepath,'/../../PersistenceImages/matlab_code'));
		end
		
% 		function obj = fit(obj, diagrams, persistenceLimits)
% 			obj.persistenceLimits = persistenceLimits;
% 			disp('Persistence Image does not need fitting.');
% 		end

		function obj = fit(obj, diagrams)
			allPoints = cat(1, diagrams{:});
			%%% transform points from [birth, death] to [birth, persistence]
			allBPpoints = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];
			%%% compute birth and persistence Limits
			obj.birthLimits = [min(allBPpoints(:,1)), max(allBPpoints(:,1))];
			obj.persLimits = [quantile(allBPpoints(:,2), 0.01), max(allBPpoints(:,2))];
% 			disp('Persistence Image does not need fitting.');
		end

		function repr = predict(obj, diagrams)
% 			ndiags = cell(length(diagrams), 1);
% 			for i = 1:numel(diagrams)
% 				ndiags{i} = obj.prepare_diagram(diagrams{i});
% 			end
			if obj.options.parallel
				error('TODO')
% 				ndiag = length(diagrams);
%				repr = cell(ndiag, 1);
% 				all_points = cat(1, diagrams{:});
% 				max_b_p = [max(all_points(:,1)), max(all_points(:,2) - all_points(:,1))]; 
% 				
% 				patch_size = 25;
% 				patches = ceil(ndiag/patch_size);
% 				prepr = cell(patches, 1);
% 				parfor p = 1:patches
% 					lidx = min((p-1) * patch_size + 1, ndiag);
% 					ridx = min(p * patch_size, ndiag);
% 					prepr{p} = new_make_PIs(diagrams(lidx:ridx), obj.resolution, obj.sigma, ...
% 						obj.weightingFunction, persistenceLimits, 1, max_b_p);
% 				end
% 				repr = cat(1, prepr{:});
			else
				switch obj.options.weightingfunction
					case 'const'
						w = @constant_one;
					case 'lin'
						w = @linear_ramp;
					case 'pow2'
						w = @power2;
					case 'pow3'
						w = @power3;
					otherwise
						error('unknown type of weighting function')
				end
						
				repr = make_PIs(diagrams, obj.resolution, obj.sigma, ...
					w, obj.persLimits, 1);
			end
		end

		function sufix = getSufix(obj)
			sufix = ['r', num2str(obj.resolution), '-', ...
				's', num2str(100*obj.sigma), '-', ...
				obj.options.weightingfunction, '-', ...
				iif(obj.options.norm, 'norm', 'nonorm') ];
		end
		
		function ndiag = prepare_diagram(obj, diagram)
			ndiag = [diagram(:, 1), diagram(:, 2) - diagram(:, 1)];
			if obj.options.norm
				ndiag = ndiag - [obj.birthLimits(1), obj.persLimits(1)];
				ndiag = ndiag ./ obj.range;
				ndiag = ndiag .* obj.options.scale;
			end
		end		
	end
end

% function cutted = remove_exceeding_points(diagrams, limits)
% 	% limits = [min_birth, max_pers];
% 	n = length(diagrams);
% 	for i=1:n
% 		points = b_p_data{j,i,d};
% 		points = points(find(points(:,1) >= type_params(d, 1)),:);
% 		points = points(find(points(:,2) <= type_params(d, 2)),:);
% 		b_p_data{j,i,d} = points;
% 	end
% end
