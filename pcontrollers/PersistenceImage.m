classdef PersistenceImage < PersistenceRepresentation
  %PERSISTENCEIMAGE

  properties
    resolution
    sigma
    weightingFunction
	parallel
  end
  
  methods
    function obj = PersistenceImage(resolution, sigma, ...
        weightingFunction)
      obj = obj@PersistenceRepresentation();

      obj.resolution = resolution;
      obj.sigma = sigma;
      obj.weightingFunction = weightingFunction;
	  obj.parallel = false;
    end
    
    function setup(obj)
		PI_path = which('PersistenceImage');
		[filepath, name, ext] = fileparts(PI_path);
		addpath(strcat(filepath,'/../../PersistenceImages/matlab_code'));
		%addpath('../PersistenceImages/matlab_code')
    end
    
    function repr = train(obj, diagrams, diagramLimits)
      repr = obj.test(diagrams, diagramLimits);
    end

    function repr = test(obj, diagrams, diagramLimits)
		% diagramLimitsPersist = [0, diagramLimits(2) - diagramLimits(1)];
		% Parameters for weight function
		% weightsLimits = [0, diagramLimits(2) - diagramLimits(1)];
		weightsLimits = [diagramLimits(1), diagramLimits(2) - diagramLimits(1)];
		% Lower bound for birth and upper bound for persistence. Other points will be rejected.
		diagramLimitsPersist = [diagramLimits(1), ...
			diagramLimits(2) - diagramLimits(1)];

		useold = false;
		if useold
			repr = newmake_PIs(diagrams, obj.resolution, obj.sigma, ...
				obj.weightingFunction, weightsLimits, 1);
		else
			repr = new_make_PIs(diagrams, obj.resolution, obj.sigma, ...
			obj.weightingFunction, weightsLimits, 1, ...
			diagramLimitsPersist, obj.parallel);
		end
    end
  end
end
