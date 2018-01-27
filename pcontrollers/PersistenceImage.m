classdef PersistenceImage < PersistenceRepresentation
  %PERSISTENCEIMAGE

  properties
    resolution
    sigma
    weightingFunction
  end
  
  methods
    function obj = PersistenceImage(resolution, sigma, ...
        weightingFunction)
      obj = obj@PersistenceRepresentation();

      obj.resolution = resolution;
      obj.sigma = sigma;
      obj.weightingFunction = weightingFunction;
    end
    
    function setup(obj)
      addpath('../PersistenceImages/matlab_code')
    end
    
    function repr = train(obj, diagrams, diagramLimits)
      repr = obj.test(diagrams, diagramLimits);
    end

    function repr = test(obj, diagrams, diagramLimits)
      diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];

      repr = newmake_PIs(diagrams, obj.resolution, obj.sigma, ...
        obj.weightingFunction, diagramLimitsPersist);
    end
  end
end
