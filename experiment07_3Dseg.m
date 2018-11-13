% Synthetic shapes experiment
function experiment07_3Dseg(test_type, algorithm, init_parallel)
%%%	ARGS:
%		test_type:	0-kernels, 1-vectors, 2-codebooks, 3-stable codebooks
%		algorithm:	0-'linearSVM-kernel', 1-'linearSVM-vector'
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
	expPath = 'exp07_3Dseg/';
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	addpath('../pdsphere/matlab');
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));
  
	sufix = '';
	basename = strcat('pds', sufix);
	
	load([expPath, basename, '.mat'], 'pds');
	load([expPath, basename, '.mat'], 'labels');
	pds = pds';
	nclasses = 4;
	labels = labels + 1;

	% calculate diagram limits
	allPoints = cat(1, pds{:});
	allPointsPersist = allPoints(:, 2) - allPoints(:, 1);
	diagramLimits = [quantile(allPointsPersist, 0.01), ...
		quantile(allPointsPersist, 0.95)];
%	diagramLimits = [quantile(allPoints(:, 1), 0.001), ...
%    quantile(allPoints(:, 2), 0.999)];

	if par
		cluster = parcluster('local');
		workers = 16;
		cluster.NumWorkers = workers;
		saveProfile(cluster);
		pool = parpool(workers);
	end

	types = {'class1','class2','class3','class4'};

	%%%%% EXPERIMENT PARAMETERS
	% number of trials
	N = 25;
	% PI tested resolutions and relative sigmas
	pi_r = [5, 10, 15, 20:10:50];
	pi_s = [0.1, 0.25, 0.5, 1, 1.5, 2];
	% tested codebook sizes
	bow_sizes = [5, 10, 15, 20:10:50];
	
	objs = {};
	switch test_type
	%%% KERNEL APPROACHES
	case 0
		disp('Creating kernel descriptor objects');
		objs{end + 1} = {PersistenceKernelOne(2.0), {'pk1', ['pk1_', num2str(2.0)]}};
		objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
		for c = [0.5, 1., 1.5, 2.0, 3.0]
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', ['pk1_', num2str(c)]}};
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', 'pk1'}};
		end
		objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
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
		disp('Creating codebooks objects');
		for c = bow_sizes
			objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceBow(c, @linear_ramp, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceBow(c, @constant_one, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
		end
		for c = bow_sizes
			objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
		end
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
	%%%%%
	disp('Descriptor objects created. Testing');

	for o = 1:numel(objs)
		acc = zeros(N, nclasses+1);
		conf_matrices = zeros(N, nclasses, nclasses);
		all_times = zeros(N, 2);
		obj = objs{o}{1};
		prop = objs{o}{2};

		for i = 1:N
			seedBig = i * 10000;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
			
			[accuracy, preciseAccuracy, confusion_matrix, times, obj] = compute_accuracy(obj, pds(:), ...
			    labels, 4, diagramLimits, algorithm, prop{1}, prop{2}, ...
			    expPath, seedBig);
			acc(i, :) = [accuracy, preciseAccuracy]';
			conf_matrices(i, :, :) = confusion_matrix;
			all_times(i, :) = times;

%			if strcmp(prop{1}, 'pbow')
%				repr = obj.predict(pds(:));
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
%			end
		end

		avg_conf_mat = squeeze(sum(conf_matrices, 1));
		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, '', types, prop, all_times, acc, avg_conf_mat);
	end
end
