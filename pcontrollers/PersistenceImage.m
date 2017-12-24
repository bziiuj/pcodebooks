classdef PersistenceImage < PersistenceRepresentation
  %PERSISTENCEIMAGE

  properties
    resolution
    sigma
    weightingFunction
    diagramLimits
  end
  
  methods
    function obj = PersistenceImage(resolution, sigma, ...
        weightingFunction, diagramLimits)
      obj = obj@PersistenceRepresentation();

      obj.resolution = resolution;
      obj.sigma = sigma;
      obj.weightingFunction = weightingFunction;
      obj.diagramLimits = diagramLimits;
    end
    
    function setup(obj)
      addpath('../PersistenceImages/matlab_code')
    end
    
    function repr = train(obj, diagrams)
      repr = obj.test(diagrams);
    end

    function repr = test(obj, diagrams)
      repr = make_PIs(diagrams, obj.resolution, obj.sigma, ...
        obj.weightingFunction, obj.diagramLimits);
    end
  end
end
