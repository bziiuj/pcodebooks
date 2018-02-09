classdef PersistencePds < PersistenceRepresentation
  %PERSISTENCEPDS
  
  properties
    resolution
    sigma
    dim
  end
  
  methods
    function obj = PersistencePds(resolution, sigma, dim)
      obj = obj@PersistenceRepresentation();

      obj.resolution = resolution;
      obj.sigma = sigma;
      obj.dim = dim;
    end
    
    function setup(obj)
      addpath('../pdsphere/matlab/');
      addpath('../pdsphere/matlab/Sphere tools/');
    end

    function repr = train(obj, diagrams, diagramLimits)
      repr = obj.test(diagrams, diagramLimits);
    end

    function repr = test(obj, diagrams, diagramLimits)
      stepVal = (diagramLimits(2) - diagramLimits(1)) / obj.resolution;
      params.x1 = diagramLimits(1):stepVal:diagramLimits(2);
      params.x2 = params.x1;
      params.sig = obj.sigma;

      htMap = newHeatMapfromPD(diagrams, params);
      phi = hmap2sphere(htMap);
      repr = Sphere_PGA(phi, obj.dim);
    end
  end
end
