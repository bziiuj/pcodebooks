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
		error('Kernel test is unavailable for this experiment!');
	case 1
		algorithm = 'linearSVM-vector';
	end
	par = 0;
	if nargin == 3
		par = init_parallel;
	end
	if test_type == 0
		error('Kernel test is unavailable for this experiment!');
	end

	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	expPath = 'exp04_petroglyphs/';
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);

	parallel_pi = true; 
	sample = 300;
	train_sample_size = 200;
	sufix = strcat('s', num2str(sample));
	basename = strcat('pds_petroglyphs_', sufix);
	load([expPath, basename, '.mat'], 'pds');
	% data is a cell array 26x1
	% each cell contains cell array samplex2
	% first column contains PD not clasified as a picture
	% second column contains PD not clasified as a picture

	% following scans, out of 26, are chosen for a training set
	train_scans = [2, 4, 6, 7, 9, 11, 15, 16, 17, 18, 22, 23, 25];

	nclasses = 2;

	types = {'stone', 'picture'};
	
	%%%%% COMPUTE DIAGRAM LIMITS
	disp(strcat('Computing limits'));
	diagramLimits = [0, 0];
	dmax = max(pds{2}{1,1}(:,2));
	dmin = min(pds{2}{1,1}(:,1));
	dmaxs = [];
	dmins = [];
	for s = train_scans
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

	%%%%% EXPERIMENT PARAMETERS
	% Number of trials
	N = 25;
	% PI tested resolutions and relative sigmas
	pi_r = [5, 10:10:50];%, 170:30:200];
	pi_s = [0.1, 0.25, 0.5, 1, 1.5, 2];
	% tested codebook sizes
%	bow_sizes = 150:20:210;
	bow_sizes = [5, 10:10:50]; %, 75, 100];%, 180:30:210];
%	bow_sizes = [10:10:50];
	sample_sizes = [10000];

	objs = {};
	switch test_type
	%%% OTHER VECTORIZED APPROACHES
	case 1
		disp('Creating vectorized descriptor objects');
		for r = pi_r
			for s = pi_s
				objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
				objs{end}{1}.parallel = parallel_pi;
			end
		end
		for r = pi_r
			for s = pi_s
				objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
				objs{end}{1}.parallel = parallel_pi;
			end
		end
		for r = [10, 20, 40, 60]
			for s = 0.1:0.1:0.3
%			for s = [0.0001, 0.0005, 0.001, 0.005, 0.01]
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
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceBow(c, @linear_ramp, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceBow(c, @constant_one, @linear_ramp), {'pbow', ['pbow_weight_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
		end
		for c = bow_sizes
			for s = sample_sizes
				objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
				objs{end}{1}.sampleSize = s;
			end
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
	%%%
	disp('Descriptor objects created. Testing');

	if par
		cluster = parcluster('local');
		workers = 32;
		cluster.NumWorkers = workers;
		saveProfile(cluster);
		pool = parpool(workers);
	end

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

	for o = 1:numel(objs)
		acc = zeros(N, nclasses + 1);
		all_times = zeros(N, 2);
		obj = objs{o}{1};
		prop = objs{o}{2};
		
		for i = 1:N
			seedBig = i * 10103;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
			
			[accuracy, preciseAccuracy, times, obj] = compute_accuracy_petroglyphs( ...
				obj, pds, flat_pds, flat_labels, train_scans, sample, train_sample_size, ...
				diagramLimits, algorithm, prop{1}, strcat(basename, '_', prop{2}), expPath, seedBig);
			acc(i, :) = [accuracy, preciseAccuracy]';
			all_times(i, :) = times;

%			% Save pbow objects
%			if strcmp(prop{1}, 'pbow') || strcmp(prop{1}, 'pfv') || strcmp(prop{1}, 'pvlad')
%				repr = obj.test(pds(:));
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
%				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
%			end
		end

		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, sufix, types, prop, all_times, acc); 
	end
end

function [accuracy, preciseAccuracy, times, obj] = compute_accuracy_petroglyphs(...
		obj, pds, flat_pds, flat_labels, train_scans, sample, train_sample_size, diagramLimits, ...
		algorithm, name, detailName, expPath, seed)
  %%% OUTPUT:
  %     accuracy - overall accuracy
  %     preciseAccuracy - accuracy for every class
  %     times - cell array {descriptor creation time, kernel creation time}
  %     obj   - 
	times = [-1, -1];

	%Get train subset 
	tr_pds = cell(length(train_scans) * train_sample_size * 2, 1);
	tridx = [];
	disp('Preparing train subset');
	for s = 1:length(train_scans)
		sidx = train_scans(s);
		idx0 = randperm(sample, train_sample_size);
		idx1 = randperm(sample, train_sample_size);
		l = train_sample_size*2*(s-1)+1;
		r = l + train_sample_size*2-1;
		tr_pds(l:r) = [pds{sidx}(idx0, 1), pds{sidx}(idx1,2)];
		offset = (sidx-1) * sample * 2;
		tridx = [tridx, offset + idx0, offset + sample + idx1];
	end
	tridx = sort(tridx);
	teidx = 1:length(flat_labels);
	teidx(tridx) = [];
	disp('Prepared');

	switch name
	case {'pi', 'pbow', 'pvlad', 'pfv', 'pbow_st', 'svlad'}
		tic;
		if strcmp(name, 'pi') %|| strcmp(name, 'pds')
			reprCell = obj.predict(flat_pds, diagramLimits);
		else
			obj = obj.fit(tr_pds, diagramLimits);
			reprCell = obj.predict(flat_pds);
		end

		times(1) = toc;
		features = zeros(obj.feature_size, length(reprCell));
		for i = 1:length(reprCell)
			features(:, i) = reprCell{i}(:)';
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
		tic;
		times(2) = toc;
	end
	
	switch algorithm
%		case 'linearSVM-kernel'
%		  [accuracy, preciseAccuracy] = new_PD_svmclassify(1-K, labels, tridx, teidx, ...
%		        'kernel');
		case 'linearSVM-vector'
		  [accuracy, preciseAccuracy] = new_PD_svmclassify(features, flat_labels+1, tridx, teidx, ...
		        'vector');
		otherwise
			error('Only vectorSVM can be used for this experiment');
	end
end
