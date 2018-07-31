classdef PersistencePdAgg < PersistenceRepresentation
  %PERSISTENCEPDAGG

  properties
	labels = {'Intervals number', 'minimum', 'maximum', 'mean', 'std', '1-quaritle', ...
		'median', '3-quartile', 'sqrt sum', 'sum', '2pow sum'};
  end
  
  methods
    function obj = PersistencePdAgg()
      obj = obj@PersistenceRepresentation();
    end
    
    function setup(obj)
    end
    
	function repr = train(obj, diagrams)
		repr = obj.test(diagrams);
	end

	function repr = test(obj, diagrams)
		repr = make_pd_agg(diagrams);
	end
  end
end
