classdef PersistenceFV < PersistenceBow
%%%%%%PERSISTENCEFV
% Currently use of PersistenceBow is different from the other classes, the train method does not returns 
% a represetation of train data but prepares the PersistenceBow object, use test to get representation.
  
	properties
		means
		covariances
		priors
	end
 
	methods
		function obj = PersistenceFV(numWords, weightingFunction)
			obj = obj@PersistenceBow(numWords, weightingFunction);
			obj.feature_size = obj.numWords * 4;
		end
    
	function sufix = getSufix(obj)
		if strcmp(func2str(obj.weightingFunction), 'constant_one')
			ff = 'const';
		elseif strcmp(func2str(obj.weightingFunction), 'linear_ramp')
			ff = 'lin';
		else
			error('unknown weightning function');
		end
		sufix = ['c', num2str(obj.numWords), '_', ff, '_', num2str(obj.sampleSize)];
	end

	function obj = fit(obj, diagrams, diagramLimits)
		disp('Fitting Persistence FV');
		allPoints = cat(1, diagrams{:});
		allPointsPersist = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];
%		diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];
		diagramLimitsPersist = diagramLimits;

		samplePointsPersist = obj.getSample(allPointsPersist, diagramLimitsPersist);

		v = var(samplePointsPersist)' ;
		[obj.means, obj.covariances, obj.priors] = ...
			vl_gmm(samplePointsPersist', obj.numWords, 'verbose', ...
				'Initialization', 'kmeans', ...
				'CovarianceBound', double(max(v)*0.0001), ...
				'NumRepetitions', 1);
		end

		function repr = predict(obj, diagrams)
			repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
				if isempty(diagrams{i})
					z = zeros(2 * size(obj.means, 1) * size(obj.means, 2), 1);
				else
					z = vl_fisher([diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)]', ...
					obj.means, ...
					obj.covariances, ...
					obj.priors, ...
					'Improved') ;
				end
				repr{i} = z;
			end
		end
	end
end
