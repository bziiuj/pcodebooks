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
			end

			diagram_distance = '../persistence-learning/code/dipha-pss/build/diagram_distance';
			
			outDir = ['temp_',run_id]; 
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
%			gram_matrix_file_wIFGT = fullfile(outDir, ...
%				  sprintf('Gramm_matrix'));
%			time_file = fullfile(outDir, ...
%				  sprintf('duration'));

			gram_matrix_file_wIFGT = ['K_wIFGT_', run_id, '.txt'];

			options = ['--time ', num2str(obj.sigma), ...
				  ' --dim ', num2str(dim) ' '];
			exec = [diagram_distance ' ' options file_list ' > ' gram_matrix_file_wIFGT];
			system(exec);

			K = load(gram_matrix_file_wIFGT);
			K = dlmread(gram_matrix_file_wIFGT, ' ', 1, 0);
			K = K(:,1:end-1);
%			K = load(gram_matrix_file_wIFGT);
%			K = dlmread(gram_matrix_file_wIFGT, ' ');
%			K = K(:,1:end-1);

			time = dlmread(time_file, ' ', [0 0 0 0]); 

			cleanup = ['rm ', gram_matrix_file_wIFGT, ' ', file_list];
			system(cleanup);

%			disp('Saving command');
%			fid_run = fopen(fullfile(outDir, 'mk_run.sh'), 'a');
%
%			fprintf(fid_run, 'touch %s\n', gram_matrix_file_wIFGT);
%			fprintf(fid_run, '%s', exec);
%			fclose(fid_run)

		end
	end
end
