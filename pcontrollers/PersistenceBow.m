classdef PersistenceBow < PersistenceRepresentation
%%%%% PERSISTENCEBOW

	properties
		numWords
		weightingFunction
		persistenceLimits
		weightingFunctionPredict
		sampleSize
		kdwords
		kdtree
	end
 
	methods
		function obj = PersistenceBow(numWords, weightingFunctionFit, weightingFunctionPredict, sampleSize)
			obj = obj@PersistenceRepresentation();

			obj.numWords = numWords;
			obj.weightingFunction = weightingFunctionFit;
			if nargin >= 3
				obj.weightingFunctionPredict = weightingFunctionPredict;
	%		else
	%			obj.weightingFunctionPredict = @constant_one;
			end

			if nargin < 4
				obj.sampleSize = 10000;
			else
				obj.sampleSize = sampleSize;
			end
			obj.feature_size = obj.numWords;
		end

		function sufix = getSufix(obj)
			if strcmp(func2str(obj.weightingFunction), 'constant_one')
				ff = '_const';
			elseif strcmp(func2str(obj.weightingFunction), 'linear_ramp')
				ff = '_lin';
			else
				error('unknown weightning function');
			end
			if ~isempty(obj.weightingFunctionPredict)
				if strcmp(func2str(obj.weightingFunctionPredict), 'constant_one')
					pf = '_const';
				elseif strcmp(func2str(obj.weightingFunctionPredict), 'linear_ramp')
					pf = '_lin';
				else
					error('unknown weightning function');
				end
			else
				pf = '';
			end
			sufix = ['c', num2str(obj.numWords), ff, pf,'_', num2str(obj.sampleSize)];
		end

		function setup(obj)
			pbow_path = which('PersistenceBow');
			[filepath, ~, ~] = fileparts(pbow_path);
			run(strcat(filepath,'/../../vlfeat/toolbox/vl_setup'))
			addpath(strcat(filepath,'/../../vlfeat/toolbox'))
			addpath(strcat(filepath,'/../../vlfeat/toolbox/misc'))
			addpath(strcat(filepath,'/../../vlfeat/toolbox/mex'))
			if ismac
			  addpath(strcat(filepath,'/../../vlfeat/toolbox/mex/mexmaci64'))
			elseif isunix
			  addpath(strcat(filepath,'/../../vlfeat/toolbox/mex/mexa64'))
			end
		end

		function samplePointsPersist = getSample(obj, diagrams, persistenceLimits)
			allPoints = cat(1, diagrams{:});
			allBPpoints = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];

			if length(allPoints) > obj.sampleSize
				sample = obj.sampleSize;
			else
				sample = length(allPoints);
			end

			if ~strcmp(func2str(obj.weightingFunction), 'constant_one')
				weights = arrayfun(@(row) ...
				  obj.weightingFunction(allBPpoints(row,:), persistenceLimits), 1:size(allBPpoints,1))';
				weights = weights / sum(weights);
				samplePointsPersist = allBPpoints(randsample(1:size(allBPpoints, 1), sample, true, weights), :);
			else
				samplePointsPersist = allBPpoints(randsample(1:size(allBPpoints, 1), sample), :);
			end
		end

		function obj = fit(obj, diagrams, persistenceLimits)
			disp('Fitting Persistence BoW');
			obj.persistenceLimits = persistenceLimits;

			sampleBpPoints = obj.getSample(diagrams, obj.persistenceLimits);

			obj.kdwords = vl_kmeans(sampleBpPoints', obj.numWords, ...
			  'verbose', 'algorithm', 'ann') ;
			obj.kdtree = vl_kdtreebuild(obj.kdwords, 'numTrees', 2) ;
		end

		function repr = predict(obj, diagrams)
			repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
				if isempty(diagrams{i})
					z = zeros(obj.numWords, 1); 
				else
					bppoints = [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)];
					[words, ~] = vl_kdtreequery(obj.kdtree, obj.kdwords, ...
						bppoints', ...
						'MaxComparisons', 100);
					% count words using weights or not
					if ~isempty(obj.weightingFunctionPredict) ...
						&& ~strcmp(func2str(obj.weightingFunctionPredict), 'constant_one')
% 					if ~isempty(obj.weightingFunctionPredict)
						z = zeros(obj.numWords, 1);
						weights = obj.weightingFunctionPredict(bppoints, obj.persistenceLimits);
						for x = 1:length(words)
							z(words(x)) = z(words(x)) + weights(x);
						end
					else
						z = vl_binsum(zeros(obj.numWords, 1), 1, double(words));
					end
					% normalize codebook
					z = sign(z) .* sqrt(abs(z));
					z = bsxfun(@times, z, 1./max(1e-12, sqrt(sum(z .^ 2))));
				end
				repr{i} = z;
			end
		end

		function pbow = saveobj(obj)
			pbow.numWords = obj.numWords;
			pbow.weightingFunction = obj.weightingFunction;
			pbow.sampleSize = obj.sampleSize;
			pbow.kdwords = obj.kdwords;
			pbow.kdtree = obj.kdtree;
		end
	end %methods
 
	methods (Static)

		function obj = loadobj(pbow)
			obj = PersistenceBow(pbow.numWords, pbow.weightingFunction, pbow.sampleSize);
			obj.kdwords = pbow.kdwords;
			obj.kdtree = pbow.kdtree;
		end

	end %methods (Static)
end %classdef
