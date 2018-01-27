classdef PersistenceFV < PersistenceBow
  %PERSISTENCEFV
  
  properties
    means
    covariances
    priors
  end
  
  methods
    function obj = PersistenceFV(numWords, weightingFunction)
      obj = obj@PersistenceBow(numWords, weightingFunction);
    end
    
    function repr = train(obj, diagrams, diagramLimits)
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

      repr = obj.test(diagrams);
    end

    function repr = test(obj, diagrams)
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
