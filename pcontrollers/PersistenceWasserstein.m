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

		function sufix = getSufix(obj)
			sufix = '';
		end

		function obj = fit(obj, diagrams)
			disp('PersistenceWasserstein does not need fitting.');
		end

		function repr = predict(obj, diagrams)
			disp('Wasserstein matrix should be computed externally');
			repr = [0];
		end

		function K = generateKernel(obj, repr)
		end
	end
end

