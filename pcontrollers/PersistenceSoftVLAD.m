classdef PersistenceSoftVLAD < PersistenceBow
%PERSISTENCESOFTVLAD
	properties
		means
		covariances
		priors
		gm
	end

	methods
		function obj = PersistenceSoftVLAD(numWords, weightingFunction)
			obj = obj@PersistenceBow(numWords, weightingFunction);
			obj.feature_size = obj.numWords * 2;
		end

		function obj = fit(obj, diagrams, persistenceLimits)
			obj.persistenceLimits = persistenceLimits;
			samplePointsPersist = obj.getSample(diagrams, obj.persistenceLimits);

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

		function repr = predict(obj, diagrams)
			repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
				if isempty(diagrams{i})
					z = zeros(obj.feature_size, 1);
				else
					x = [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)];
					assign = posterior(obj.gm, x)';
					z = vl_vlad(x', obj.means, double(assign), ...
						'SquareRoot','NormalizeComponents');
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
