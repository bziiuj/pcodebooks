classdef PersistenceFV < PersistenceBow
	%%%%%%PERSISTENCEFV
	% Currently use of PersistenceBow is different from the other classes, the train method does not returns
	% a represetation of train data but prepares the PersistenceBow object, use test to get representation.
	
properties
	means
	covariances
	priors
	option
end
  
methods
	function obj = PersistenceFV(numWords, weightingFunction, option)
		obj = obj@PersistenceBow(numWords, weightingFunction);
		obj.feature_size = obj.numWords * 4;
		if nargin < 3
			obj.option = 1;
		else
			obj.option = option;
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
			sufix = ['c', num2str(obj.numWords), '_', ff, '_', num2str(obj.sampleSize),'_o',num2str(obj.option)];
		end

	function obj = fit(obj, diagrams, persistenceLimits)
		disp('Fitting Persistence FV');
		obj.persistenceLimits = persistenceLimits;

		samplePointsPersist = obj.getSample(diagrams, obj.persistenceLimits);
	
		if obj.option == 1
			v = var(samplePointsPersist)' ;
			[obj.means, obj.covariances, obj.priors] = ...
				vl_gmm(samplePointsPersist', obj.numWords, 'verbose', ...
				'Initialization', 'kmeans', ...
				'CovarianceBound', double(max(v)*0.0001), ...
				'NumRepetitions', 1);
		elseif obj.option == 2
			kdwords = vl_kmeans(samplePointsPersist', obj.numWords, ...
				'verbose', 'algorithm', 'ann') ;
			kdtree = vl_kdtreebuild(kdwords, 'numTrees', 2) ;
			[words, ~] = vl_kdtreequery(kdtree, kdwords, ...
				samplePointsPersist', ...
				'MaxComparisons', 100);

			obj.means = zeros(2, obj.numWords);
			obj.covariances = zeros(2, obj.numWords);
			obj.priors = zeros(obj.numWords, 1);
			for c = 1:obj.numWords
				samplePointsPersistC = samplePointsPersist(words == c, :);
				v = var(samplePointsPersistC)' ;
				[mean, covariance, prior] = vl_gmm(samplePointsPersistC', 1, 'verbose', ...
					'Initialization', 'kmeans', ...
					'CovarianceBound', double(max(v)*0.0001), ...
					'NumRepetitions', 1);

				obj.means(:, c) = mean;
				obj.covariances(:, c) = covariance;
				obj.priors(c) = sum(words == c) / length(words);
				if isnan(mean(1))
					obj.covariances(:, c) = [0.000001, 0.000001];
					obj.means(:, c) = samplePointsPersistC(1,:);
					obj.priors(c) = 1/length(words);
				end
			end
		end
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
