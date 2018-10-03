classdef PersistenceLandscape < PersistenceRepresentation
  %PERSISTENCELANDSCAPE

  properties
  end
  
  methods
    function obj = PersistenceLandscape()
      obj = obj@PersistenceRepresentation();
    end
    
    function setup(obj)
      addpath('../Persistent-Landscape-Wrapper/cpp');
      addpath('../Persistent-Landscape-Wrapper/lib');
    end
    
    function obj = fit(obj, diagrams)
		disp('Persistence Landscape does not need fitting.');
    end
    
    function repr = predict(obj, diagrams)
      repr = cell(1, numel(diagrams));
      for i = 1:numel(diagrams)
        repr{i} = barcodeToLandscape(diagrams{i});
      end
    end

    function K = generateKernel(obj, repr)
      K = zeros(length(repr));
      for i = 1:length(repr)
		  disp(strcat(num2str(i),'/',num2str(length(repr))));
        for j = 1:length(repr)
          K(i, j) = landscapeDistance(repr{i}, repr{j}, 2);
        end
      end
    end
  end
end
