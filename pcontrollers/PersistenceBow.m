classdef PersistenceBow < PersistenceRepresentation
%%%%% PERSISTENCEBOW

  properties
	numWords
	weightingFunction
	diagramLimits
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
    
    function setup(obj)
		pbow_path = which('PersistenceBow');
		[filepath, name, ext] = fileparts(pbow_path);
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

	function samplePointsPersist = getSample(obj, allPointsPersist, diagramLimitsPersist)
		if ~isempty(obj.weightingFunction)
			weights = arrayfun(@(row) ...
			  obj.weightingFunction(allPointsPersist(row,:), diagramLimitsPersist), 1:size(allPointsPersist,1))';
			weights = weights / sum(weights);
			samplePointsPersist = allPointsPersist(randsample(1:size(allPointsPersist, 1), obj.sampleSize, true, weights), :);
		else
			samplePointsPersist = allPointsPersist(randsample(1:size(allPointsPersist, 1), obj.sampleSize), :);
		end
	end
	
	function obj = fit(obj, diagrams, diagramLimits)
		allPoints = cat(1, diagrams{:});
		allPointsPersist = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];
		diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];
		obj.diagramLimits = diagramLimitsPersist;
		
		samplePointsPersist = obj.getSample(allPointsPersist, diagramLimitsPersist);
		
		obj.kdwords = vl_kmeans(samplePointsPersist', obj.numWords, ...
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
				if ~isempty(obj.weightingFunctionPredict)
					z = zeros(obj.numWords, 1);
					weights = obj.weightingFunctionPredict(bppoints, obj.diagramLimits);
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
