classdef PersistenceKernelOne < PersistenceRepresentation
	%PERSISTENCEKERNELONE
	  
	properties
		sigma
	end
	  
	methods
		function obj = PersistenceKernelOne(sigma)
			obj = obj@PersistenceRepresentation();

			obj.sigma = sigma;
		end

		function sufix = getSufix(obj)
			sufix = ['s', num2str(obj.sigma)];
		end

		function setup(obj)
			addpath('../persistence-learning/code/matlab/');
			pl_setup();
		end

		function obj = fit(obj, diagrams)
			disp('PersistenceKernelOne does not need fitting.');
		end

		function repr = predict(obj, diagrams)
			repr = diagrams;
		end

		function [K, time] = generateKernel(obj, repr, run_id)
			dim = 1; % TODO: does it matter?

			if nargin < 3
				run_id = '';
			else
				run_id = ['_', run_id];
			end

			diagram_distance = '../persistence-learning/code/dipha-pss/build/diagram_distance';
			
			outDir = ['temp',run_id]; 
			if exist(outDir)
				rmdir(outDir, 's');
			end
			mkdir(outDir);

			file_list = '';
			% Number of diagrams to create
			for i=1:numel(repr)
				data = [ones(size(repr{i}, 1), 1) * dim, repr{i}];

				outFile = sprintf('pd_%d', i);
				outFile = fullfile(outDir, outFile);
				pl_write_persistence_diagram(outFile, 'dipha', data);
				file_list = [file_list, ' ', outFile, '.bin'];
			end

			% GRAM matrix
			gram_matrix_file_wIFGT = fullfile(outDir, ...
				  sprintf('K_wIFGT.txt'));

			options = ['--time ', num2str(obj.sigma), ...
				  ' --dim ', num2str(dim) ' '];
			exec = [diagram_distance ' ' options file_list ' > ' gram_matrix_file_wIFGT];
			system(exec);

			K = dlmread(gram_matrix_file_wIFGT, ' ', 1, 0);
			K = K(:,1:end-1);
			time = dlmread(gram_matrix_file_wIFGT, ' ', [0 2 0 2]); 

			cleanup = ['rm -rf ', outDir];
			system(cleanup);
		end
	end
end
