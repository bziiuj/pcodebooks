% Graphs Reddit_5K experiment
function experiment05_reddit5K(test_type, algorithm, init_parallel, subset)
%%%	ARGS:
%		test_type:	0-kernels, 11-PI, 12-PI weighted, 13-Riemannian sphere, 2-codebooks, 3-stable codebooks, 4-PVLAD+PFV
%		algorithm:	0-'linearSVM-kernel', 1-'linearSVM-vector'
%		initialize parallel pool (it is convinient to have a lot of workers while computing PI on a grid)
%		experiment using subset of data (true) or full dataset (false)

	%%%%% EXPERIMENT PARAMETERS
	% number of trials
	N = 5;

	if subset
		% PI tested resolutions and relative sigmas
		pi_r = [10:10:50, 60:20:120];
		pi_s = [0.5, 1, 2];
		% tested codebook sizes
		bow_sizes = [10:10:50, 60:20:200];
		sample_sizes = [2000, 10000, 50000];
	else
		% PI tested resolutions and relative sigmas
		pi_r = [10:10:60];
		pi_s = [0.5, 1, 2];
		% tested codebook sizes
		bow_sizes = [10:10:50, 60:20:200];
		sample_sizes = [2000, 10000, 50000];
	end

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

	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	expPath = 'exp05_reddit5K/';
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));
	
	if subset
		sufix = 'sub100';
	else
		sufix = '';
	end
	
	load([expPath, 'exp05_pds.mat'], 'pds');
	nclasses = size(pds, 2);

	types = {'cl1', 'cl2', 'cl3', 'cl4', 'cl5'};

	objs = {};
	switch test_type
	%%% KERNEL APPROACHES
	case 0
		disp('Creating kernel descriptor objects');
		objs{end + 1} = {PersistenceWasserstein(), {'pw', 'pw'}};
		for c = [0.5, 1., 2.0]
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', ['pk1_', num2str(c)]}};
		end
		for a = 50:50:250
		  objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
		end
		objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};

	%%% OTHER VECTORIZED APPROACHES
	case 11
		disp('Creating vectorized descriptor objects');
		for r = pi_r
			for s = pi_s
				objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
				objs{end}{1}.parallel = true;
			end
		end
	case 12
		for r = pi_r
			for s = pi_s
				objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
				objs{end}{1}.parallel = true;
			end
		end
	case 13
		for r = [20, 40, 60]
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

	if par
		cluster = parcluster('local');
		workers = 8;
		cluster.NumWorkers = workers;
		saveProfile(cluster);
		pool = parpool(workers);
	end

	% init seed for RNG
	initSeed = 10101;

	% labels preparation
	labels = {};
	for c = 1:nclasses
		labels{c} = ones(length(pds{c}), 1)*c;
	end
	labels = cat(1,labels{:});

	% flat pds cell array
	for c = 2:nclasses
		pds{1} = cat(2, pds{1}, pds{c});
	end
	pds = pds{1}';

	% compute diagrams train/test division for every run
	disp('Computing diagrams limits');
	persistenceLimits = zeros(N, 2);
	trainSet = cell(N, 1);
	testSet = cell(N, 1);
	for i = 1:N
		seedBig = i * initSeed;
		[tridx, teidx] = train_test_indices(labels, nclasses, 0.1, seedBig);
		trainSet{i} = sort(tridx);
		testSet{i} = sort(teidx);
	end

	% compute subsets for every run (for reduced experiment)
	if subset
		for i = 1:N
			seedBig = i * initSeed;
			[trSample, teSample] = train_test_subsets(labels, nclasses, trainSet{i}, testSet{i}, 90, 10, seedBig);
			trainSet{i} = sort(trSample);
			testSet{i} = sort(teSample);
		end
	end

	% compute persistence limits for every run
	for i = 1:N
		trainPoints = cat(1, pds{trainSet{i}});
		trainPointsPersist = trainPoints(:, 2) - trainPoints(:, 1);
		persistenceLimits(i,:) = [quantile(trainPointsPersist, 0.05), ...
			quantile(trainPointsPersist, 0.95)];
	end

	disp('Descriptor objects created. Testing');
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
			seedBig = i * initSeed;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);

			[acc, precAcc, confMats, C, times, obj] = compute_accuracy(obj, ...
				pds(trainSet{i}), pds(testSet{i}), labels(trainSet{i}), labels(testSet{i}), ...
				nclasses, persistenceLimits(i,:), algorithm, prop{1}, prop{2}, ...
				expPath, sufix, seedBig);

			allC(i) = C;
			allAccTest(i, :) = [acc{1}, precAcc{1}]';
			conf_matrices_test(i, :, :) = confMats{1};
			allAccTrain(i, :) = [acc{2}, precAcc{2}]';
			conf_matrices_train(i, :, :) = confMats{2};
			allTimes(i, :) = times;

%			% Save pbow objects
%			if strcmp(prop{1}, 'pbow') || strcmp(prop{1}, 'pfv') || strcmp(prop{1}, 'pvlad')
%				repr = obj.predict(pds(:));
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
%			end
		end

		avg_conf_mat_test = squeeze(sum(conf_matrices_test, 1)/N);
		avg_conf_mat_train = squeeze(sum(conf_matrices_train, 1)/N);

		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, sufix, types, prop, ...
			allTimes, allAccTest, avg_conf_mat_test, allAccTrain, ...
			avg_conf_mat_train, allC); 
	end
end
