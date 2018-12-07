% petrogllyphs experiment
function experiment04_petroglyphs(test_type, algorithm, init_parallel, subset)
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
	par = 0;
	if nargin >= 3
		par = init_parallel;
	end

	if subset
		sample = 10;
	else
		sample = 300;
	end

	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	expPath = 'exp04_petroglyphs/';
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));

	parallel_pi = true; 

	sufix = strcat('s', num2str(sample));
	basename = strcat('pds_petroglyphs_', sufix);
	
	nclasses = 2;

	types = {'no_engravement', 'engravement'};
	
	%%%%% EXPERIMENT PARAMETERS
	% Number of trials
	N = 10;
	% PI tested resolutions and relative sigmas
	pi_r = 10:10:100;%, 170:30:200];
	pi_s = [0.5, 1, 2, 3];
	% tested codebook sizes
%	bow_sizes = 150:20:210;
	bow_sizes = [10, 20:20:200]; %, 75, 100];%, 180:30:210];
	bow_sizes = [50];
	sample_sizes = [10000];

	objs = {};
	switch test_type
	%%% KERNEL APPROACHES
	case 0
		disp('Creating kernel descriptor objects');
		objs{end + 1} = {PersistenceWasserstein(), {'pw', 'pw'}};
		objs{end + 1} = {PersistenceKernelOne(2.0), {'pk1', ['pk1_', num2str(2.0)]}};
		for c = [0.5, 1., 1.5, 2.0, 3.0]
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', ['pk1_', num2str(c)]}};
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', 'pk1'}};
		end
		for a = 50:50:250
		  objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
		end
		objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};

	%%% OTHER VECTORIZED APPROACHES
	case 1
		disp('Creating vectorized descriptor objects');
		for r = pi_r
			for s = pi_s
				objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
				objs{end}{1}.parallel = true;
			end
		end
		for r = pi_r
			for s = pi_s
				objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
				objs{end}{1}.parallel = true;
			end
		end
		for r = [10, 20, 40, 60]
			for s = 0.1:0.1:0.3
				for d = 25:25:100
					objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), ...
						'_', num2str(s), '_', num2str(d)]}};
				end
			end
		end

	%%% PERSISTENCE CODEBOOKS
	case 2 
		for sample_size = sample_sizes
			disp(['Creating PBOW objects.', ' Sample size: ', num2str(sample_size)]);
			for c = bow_sizes
				objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceBow(c, @constant_one, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceBow(c, @linear_ramp, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
		end
	%%% PERSISTENCE CODEBOOKS PVLAD + PFV
	case 4
		for sample_size = sample_sizes
			disp(['Creating PLVAD and PFV objects.', ' Sample size: ', num2str(sample_size)]);
			for c = bow_sizes
				objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
		end

	%%% STABLE PERSISTENCE CODEBOOKS
	case 3
		for sample_size = sample_sizes
			disp(['Creating stable codebooks objects.', ' Sample size: ', num2str(sample_size)]);
			for c = bow_sizes
				objs{end + 1} = {PersistenceStableBow(c, @linear_ramp), {'pbow_st', ['pbow_st_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceStableBow(c, @constant_one), {'pbow_st', ['pbow_st_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceSoftVLAD(c, @linear_ramp), {'svlad', ['svlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceSoftVLAD(c, @constant_one), {'svlad', ['svlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
		end
	end
	%%%

	% init seed for RNG
	initSeed = 11111;

	if par
		cluster = parcluster('local');
		workers = 8;
		cluster.NumWorkers = workers;
		saveProfile(cluster);
		pool = parpool(workers);
	end

	for o = 1:numel(objs)
		allAccTest = zeros(N, nclasses + 1);
		allAccTrain = zeros(N, nclasses + 1);
		conf_matrices_test = zeros(N, nclasses, nclasses);
		conf_matrices_train = zeros(N, nclasses, nclasses);
		allTimes = zeros(N, 4);
		allC = zeros(N, 1);

		obj = objs{o}{1};
		prop = objs{o}{2};

		for i = 1:N
			[pds, train_surfs, persistenceLimits] = load_data_nth_rep(i, expPath, basename, sample);
			% all pds in flat cell array
			flat_pds = cell(26*sample*2, 1); 
			% all labels in flat array
			flat_labels = zeros(26*sample*2, 1);
			train_set = [];
			test_set = [];
			for s = 1:26
				l = sample*2*(s-1)+1;
				r = l + sample*2-1;
				flat_pds(l:r) = [pds{s}(:,1), pds{s}(:,2)];
				flat_labels(l:r) = [zeros(sample, 1); ones(sample, 1)];

				if ismember(s, train_surfs)
					train_set = [train_set l:r];
				else
					test_set = [test_set l:r];
				end
			end

			seedBig = i * initSeed;
			rng(seedBig);
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);

			[acc, precAcc, confMats, C, times, obj] = compute_accuracy(obj, ...
				pds(train_set), pds(test_set), labels(train_set), labels(test_set), ...
				nclasses, persistenceLimits(i,:), algorithm, prop{1}, prop{2}, ...
				expPath, '', seedBig);

			allC(i) = C;
			allAccTest(i, :) = [acc{1}, precAcc{1}]';
			conf_matrices_test(i, :, :) = confMats{1};
			allAccTrain(i, :) = [acc{2}, precAcc{2}]';
			conf_matrices_train(i, :, :) = confMats{2};
			allTimes(i, :) = times;

% 			[accuracy, preciseAccuracy, confusion_matrix, times, obj] = ...
% 				compute_accuracy_petroglyphs(obj, pds, flat_pds, ...
% 				flat_labels, train_surfs, sample, diagramLimits, algorithm, ...
% 				prop{1}, strcat(basename, '_', 'rep', num2str(i), '_', prop{2}), ...
% 				expPath, seedBig);
% 			acc(i, :) = [accuracy, preciseAccuracy]';
% 			conf_matrices(i, :, :) = confusion_matrix;
% 			all_times(i, :) = times;

%			% Save pbow objects
%			if strcmp(prop{1}, 'pbow') || strcmp(prop{1}, 'pfv') || strcmp(prop{1}, 'pvlad')
%				repr = obj.test(pds(:));
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
%			end
		end
		
		avg_conf_mat = squeeze(sum(conf_matrices, 1));
		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, sufix, types, prop, all_times, acc, avg_conf_mat);
	end
end

function [accuracy, preciseAccuracy, confusion_matrix, times, obj] = compute_accuracy_petroglyphs(...
		obj, pds, flat_pds, flat_labels, train_surfs, sample, diagramLimits, ...
		algorithm, name, detailName, expPath, seed)
  %%% OUTPUT:
  %     accuracy - overall accuracy
  %     preciseAccuracy - accuracy for every class
  %     times - cell array {descriptor creation time, kernel creation time}
  %     obj   - 
	times = [-1, -1];

	%Get train subset 
	tr_pds = cell(length(train_surfs) * sample * 2, 1);
	tridx = [];
	disp('Preparing train subset');
	for s = 1:length(train_surfs)
		sidx = train_surfs(s);
		l = sample*2*(s-1)+1;
		r = l + sample*2-1;
		tr_pds(l:r) = [pds{sidx}(:, 1), pds{sidx}(:,2)];
		offset = (sidx-1) * sample * 2;
		tridx = [tridx, offset + [1:2*sample]];
	end
	tridx = sort(tridx);
	teidx = 1:length(flat_labels);
	teidx(tridx) = [];
	disp('Prepared');

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
	case {'pk1'}
		kernelPath = [expPath, detailName, '.mat'];
		if ~exist(kernelPath, 'file')
			repr = obj.predict(flat_pds);
		
			[K, time] = obj.generateKernel(repr, detailName);
			times(2) = time;
			save(kernelPath, 'K', 'times');
		else
			load(kernelPath);
		end
		% K is uppertriangular, so ...
		K = K;
	case {'pk2e', 'pk2a', 'pl'}
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
			obj = obj.fit(tr_pds, diagramLimits);
			reprCell = obj.predict(flat_pds);
		end

		times(1) = toc;
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

	accuracy = [];
	preciseAccuracy = [];
	confusion_matrix = [];
	switch algorithm
		case 'linearSVM-kernel'
		  [accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(1-K, flat_labels+1, tridx, teidx, ...
		        'kernel');
		case 'linearSVM-vector'
		  [accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(features, flat_labels+1, tridx, teidx, ...
		        'vector');
		otherwise
			error('Only vectorSVM can be used for this experiment');
	end
end

function [pds, train_surfs, persistenceLimits] = load_data_nth_rep(n, path, basename, sample)
	% data is a cell array 26x1
	% each cell contains cell array samplex2
	% first column contains PDs not clasified as a picture
	% second column contains PDs clasified as a picture
	load([path, basename, '_rep', num2str(n),'.mat'], 'pds');

	rng(n)
	train_surfs = sort(randsample(26, 13))';
	%%%%% COMPUTE DIAGRAM LIMITS
	disp(strcat('Computing limits'));
	persistenceLimits = [0, 0];
	dmax = max(pds{train_surfs(1)}{1,1}(:,2));
	dmin = min(pds{train_surfs(1)}{1,1}(:,1));
	dpers = [];
	dpers = [];
	for s = train_surfs
		for i = 1:sample
			for j = 1:2
				dmin = min(dmin, min(pds{s}{i,j}(:,1)));
				dmax = max(dmax, max(pds{s}{i,j}(:,2)));
%				dmins = [dmins, min(pds{s}{i,j}(:,1))];
%				dmaxs = [dmaxs, max(pds{s}{i,j}(:,2))];
				dpers = [dpers, min(pds{s}{i,j}(:,2) - pds{s}{i,j}(:,1))];
				dpers = [dpers, max(pds{s}{i,j}(:,2) - pds{s}{i,j}(:,1))];
			end
		end
	end
	persistenceLimits = [dmin, dmax];
	disp(strcat('MinMax diagram values: ', num2str(persistenceLimits)));
%	diagramLimits = [quantile(dmins, 0.01), quantile(dmaxs, 0.99)];
	persistenceLimits = [quantile(dpers, 0.01), quantile(dpers, 0.99)];
	disp(strcat('Diagram limits: ', num2str(persistenceLimits)));
end
