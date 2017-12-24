classdef PersistenceRepresentation
  %PERSISTENCEREPRESENTATION

  properties
    seed
  end
  
  methods
    function obj = PersistenceRepresentation()
      obj.setup();
    end

    % to override
    function setup(obj)
    end
    
    % to override
    function repr = train(obj, diagrams)
      repr = 0;
    end

    % to override
    function repr = test(obj, diagrams)
      repr = 0;
    end

    % to override for non-vector representations
    function K = generateKernel(obj, repr)
      reprVect = repr;
      for i = 1:numel(reprVect)
        reprVect{i} = reprVect{i}(:);
      end
      reprVect = cat(2, reprVect{:});

      K = pdist2(reprVect', reprVect');
    end
  end
end
