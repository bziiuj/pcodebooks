% GeoMat textures experiment
function experiment03_geomat(test_type, algorithm, init_parallel, subset)
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

	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	expPath = 'exp03_geomat/';
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));
	
	dim = 1;
	scale = '400';
	if subset
		subset = '_sub25';
	else
		subset = '';
	end
	sufix = strcat(num2str(dim)', '_', scale, subset);
	basename = strcat('pds_', sufix);
	
	load([expPath, basename, '.mat'], 'pds');
	pds = pds';
	
	pds_size = size(pds);
	nclasses = pds_size(2);
	nexamples = pds_size(1);
	
	types = {'Asphalt', 'Brick', 'Cement - Granular', 'Cement - Smooth', ...
	    'Concrete - Cast-in-Place', 'Concrete - Precast', 'Foliage', ...
	    'Grass', 'Gravel', 'Marble', 'Metal - Grills', 'Paving', ...
	    'Soil - Compact', 'Soil - Dirt and Vegetation', 'Soil - Loose', ...
	    'Soil - Mulch', 'Stone - Granular', 'Stone - Limestone', 'Wood'};
	
	allPoints = cat(1, pds{:});
	diagramLimits = [quantile(allPoints(:, 1), 0.005), ...
	  quantile(allPoints(:, 2), 0.995)];

	%%%%% EXPERIMENT PARAMETERS
	% PI tested resolutions and relative sigmas
	% number of trials
	N = 25;
	pi_r = [10, 20:20:200];
	% pi_r = 20:30:110;
	pi_s = [0.1, 0.25, 0.5, 1, 1.5];
	% tested codebook sizes
%	bow_sizes = [10:10:50, 70:20:150, 180:30:210];
	bow_sizes = [10, 20:20:200];
	% bow_sizes = 20:30:200;
	sample_sizes = [50000];

	objs = {};
	switch test_type
	%%% KERNEL APPROACHES
	case 0
		disp('Creating kernel descriptor objects');
		objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
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
		for r = [5, 10, 20, 40]
			for s = [0.01, 0.1, 0.2, 0.3]
				for d = 25:25:100
					objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), ...
					'_', num2str(s), '_', num2str(d)]}};
				end
			end
		end
	%%% PERSISTENCE CODEBOOKS
	case 2
		disp('Creating codebooks objects');
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
%		for c = bow_sizes
%			for s = sample_sizes
%				objs{end + 1} = {PersistenceBow(c, @linear_ramp, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
%				objs{end}{1}.sampleSize = s;
%			end
%		end
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

	if par
		cluster = parcluster('local');
		workers = 32;
		cluster.NumWorkers = workers;
		saveProfile(cluster);
		pool = parpool(workers);
	end

	for o = 1:numel(objs)
		acc = zeros(N, nclasses + 1);
		conf_matrices = zeros(N, nclasses, nclasses);
		all_times = zeros(N, 2);
		obj = objs{o}{1};
		prop = objs{o}{2};
		
		for i = 1:N
			seedBig = i * 10101;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
			
			labels = reshape(repmat(1:nclasses, [nexamples, 1]), [nclasses*nexamples, 1]);
			
			[accuracy, preciseAccuracy, confusion_matrix, times, obj] = compute_accuracy(obj, pds(:), ...
				labels, nclasses, diagramLimits, algorithm, prop{1}, ...
				strcat(basename, '_', prop{2}), expPath, seedBig);
			acc(i, :) = [accuracy, preciseAccuracy]';
			conf_matrices(i, :, :) = confusion_matrix;
			all_times(i, :) = times;

%			% Save pbow objects
%			if strcmp(prop{1}, 'pbow') || strcmp(prop{1}, 'pfv') || strcmp(prop{1}, 'pvlad')
%				repr = obj.predict(pds(:));
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
%			end
%		end

		avg_conf_mat = squeeze(sum(conf_matrices, 1));
		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, sufix, types, prop, all_times, acc, avg_conf_mat); 
	end
end
