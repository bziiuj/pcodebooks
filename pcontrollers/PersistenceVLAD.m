classdef PersistenceVLAD < PersistenceBow
  %PERSISTENCEVLAD
  
  properties
  end
  
  methods
    function obj = PersistenceVLAD(numWords, weightingFunction)
      obj = obj@PersistenceBow(numWords, weightingFunction);
      obj.feature_size = obj.numWords * 2;
    end
    
    function repr = test(obj, diagrams)
      repr = cell(numel(diagrams), 1);
      for i = 1:numel(diagrams)
        if isempty(diagrams{i})
          z = zeros(size(obj.kdwords, 1) * size(obj.kdwords, 2), 1);
        else
          [words, ~] = vl_kdtreequery(obj.kdtree, obj.kdwords, ...
              [diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)]', ...
              'MaxComparisons', 100) ;
          assign = zeros(obj.numWords, numel(words), 'single');
          assign(sub2ind(size(assign), double(words), 1:numel(words))) = 1;
          z = vl_vlad([diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)]', ...
            obj.kdwords, double(assign), ...
            'SquareRoot','NormalizeComponents');
        end
        repr{i} = z;
      end
    end
  end
end
