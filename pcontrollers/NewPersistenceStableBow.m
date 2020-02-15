classdef NewPersistenceStableBow < NewPersistenceBow
%%%%%%PERSISTENCE STABLE BOW

	properties
		means
		covariances
		priors
		gmm
		option
	end

	methods
		function obj = NewPersistenceStableBow(numWords, varargin)
			obj = obj@NewPersistenceBow(numWords, varargin{:});
		end
		  
		function obj = fit(obj, diagrams)
			disp('Fitting Stable Persistence BoW');

			k = 0;
			b = 0;
			while( k <= obj.numWords )
				[sampleBpPoints, obj] = obj.getSample(diagrams);
				obj.sample = sampleBpPoints;
				k = length(sampleBpPoints');
				b = b+1;
				if b > 9
					disp('imposibruu');
				end
			end
			
			v = var(sampleBpPoints)';

			[obj.means, obj.covariances, obj.priors] = ...
			  vl_gmm(sampleBpPoints', obj.numWords, 'verbose', ...
				  'Initialization', 'kmeans', ...
				  'CovarianceBound', double(max(v)*0.0001), ...
				  'NumRepetitions', 1); %#ok<UDIM>

			reshaped_covariances = reshape(obj.covariances, ...
				[1, size(obj.covariances, 1), size(obj.covariances, 2)]);
			zero_priors = obj.priors==0;
			obj.priors(zero_priors) = 0.1^20;
			try  
				obj.gmm = gmdistribution(obj.means', reshaped_covariances, obj.priors);
			catch
				disp(obj.means');
				disp(reshaped_covariances);
				disp(obj.priors);
				error('something is wrong with GMM');
			end
		end

		function repr = predict(obj, diagrams)
			repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
				if isempty(diagrams{i})
					z = zeros(obj.numWords, 1);
				else
					% prepare diagrams
					ndiag = obj.prepare_diagram(diagrams{i});
% 					ndiag = [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)];
% 					ndiag = ndiag - [obj.birthLimits(1), obj.persLimits(1)];
% 					ndiag = ndiag ./ obj.range;
% 					ndiag = ndiag .* obj.scale;

					z = posterior(obj.gmm, ndiag);
					z = z .* repmat(pdf(obj.gmm, ndiag), [1, size(z, 2)]);
					z = sum(z);
				end
				z = sign(z) .* sqrt(abs(z));
				z = bsxfun(@times, z, 1./max(1e-12, sqrt(sum(z .^ 2))));
				repr{i} = z;
			end
		  end

		function sufix = getSufix(obj)
			sufix = ['c', num2str(obj.numWords), '_', ...
				obj.options.samplingweight, '_', ...
				iif(obj.options.norm, 'norm', 'nonorm')	];
		end
	end
end 

