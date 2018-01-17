classdef PersistenceVLAD < PersistenceBow
  %PERSISTENCEVLAD
  
  properties
    means
    covariances
    priors
  end
  
  methods
    function obj = PersistenceVLAD(numWords, weightingFunction, ...
        diagramLimits)
      obj = obj@PersistenceBow(numWords, weightingFunction, ...
        diagramLimits);
    end
    
    function repr = test(obj, diagrams)
      repr = cell(numel(diagrams), 1);
      for i = 1:numel(diagrams)
        [words, ~] = vl_kdtreequery(obj.kdtree, obj.kdwords, ...
            [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)]', ...
            'MaxComparisons', 100) ;
        assign = zeros(obj.numWords, numel(words), 'single');
        assign(sub2ind(size(assign), double(words), 1:numel(words))) = 1;
        z = vl_vlad([diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)]', ...
          obj.kdwords, double(assign), ...
          'SquareRoot','NormalizeComponents');
        repr{i} = z;
      end
    end
  end
end
