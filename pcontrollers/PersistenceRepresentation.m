classdef PersistenceRepresentation
	%PERSISTENCEREPRESENTATION

	properties
		seed
		feature_size
		options
	end

	methods
		function obj = PersistenceRepresentation()
			obj.setup();
		end

		% to override
		function setup(obj) %#ok<MANU>
			pbow_path = which('PersistenceRepresentation');
			[filepath, ~, ~] = fileparts(pbow_path);
			addpath(strcat(filepath,'/../utils'))
		end
		
		% to override
		function obj = fit(obj, diagrams)
		%%% Fit descriptor object to the provided set of persistence diagrams.
		%	Function should return object itself, possibly modified.
		%	diagrams - 1-dimensional cell array of persistence diagrams 
			error('fit function is not overrided');
		end

		% to override
		function repr = predict(obj, diagrams)
		%%% Get the representation of given persistence diagrams.
		%	diagrams - 1-dimensional cell array of persistence diagrams 
		%	repr 	- 1-dimensional cell array of persistence diagrams representation
			repr = [0];
			error('predict function is not overrided');
		end
			
		% to override for non-vector representations
		function K = generateKernel(obj, repr)
			reprVect = repr;
			for i = 1:numel(reprVect)
				reprVect{i} = reprVect{i}(:);
			end
			reprVect = cat(2, reprVect{:});
			K = pdist2(reprVect', reprVect');
			% K = exp(pdist2(reprVect',reprVect','euclidean').^2);
		end
		% to override
		function sufix = getSufix(obj)
			%%% Get string describing object parameters
		end
	end
end
