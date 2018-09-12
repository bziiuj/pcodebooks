classdef PersistenceWasserstein < PersistenceRepresentation
  %PERSISTENCEDIAGRAM

  properties
  	q
  end
  
  methods
	function obj = PersistenceWasserstein(q)
		obj = obj@PersistenceRepresentation();
		if nargin < 1
			obj.q = 2;
		else
			obj.q = q;
		end
		disp(strcat('Wasserstein q: ', num2str(obj.q)));
    end

    function setup(obj)
    end

    function [obj, repr] = train(obj, diagrams)
      repr = obj.test(diagrams);
    end
    
    function repr = test(obj, diagrams)
      repr = diagrams;
    end

    function K = generateKernel(obj, repr)
	end
  end
  
end

