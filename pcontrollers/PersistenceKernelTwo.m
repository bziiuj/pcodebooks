classdef PersistenceKernelTwo < PersistenceRepresentation
  %PERSISTENCEKERNELTWO
  
  properties
    exact
    n
  end
  
  methods
    function obj = PersistenceKernelTwo(exact, n)
      obj = obj@PersistenceRepresentation();

      obj.exact = exact;
      if exact
        obj.n = -1;
      else
        obj.n = n;
      end
    end
    
    function setup(obj)
      addpath('pkerneltwo')
    end
    
    function obj = fit(obj, diagrams)
		disp('PersistenceKernelTwo does not need fitting.');
    end
    
    function repr = predict(obj, diagrams)
		repr = diagrams;
    end

    function K = generateKernel(obj, repr)
      if obj.exact
        K = secondKernel(repr', obj.exact, -1);
      else
        K = secondKernel(repr(:)', obj.exact, obj.n);
      end
    end
  end
end
