classdef PersistenceStableBow < PersistenceBow
%%%%%%PERSISTENCESTABLEBOWA

	properties
		means
		covariances
		priors
		gm
		option
	end

	methods
		function obj = PersistenceStableBow(numWords, weightingFunction, option)
			obj = obj@PersistenceBow(numWords, weightingFunction);
			obj.feature_size = obj.numWords;
			if nargin < 3
				obj.option = 1;
			else
				obj.option = option;
			end
		end
		  
		function obj = fit(obj, diagrams, persistenceLimits)
			disp('Fitting Stable Persistence BoW');
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

		function repr = predict(obj, diagrams)
			repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
				if isempty(diagrams{i})
					z = zeros(obj.numWords, 1);
				else
					x = [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)];
					z = posterior(obj.gm, x);
					z = z .* repmat(pdf(obj.gm, x), [1, size(z, 2)]);
					z = sum(z);
				end
				z = sign(z) .* sqrt(abs(z));
				z = bsxfun(@times, z, 1./max(1e-12, sqrt(sum(z .^ 2))));
				repr{i} = z;
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

			sufix = ['c', num2str(obj.numWords), '_', ff, '_', num2str(obj.sampleSize)];
		end
	end
end 

