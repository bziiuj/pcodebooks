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
		
		function obj = fit(obj, diagrams)
			disp('Persistence Agg does not need fitting.');
		end

		function repr = predict(obj, diagrams)
			repr = make_pd_agg(diagrams);
		end
	end
end
