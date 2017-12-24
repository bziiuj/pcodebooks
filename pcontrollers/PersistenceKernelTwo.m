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
    
    function repr = train(obj, diagrams)
      repr = obj.test(diagrams);
    end
    
    function repr = test(obj, diagrams)
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
