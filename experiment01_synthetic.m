% Synthetic shapes experiment
function experiment01_synthetic(test_type, algorithm, init_parallel)
%%%	ARGS:
%		test_type:	0-kernels, 1-vectorized descriptors, 2-codebooks, 3-stable codebooks, 4-PVLAD+PFV
%		algorithm:	0-'linearSVM-kernel', 1-'linearSVM-vector'
%		init_parallel: aplicable only for test_type=1

%%%%% EXPERIMENT PARAMETERS
	% number of trials
	N = 25;
	% PI tested resolutions and relative sigmas
	pi_r = 10:10:100;
	pi_s = [0.1, 0.5, 1, 1.5, 2, 3];
	% tested codebook sizes
	bow_sizes = [5, 10:10:200];
	sample_sizes = [1000, 5000, 10000];

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
	rawPath = 'rawdata/exp01_synthetic/';
	expPath = 'exp01_synthetic/';
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	addpath('../pdsphere/matlab');
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));
  
	types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
	    'Clusters within Clusters', 'Torus', 'Random Cloud 2D'};
	nclasses = numel(types);

	pds = prepareDiagrams(rawPath, expPath, types);

	if par
		cluster = parcluster('local');
		workers = 8;
		cluster.NumWorkers = workers;
		saveProfile(cluster);
		pool = parpool(workers);
	end

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
		for r = [10, 20, 40]
			for s = 0.1:0.1:0.3
				for d = 50:25:100
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
	%%%%%

	labels = [repmat(1, [1, 50]), ...
		repmat(2, [1, 50]), ...
		repmat(3, [1, 50]), ...
		repmat(4, [1, 50]), ...
		repmat(5, [1, 50]), ...
		repmat(6, [1, 50]), ...
		repmat(7, [1, 50])]';
	pds = pds(:);

	% init seed for RNG
	initSeed = 10000;

	% compute diagram limits for every run
	disp('Computing diagrams limits');
	persistenceLimits = zeros(N, 2);
	trainSet = cell(N, 1);
	testSet = cell(N, 1);
	for i = 1:N
		seedBig = i * initSeed;
		[tridx, teidx] = train_test_indices(labels, nclasses, 0.2, seedBig);
		trainSet{i} = tridx;
		testSet{i} = teidx;

		trainPoints = cat(1, pds{tridx});
		trainPointsPersist = trainPoints(:, 2) - trainPoints(:, 1);
		persistenceLimits(i,:) = [quantile(trainPointsPersist, 0.05), ...
			quantile(trainPointsPersist, 0.95)];
	end

% 	cPI = consolidated_PI(pds(:), 0.1, 250);

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
				expPath, '', seedBig);

			allC(i) = C;
			allAccTest(i, :) = [acc{1}, precAcc{1}]';
			conf_matrices_test(i, :, :) = confMats{1};
			allAccTrain(i, :) = [acc{2}, precAcc{2}]';
			conf_matrices_train(i, :, :) = confMats{2};
			allTimes(i, :) = times;

%			if strcmp(prop{1}, 'pbow')
%				repr = obj.predict(pds(:));
%				kdwords = obj.kdwords;
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_codebook.mat'), 'kdwords');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
%			end
		end

		avg_conf_mat_test = squeeze(sum(conf_matrices_test, 1)/N);
		avg_conf_mat_train = squeeze(sum(conf_matrices_train, 1)/N);

		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, '', types, prop, ...
			allTimes, allAccTest, avg_conf_mat_test, allAccTrain, ...
			avg_conf_mat_train, allC); 
	end
end %experiment01

function pds = prepareDiagrams(rawPath, expPath, types)
	PLOT = 0;

	pdfilename = 'exp01_pds.mat';
	% load pds
	if ~exist([expPath, pdfilename], 'file')
		pds = cell(numel(types), 50);
		for i = 2:51
			for j = 1:numel(types)
				filePath = [rawPath, 'pd_gauss_0_1/', types{j}, '/', num2str(i), '.h5.pc.simba.1.00001_3.persistence'];
				pd = importdata(filePath, ' ');
				pd(isinf(pd(:, 3)) | pd(:, 1) ~= 1, :) = [];
				pds{j, i - 1} = pd(:, 2:3);

				if PLOT
					subplot(2, 3, i - 1);
					colors = {'y*', 'm*', 'c*', 'r*', 'g*', 'b*'};
					plot(pd(:, 2), pd(:, 3), colors{j}); xlim([0, 0.22]); ylim([0, 0.22]); legend(types);
					hold on;
				end
			end
		end
		pds = pds';
		save([expPath, pdfilename], 'pds');
	else
		load([expPath, pdfilename]);
	end
end
