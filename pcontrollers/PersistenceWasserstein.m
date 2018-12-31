classdef PersistenceWasserstein < PersistenceRepresentation
	%PERSISTENCEDIAGRAM

	properties
	end

	methods
		function obj = PersistenceWasserstein()
			obj = obj@PersistenceRepresentation();
			disp('2-Wasserstein');
		end

		function setup(obj)
			addpath('wasserstein_hera/build/');
		end

		function sufix = getSufix(obj)
			sufix = '';
		end

		function obj = fit(obj, diagrams)
			disp('PersistenceWasserstein does not need fitting.');
		end

		function repr = predict(obj, diagrams)
			repr = diagrams;
		end

%		function K = generateKernel(obj, repr)
		function [K, time] = generateKernel(obj, repr, run_id)
			if nargin < 3
				run_id = '';
			else
				run_id = ['_', run_id];
			end

			wass_matrix_exec = 'wasserstein_hera/build/wasserstein_dist_hacked';

			outDir = ['temp', run_id]; 
			if exist(outDir)
				rmdir(outDir, 's');
			end
			mkdir(outDir);

			file_list = '';
			% Number of diagrams to create
			for i=1:numel(repr)
				diag_size = size(repr{i}, 1);
				data = [ones(diag_size, 1), repr{i}];

				outFile = sprintf('pd_%d', i);
				outFile = fullfile(outDir, outFile);
				dlmwrite(outFile, data, 'delimiter', ' ');
				% pl_write_persistence_diagram(outFile, 'dipha', data);
				file_list = [file_list, ' ', outFile];
			end

			% wasserstein distance matrix
			wass_mat_file = ['result'];
			time_file = ['duration'];

% 			gram_matrix_file_wIFGT = ['K_wIFGT_', run_id, '.txt'];

			command = [wass_matrix_exec, ' ', file_list];
			system(command);

			K = dlmread(wass_mat_file, ' ');
			K = K(:, 1:end-1);
			time = dlmread(time_file, ' ', [0 0 0 0]); 

			cleanup = ['rm ', wass_mat_file, ' ', time_file];
			system(cleanup);
			cleanup = ['rm -rf ', outDir];
			system(cleanup);

%			disp('Saving command');
%			fid_run = fopen(fullfile(outDir, 'mk_run.sh'), 'a');
		end
	end
end

