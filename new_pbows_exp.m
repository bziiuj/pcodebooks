% Synthetic shapes experiment
function new_pbows_exp()
%%%	ARGS:
%		test_type:	0-kernels, 1-vectorized descriptors, 2-codebooks, 3-stable codebooks, 4-PVLAD+PFV
%		algorithm:	0-'linearSVM-kernel', 1-'linearSVM-vector'
%		init_parallel: aplicable only for test_type=1
			
	addpath('pcontrollers');
	addpath('utils');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	addpath('../pdsphere/matlab');
	
%%%%% EXPERIMENT PARAMETERS
	% number of trials
	N = 5;
	
	algorithm = 0;
	
	switch algorithm
	case 0
		algorithm = 'linearSVM-kernel';
	case 1
		algorithm = 'linearSVM-vector';
	end

	dataset = 'geomat';
	subset = false;
	[variants, exp_name] = spbow_vs_sapi(dataset);
% 	[variants, exp_name] = pi_vs_nspbow_test(dataset);
% 	[variants, exp_name] = nspbow_sample_size_test(dataset);
	if ~subset
		exp_name = [exp_name, '_full'];
	end

	switch dataset
		case 'synthetic'
			expPath = 'exp01_synthetic_new/';
			test_split = 0.2;
		case 'geomat'
			expPath = 'exp03_geomat_new/';
		case '3Dseg'
			expPath = 'exp07_3Dseg_new/';
			test_split = 0.5;
		otherwise
			expPath = 'exp00_other/';
	end
	[types, pds, labels] = loadDataset(dataset);
% 	bow_sizes = [100];
% 	sample_sizes = [10000];

	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));

	nclasses = numel(types);

	% init seed for RNG
	initSeed = 10000;

	% compute division for train and test
	persistenceLimits = zeros(N, 2);
	trainSet = cell(N, 1);
	testSet = cell(N, 1);

	if strcmp(dataset, 'geomat')
		if subset
			load('exp03_geomat/exp03_test_train_subsets.mat', 'testSet');
			load('exp03_geomat/exp03_test_train_subsets.mat', 'trainSet');
		else 
			% create matrix of indices
			indices = repmat([1:600]',1,19) + repmat(0:600:600*18, 600, 1);
			tridx = indices(1:400, :);
			teidx = indices(401:600, :);
			for i = 1:N
				trainSet{i} = tridx(:);
				testSet{i} = teidx(:);
			end
		end
	else
		if ~subset
			error("implement not subset");
		end
		for i = 1:N
			seedBig = i * initSeed;
			[tridx, teidx] = train_test_indices(labels, nclasses, test_split, seedBig);
			trainSet{i} = tridx;
			testSet{i} = teidx;

			trainPoints = cat(1, pds{tridx});
			trainPointsPersist = trainPoints(:, 2) - trainPoints(:, 1);
			persistenceLimits(i,:) = [quantile(trainPointsPersist, 0.05), ...
				quantile(trainPointsPersist, 0.95)];
		end
	end
% 	cPI = consolidated_PI(pds(:), 0.1, 250);

	disp('Descriptor objects created. Testing');
% 	for o = 1:numel(objs)
	for o = 1:numel(variants)
		allAccTest = zeros(N, nclasses + 1);
		allAccTrain = zeros(N, nclasses + 1);
		conf_matrices_test = zeros(N, nclasses, nclasses);
		conf_matrices_train = zeros(N, nclasses, nclasses);
		allTimes = zeros(N, 4);
		allC = zeros(N, 1);

		switch variants{o}{2}{1}
			case 'npbow'
				descr = @NewPersistenceBow;
			case 'nspbow'
				descr = @NewPersistenceStableBow;
			case 'pi'
				descr = @PersistenceImage;
			otherwise
				error('ups');
		end
		
% 		obj = pbow(variants{o}{1}{:});
		obj = descr(variants{o}{1}{:});
		prop = variants{o}{2};
% 		obj = objs{o}{1};
% 		prop = objs{o}{2};

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
		end

		avg_conf_mat_test = squeeze(sum(conf_matrices_test, 1)/N);
		avg_conf_mat_train = squeeze(sum(conf_matrices_train, 1)/N);

		fprintf('Saving results for: %s\n', prop{2});
		print_results(expPath, obj, N, algorithm, exp_name, types, prop, ...
			allTimes, allAccTest, avg_conf_mat_test, allAccTrain, ...
			avg_conf_mat_train, allC); 
	end
end %experiment01

function [variants, name] = nspbow_sample_size_test(dataset)
	res = [5, 10, 20, 30, 40];
	wf = {'const', 'lin', 'pow2'};
	cs = [10, 50, 100, 200, 400];
	name = 'sample_size';

	switch dataset
		case 'synthetic'
			sample_sizes = [1000:1000:6000 7000:2000:13000];
		case 'geomat'
			sample_sizes = [5000, 10000, 20000, 50000, 100000];
		case '3Dseg'
			sample_sizes = [2000:2000:10000, 12500, 15000:5000:30000];
		otherwise
			error('not known dataset');
	end
	
	variants = {};
 	%%% GRID+NORM - STABLE PBOW
	for g = res
		for c = cs
			for f = wf
				for ss = sample_sizes
					variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
						'samplingWeight', f{:}, 'gridsize', g }, ...
						{'nspbow', ['nspbow_', num2str(g)]}}; %#ok<CCAT,AGROW>
% 					variants{end+1} = {{c, 'sampleSize', s2, 'norm', true, ...
% 						'samplingWeight', f{:}, 'gridsize', g }, ...
% 						{'nspbow', ['nspbow_', num2str(g)]}}; %#ok<CCAT,AGROW>
% 					variants{end+1} = {{c, 'sampleSize', s3, 'norm', true, ...
% 						'samplingWeight', f{:}, 'gridsize', g }, ...
% 						{'nspbow', ['nspbow_', num2str(g)]}}; %#ok<CCAT,AGROW>
				end
			end
		end
	end
end

function [variants, name] = pi_vs_nspbow_test(dataset)
	res = 5:5:25;
	wf = {'const', 'lin', 'pow2', 'pow3'};
	name = 'pi_vs_nspbow';
	
	switch dataset
		case 'synthetic'
			sigma = 0.1;
			sample_size = 10000;
		case 'geomat'
			sigma = 0.5;
			sample_size = 2000;
		case '3Dseg'
			sigma = 0.5;
			sample_size = 10000;
		otherwise
			error('not known dataset');
	end
	
	variants = {};
 	%%% GRID+NORM - STABLE PBOW
	for g = res
		for f = wf
			variants{end+1} = {{g*g, 'sampleSize', sample_size, 'norm', true, ...
				'samplingWeight', f{:}, 'gridsize', g }, ...
				{'nspbow', ['nspbow_', num2str(g*g)]}}; %#ok<CCAT,AGROW>
		end
	end
	%%% PI
	for g = res
		for f = wf
			variants{end+1} = {{g, sigma, 'weightingFunction', f{:}}, ...
				{'pi', ['pi_', num2str(g), '_', num2str(1)]}}; %#ok<CCAT,AGROW>
		end
	end
end

function [variants, name] = spbow_vs_sapi(dataset)
	res = [1, 5, 10, 15, 25];
	wf = {'const', 'lin', 'pow2', 'pow3'};
	name = 'spbow_vs_sapi';
	
	switch dataset
		case 'synthetic'
			bow_sizes = [10, 20:20:200];
			sample_sizes = [2000, 5000, 10000];
		case 'geomat'
			bow_sizes = 20:20:200;
			sample_sizes = [10000, 50000, 100000];
		case '3Dseg'
			bow_sizes = 20:20:100;
			sample_sizes = [5000, 10000, 30000];
		otherwise
			error('not known dataset');
	end
	
	variants = {};
 	%%% STABLE PBOW
	for c = bow_sizes
		for g = res
			for s = sample_sizes
				for f = wf
					variants{end+1} = {{c, 'sampleSize', s, 'norm', true, ...
						'samplingWeight', f{:}, 'gridsize', g }, ...
						{'nspbow', ['nspbow_', num2str(g)]}}; %#ok<CCAT,AGROW>
				end
			end
		end
	end
end

% 	pbow = @PersistenceImage;
% 	%%% PERSISTENCE IMAGES
% 	for res = resolutions
% 		for s = sigmas
% 			disp({res, s})
% 			for wf = {'const', 'lin', 'pow2', 'pow3'}
% 				variants{end+1} = {{res, s, 'weightingFunction', wf{:}, ...
% 					'norm', false}, ...
% 					{'pi', ['pi_', num2str(res), '_', num2str(s)]}}; %#ok<AGROW>
% % 				variants{end+1} = {{res, s, 'weightingFunction', wf{:}, ...
% % 					'norm', true}, ...
% % 					{'pi', ['pi_', num2str(res), '_', num2str(s)]}}; %#ok<AGROW>
% 			end
% 		end
% 	end
	
% 	pbow = @NewPersistenceBow;
% 	%%% DEFAULT PBOWS
% 	for c = bow_sizes
% 		for ss = sample_sizes
% 			disp({c, ss})
% 			for sw = {'const', 'lin', 'pow2', 'pow3'}
% 				for pw = {'const', 'lin', 'pow2'}
% 					variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 						'samplingWeight', sw{:}, 'predictWeight', pw{:}},...
% 						{'npbow', ['npbow_', num2str(c)]}}; %#ok<*NASGU>
% % 					objs{end + 1} = {NewPersistenceBow(c, 'sampleSize', ss, ...
% % 						'norm', false, 'samplingWeight', sw{:}, 'predictWeight', pw{:} ...
% % 						), {'npbow', ['npbow_', num2str(c)]}};
% 				end
% 			end
% 		end
% 	end
% 
% 	%%% NORM, WKMEANS, NORM+WKMEANS
% 	for c = bow_sizes
% 		for ss = sample_sizes
% 			disp({c, ss})
% 			for sw = {'const', 'lin', 'pow2', 'pow3'}
% 				for pw = {'const', 'lin', 'pow2'}								
% 					variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
% 						'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% 						'method', 'kmeans'}, ...
% 						{'npbow', ['npbow_', num2str(c)]}}; %#ok<*CCAT>
% 					variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 						'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% 						'method', 'wkmeans'}, ...
% 						{'npbow', ['npbow_', num2str(c)]}};
% 					variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 						'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% 						'method', 'wkmeans'}, ...
% 						{'npbow', ['npbow_', num2str(c)]}};
% % 					objs{end + 1} = {NewPersistenceBow(c, 'sampleSize', ss, ...
% % 						'norm', true, 'samplingWeight', sw{:}, 'predictWeight', pw{:} ...
% % 						), {'npbow', ['npbow_', num2str(c)]}};
% % 					objs{end + 1} = {NewPersistenceBow(c, 'sampleSize', ss, ...
% % 						'norm', false, 'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% % 						'method', 'wkmeans' ...
% % 						), {'npbow', ['npbow_', num2str(c)]}};
% % 					objs{end + 1} = {NewPersistenceBow(c, 'sampleSize', ss, ...
% % 						'norm', true, 'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% % 						'method', 'wkmeans' ...
% % 						), {'npbow', ['npbow_', num2str(c)]}};
% 				end
% 			end
% 		end
% 	end
% 	
% 	%%% GRID, GRID+NORM
% 	for c = bow_sizes
% 		for g = [5, 10, 15, 20]
% 			ss = floor(10000/(g*sqrt(g)));
% % 			sample_size = floor(20000/(g*g));
% 			disp({c, g, ss})
% 			for sw = {'const', 'lin', 'pow2', 'pow3'}
% 				for pw = {'const', 'lin', 'pow2'}
% 					variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 						'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% 						'method', 'kmeans', 'gridsize', g}, ...
% 						{'npbow', ['npbow_', num2str(c)]}};
% 					variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
% 						'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% 						'method', 'kmeans', 'gridsize', g}, ...
% 						{'npbow', ['npbow_', num2str(c)]}};
% % 					objs{end + 1} = {NewPersistenceBow(c, 'sampleSize', sample_size, ...
% % 						'norm', false, 'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% % 						'gridsize', g), {'npbow', ['npbow_', num2str(c)]}};
% % 					objs{end + 1} = {NewPersistenceBow(c, 'sampleSize', sample_size, ...
% % 						'norm', true, 'samplingWeight', sw{:}, 'predictWeight', pw{:}, ...
% % 						'gridsize', g), {'npbow', ['npbow_', num2str(c)]}};
% 				end
% 			end
% 		end
% 	end

% 	pbow = @NewPersistenceStableBow;
% 	%%% DEFAULT STABLE PBOWS
% 	for c = bow_sizes
% 		for ss = sample_sizes
% 			disp({c, ss});
% 			for sw = {'const', 'lin', 'pow2', 'pow3'}
% 				variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 						'samplingWeight', sw{:}}, ...
% 						{'nspbow', ['nspbow_', num2str(c)]}};
% % 				objs{end + 1} = {NewPersistenceStableBow(c, 'sampleSize', ss, ...
% % 					'norm', false, 'samplingWeight', sw{:} ...
% % 					), {'nspbow', ['nspbow_', num2str(c)]}};
% 			end
% 		end
% 	end
%  	%%% NORM, WKMEANS, NORM+WKMEANS - STABLE PBOW
% 	for c = bow_sizes
% 		for ss = sample_sizes
% 			disp({c, ss})
% 			for sw = {'const', 'lin', 'pow2', 'pow3'}
% 				variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
% 						'samplingWeight', sw{:}, 'method', 'kmeans'}, ...
% 						{'nspbow', ['nspbow_', num2str(c)]}};
% 				variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 						'samplingWeight', sw{:}, 'method', 'wkmeans'}, ...
% 						{'nspbow', ['nspbow_', num2str(c)]}};
% 				variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
% 						'samplingWeight', sw{:}, 'method', 'wkmeans'}, ...
% 						{'nspbow', ['nspbow_', num2str(c)]}};
% % 				objs{end + 1} = {NewPersistenceStableBow(c, 'sampleSize', ss, ...
% % 					'norm', true, 'samplingWeight', sw{:} ...
% % 					), {'nspbow', ['nspbow_', num2str(c)]}};
% % 				objs{end + 1} = {NewPersistenceStableBow(c, 'sampleSize', ss, ...
% % 					'norm', false, 'samplingWeight', sw{:}, ...
% % 					'method', 'wkmeans' ...
% % 					), {'nspbow', ['nspbow_', num2str(c)]}};
% % 				objs{end + 1} = {NewPersistenceStableBow(c, 'sampleSize', ss, ...
% % 					'norm', true, 'samplingWeight', sw{:}, ...
% % 					'method', 'wkmeans' ...
% % 					), {'nspbow', ['nspbow_', num2str(c)]}};
% 			end
% 		end
% 	end
% 	
% 	%%% GRID, GRID+NORM - STABLE PBOW
% 	for c = bow_sizes
% 		for g = [5, 10, 15, 20]
% % 		for g = [2]
% 			ss = floor(10000/(g*sqrt(g)));
% % 			sample_size = floor(20000/(g*g));
% 			disp({c, g, ss})
% 			for sw = {'const', 'lin', 'pow2', 'pow3'}
% 				variants{end+1} = {{c, 'sampleSize', ss, 'norm', false, ...
% 					'samplingWeight', sw{:}, 'gridsize', g }, ...
% 					{'nspbow', ['nspbow_', num2str(c)]}};
% 				variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
% 					'samplingWeight', sw{:}, 'gridsize', g }, ...
% 					{'nspbow', ['nspbow_', num2str(c)]}};
% % 				objs{end + 1} = {NewPersistenceStableBow(c, 'sampleSize', sample_size, ...
% % 					'norm', false, 'samplingWeight', sw{:}, ...
% % 					'gridsize', g), {'nspbow', ['nspbow_', num2str(c)]}};
% % 				objs{end + 1} = {NewPersistenceStableBow(c, 'sampleSize', sample_size, ...
% % 					'norm', true, 'samplingWeight', sw{:}, ...
% % 					'gridsize', g), {'nspbow', ['nspbow_', num2str(c)]}};
% 			end
% 		end
% 	end
