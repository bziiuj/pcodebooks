classdef PersistenceStableBow < PersistenceBow
%%%%%%PERSISTENCESTABLEBOWA

	properties
	  means
	  covariances
	  priors
	  gm
	end

	methods
	  function obj = PersistenceStableBow(numWords, weightingFunction)
		obj = obj@PersistenceBow(numWords, weightingFunction);
		obj.feature_size = obj.numWords;
	  end
	  
	  function obj = train(obj, diagrams, diagramLimits)
		allPoints = cat(1, diagrams{:});
		allPointsPersist = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];
		diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];

		samplePointsPersist = obj.getSample(allPointsPersist, diagramLimitsPersist);

		v = var(samplePointsPersist)' ;
		[obj.means, obj.covariances, obj.priors] = ...
		  vl_gmm(samplePointsPersist', obj.numWords, 'verbose', ...
			  'Initialization', 'kmeans', ...
			  'CovarianceBound', double(max(v)*0.0001), ...
			  'NumRepetitions', 1);

		reshaped_covariances = reshape(obj.covariances, ...
		  [1, size(obj.covariances, 1), size(obj.covariances, 2)]);
		zero_priors = [obj.priors==0];
		obj.priors(zero_priors) = 0.1^20;
		try  
			obj.gm = gmdistribution(obj.means', reshaped_covariances, obj.priors);
		catch
			disp(obj.means');
			disp(reshaped_covariances);
			disp(obj.priors);
		end
	end

	function repr = test(obj, diagrams)
		repr = cell(numel(diagrams), 1);
		for i = 1:numel(diagrams)
			if isempty(diagrams{i})
				z = zeros(obj.numWords, 1);
			else
				x = [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)];
				z = posterior(obj.gm, x);
				z = sum(z);
			end
			z = sign(z) .* sqrt(abs(z));
			z = bsxfun(@times, z, 1./max(1e-12, sqrt(sum(z .^ 2))));
			repr{i} = z;
		end
	  end
	end
end
