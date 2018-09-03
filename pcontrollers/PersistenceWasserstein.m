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
		pbow_path = which('PersistenceWasserstein');
		[filepath, name, ext] = fileparts(pbow_path);
		addpath(strcat(filepath,'/../wasserstein'))
    end

    function [obj, repr] = train(obj, diagrams)
      repr = obj.test(diagrams);
    end
    
    function repr = test(obj, diagrams)
      repr = diagrams;
    end

    function K = generateKernel(obj, repr)
		n = length(repr);
		K = zeros(n);
		for i = 1:n
			disp(strcat(num2str(i),'/',num2str(n)));
			for j = i+1:n
				K(i,j) = pd_wasserstein(repr{i}, repr{j}, obj.q);
				K(j,i) = K(i, j);
			end
		end
	end
  end
  
end

