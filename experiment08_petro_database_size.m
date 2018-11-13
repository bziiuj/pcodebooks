% petrogllyphs experiment
function experiment08_petro_dataset_size(test_type, algorithm, subset)
%%%	ARGS:
%		test_type:	0-kernels, 1-vectors, 2-codebooks, 3-stable codebooks
%		algorithm:	0-'linearSVM-kernel', 1-'linearSVM-vector'
%		initialize parallel pool (it is convinient to have a lot of workers while computing PI on a grid)
%		experiment using subset of data (true) or full dataset (false)
	switch algorithm
	case 0
		algorithm = 'linearSVM-kernel'; 
	case 1
		algorithm = 'linearSVM-vector';
	end
%	par = 0;
%	if nargin >= 3
%		par = init_parallel;
%	end

	if nargin < 4
		sample = 300;
	else
		sample = subset;
	end

	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	dataPath = 'exp04_petroglyphs/';
	expPath = 'exp08_petro_dataset_size/';
	mkdir(expPath);

%	parallel_pi = true; 

	sufix = strcat('s', num2str(sample));
	basename = strcat('pds_petroglyphs_', sufix);
	
	nclasses = 2;

	types = {'no_engravement', 'engravement'};
	
	%%%%% EXPERIMENT PARAMETERS
	% Number of trials
	N = 20;
	% PI tested resolutions and relative sigmas
	pi_r = [5, 10:10:100];%, 170:30:200];
	pi_s = [0.1, 0.25, 0.5, 1, 1.5, 2];
	% tested codebook sizes
%	bow_sizes = 150:20:210;
%	bow_sizes = [5, 10:10:100]; %, 75, 100];%, 180:30:210];
%	bow_sizes = [10:10:50];
	bow_sizes = [50];
	sample_sizes = [10000];

	num_of_pds = 1000:1000:10000;
	objs = {};
	switch test_type
	%%% PERSISTENCE CODEBOOKS
	case 2
		disp('Creating codebooks objects');
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceBow(c, @linear_ramp, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceBow(c, @constant_one, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
	%%% STABLE PERSISTENCE CODEBOOKS
	case 3
		disp('Creating stable codebooks objects');
		for c = bow_sizes
			objs{end + 1} = {PersistenceStableBow(c, @linear_ramp), {'pbow_st', ['pbow_st_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceStableBow(c, @constant_one), {'pbow_st', ['pbow_st_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceSoftVLAD(c, @linear_ramp), {'svlad', ['svlad_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceSoftVLAD(c, @constant_one), {'svlad', ['svlad_', num2str(c)]}};
		end
	end
	%%%
	disp('Descriptor objects created. Testing');

	for o = 1:numel(objs)
		obj = objs{o}{1};
		prop = objs{o}{2};

		fid_summary = fopen([expPath, 'results_', sufix, ...
				algorithm, '_', prop{1}, '.txt'], 'a');
		header = [prop{1}, ';sample;fit_time;predict_time;svm_time;std;acc;', types{1}, ';', types{2}];
		fprintf(fid_summary, '%s\n', header);
		fclose(fid_summary);
 
		for p = num_of_pds
			acc = zeros(N, nclasses + 1);
			all_times = zeros(N, 3);
			for i = 1:N
				[pds, train_surfs, diagramLimits] = load_data_nth_rep(i, dataPath, basename, sample);
				% all pds in flat cell array
				flat_pds = cell(26*sample*2, 1); 
				% all labels in flat array
				flat_labels = zeros(26*sample*2, 1);
				for s = 1:26
					l = sample*2*(s-1)+1;
					r = l + sample*2-1;
					flat_pds(l:r) = [pds{s}(:,1), pds{s}(:,2)];
					flat_labels(l:r) = [zeros(sample, 1); ones(sample, 1)];
				end

				rsample = randsample(length(flat_labels), p);
				flat_pds = flat_pds(rsample);
				flat_labels = flat_labels(rsample);

				seedBig = i * 10103;
				rng(seedBig);
				fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
				
				[accuracy, preciseAccuracy, confusion_matrix, times, obj] = ...
					compute_accuracy_petroglyphs(obj, flat_pds, ...
					flat_labels, train_surfs, sample, diagramLimits, algorithm, ...
					prop{1}, strcat(basename, '_', 'rep', num2str(i), '_', prop{2}), ...
					expPath, seedBig);
				acc(i, :) = [accuracy, preciseAccuracy]';
				conf_matrices(i, :, :) = confusion_matrix;
				all_times(i, :) = times;
			end

			avg_conf_mat = squeeze(sum(conf_matrices, 1));
			fprintf('Saving results for: %s\n', prop{2});
	%		print_results(expPath, obj, N, algorithm, sufix, types, prop, all_times, acc, avg_conf_mat);

			fid_summary = fopen([expPath, 'results_', sufix, ...
					algorithm, '_', prop{1}, '.txt'], 'a');
			f = functions(obj.weightingFunction);
			if isempty(obj.weightingFunctionPredict)
				% numWords;sampleSize;weightingFunctionFit;weightingFunctionPredict
				specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function];
			else
				fp = functions(obj.weightingFunctionPredict);
				% numWords;sampleSize;weightingFunction
				specs = [num2str(obj.numWords), ';', num2str(obj.sampleSize), ';', f.function, ';', fp.function];
			end

			basicLine = sprintf(['%s;%f;%f;%f;%f;%f;%f', repmat(';%f', [1, length(types)])], ...
				prop{1}, p, mean(times(:,1)), mean(times(:,2)), mean(times(:,3)), std(acc(:,1)), mean(acc));

			fprintf(fid_summary, '%s;%s\n', basicLine, specs);
			fclose(fid_summary);
		end
	end
end

function [accuracy, preciseAccuracy, confusion_matrix, times, obj] = compute_accuracy_petroglyphs(...
		obj, flat_pds, flat_labels, train_surfs, sample, diagramLimits, ...
		algorithm, name, detailName, expPath, seed)
  %%% OUTPUT:
  %     accuracy - overall accuracy
  %     preciseAccuracy - accuracy for every class
  %     times - cell array {descriptor creation time, kernel creation time}
  %     obj   - 
	times = [-1, -1, -1];

	switch name
	case {'pw'}
		kernelPath = [expPath, detailName, '.mat'];
		disp(kernelPath);
		if ~exist(kernelPath, 'file')
		    throw(MException('Error', 'Wasserstein distance is currently not implemented'));
		else
		    load(kernelPath);
		    K = double(K);
		end
	case {'pk1', 'pk2e', 'pk2a', 'pl'}
		kernelPath = [expPath, detailName, '.mat'];
		if ~exist(kernelPath, 'file')
			tic;
			repr = obj.predict(flat_pds);
		
			K = obj.generateKernel(repr);
			times(2) = toc;
			save(kernelPath, 'K', 'times');
		else
			load(kernelPath);
		end
		% K is uppertriangular, so ...
		K = K + K';
	case {'pi', 'pbow', 'pvlad', 'pfv', 'pbow_st', 'svlad'}
		tic;
		if strcmp(name, 'pi') %|| strcmp(name, 'pds')
			reprCell = obj.predict(flat_pds, diagramLimits);
		else
			obj = obj.fit(flat_pds, diagramLimits);
			times(1) = toc;
			tic
			reprCell = obj.predict(flat_pds);
			times(2) = toc;
		end

		switch algorithm 
		case 'linearSVM-kernel'
			tic;
			K = obj.generateKernel(reprCell);
			times(2) = toc;
		case 'linearSVM-vector'
			features = zeros(obj.feature_size, length(reprCell));
			for i = 1:length(reprCell)
				features(:, i) = reprCell{i}(:)';
			end
		end
	case {'pds'}
		tic;
		% compute diagram limits
		features = obj.predict(flat_pds, diagramLimits);
		times(1) = toc;
		% this is hack - modify it in the future, so that all representations
		% return the same thing
		reprNonCell = cell(1, size(features,2));
		for i = 1:size(features, 2)
		  reprNonCell{i} = features(:, i);
		end
		if strcmp(algorithm, 'linearSVM-kernel')
			tic;
			K = obj.generateKernel(reprNonCell);
			times(2) = toc;
		end
	end

	all_idx = 1:length(flat_labels);
	tic
	switch algorithm
		case 'linearSVM-kernel'
		  [accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(1-K, flat_labels+1, tridx, teidx, ...
		        'kernel');
		case 'linearSVM-vector'
			[accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(...
				features, flat_labels+1, all_idx, all_idx, 'vector');
		otherwise
			error('Only vectorSVM can be used for this experiment');
	end
	times(3) = toc;
end

function [pds, train_surfs, diagramLimits] = load_data_nth_rep(n, path, basename, sample)
	% data is a cell array 26x1
	% each cell contains cell array samplex2
	% first column contains PDs not clasified as a picture
	% second column contains PDs clasified as a picture
	load([path, basename, '_rep', num2str(n),'.mat'], 'pds');

	rng(n)
	train_surfs = sort(randsample(26,13))';
	%%%%% COMPUTE DIAGRAM LIMITS
	disp(strcat('Computing limits'));
	diagramLimits = [0, 0];
	dmax = max(pds{train_surfs(1)}{1,1}(:,2));
	dmin = min(pds{train_surfs(1)}{1,1}(:,1));
	dmaxs = [];
	dmins = [];
	for s = train_surfs
		for i = 1:sample
			for j = 1:2
				dmin = min(dmin, min(pds{s}{i,j}(:,1)));
				dmax = max(dmax, max(pds{s}{i,j}(:,2)));
				dmins = [dmins, min(pds{s}{i,j}(:,1))];
				dmaxs = [dmaxs, max(pds{s}{i,j}(:,2))];
			end
		end
	end
	diagramLimits = [dmin, dmax];
	disp(strcat('MinMax diagram values: ', num2str(diagramLimits)));
	diagramLimits = [quantile(dmins, 0.01), quantile(dmaxs, 0.99)];
	disp(strcat('Diagram limits: ', num2str(diagramLimits)));
end
