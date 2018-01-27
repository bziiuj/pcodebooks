classdef PersistenceBow < PersistenceRepresentation
  %PERSISTENCEBOW
  
  properties
    numWords
    weightingFunction
    kdwords
    kdtree
  end
  
  methods
    function obj = PersistenceBow(numWords, weightingFunction)
      obj = obj@PersistenceRepresentation();

      obj.numWords = numWords;
      obj.weightingFunction = weightingFunction;
    end
    
    function setup(obj)
      run('../vlfeat/toolbox/vl_setup')
      addpath('../vlfeat/toolbox')
      addpath('../vlfeat/toolbox/misc')
      addpath('../vlfeat/toolbox/mex')
      if ismac
        addpath('../vlfeat/toolbox/mex/mexmaci64')
      elseif isunix
        addpath('../vlfeat/toolbox/mex/mexa64')
      end
    end

    function samplePointsPersist = getSample(obj, allPointsPersist, diagramLimitsPersist)
      if ~isempty(obj.weightingFunction)
        weights = arrayfun(@(row) ...
          obj.weightingFunction(allPointsPersist(row,:), diagramLimitsPersist), 1:size(allPointsPersist,1))';
        weights = weights / sum(weights);
        samplePointsPersist = allPointsPersist(randsample(1:size(allPointsPersist, 1), 10000, true, weights), :);
      else
        samplePointsPersist = allPointsPersist(randsample(1:size(allPointsPersist, 1), 10000), :);
      end
    end

    function repr = train(obj, diagrams, diagramLimits)
      allPoints = cat(1, diagrams{:});
      allPointsPersist = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];
      diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];

      samplePointsPersist = obj.getSample(allPointsPersist, diagramLimitsPersist);

      obj.kdwords = vl_kmeans(samplePointsPersist', obj.numWords, ...
        'verbose', 'algorithm', 'ann') ;
      obj.kdtree = vl_kdtreebuild(obj.kdwords, 'numTrees', 2) ;

      repr = obj.test(diagrams);
    end

    function repr = test(obj, diagrams)
      repr = cell(numel(diagrams), 1);
      for i = 1:numel(diagrams)
        if isempty(diagrams{i})
          z = zeros(obj.numWords, 1);
        else
          [words, ~] = vl_kdtreequery(obj.kdtree, obj.kdwords, ...
              [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)]', ...
              'MaxComparisons', 100);
          z = vl_binsum(zeros(obj.numWords, 1), 1, double(words));
          z = sign(z) .* sqrt(abs(z));
          z = bsxfun(@times, z, 1./max(1e-12, sqrt(sum(z .^ 2))));
        end
        repr{i} = z;
      end
    end
  end
end
