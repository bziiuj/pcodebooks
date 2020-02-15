function new_pbows_exp_petro()
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
	N = 4;
	
	algorithm = 0;
	
	switch algorithm
	case 0
		algorithm = 'linearSVM-kernel';
	case 1
		algorithm = 'linearSVM-vector';
	end

	dataset = 'petro';
	expPath = 'exp04_petro_new/';
	dataPath = 'exp04_petroglyphs/';
% 	bow_sizes = 25:25:200;
% 	sample_sizes = [10000];

	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	confPath = strcat(expPath, 'conf/');
	mkdir(confPath);
	mkdir(strcat(expPath, 'descriptors/'));
	basename = strcat('pds_petroglyphs');

	nclasses = 2;
	sample = 300;
	types = {'no_engravement', 'engravement'};

% 	[variants, exp_name] = spbow_vs_sapi(dataset);
% 	[variants, exp_name] = pi_vs_nspbow_test(dataset);
	[variants, exp_name] = nspbow_sample_size_test();
	
	% init seed for RNG
	initSeed = 11111;

	% labels preparation
	labels = zeros(26*300*2, 1);
	for s = 1:26
		l = sample*2*(s-1)+1;
		r = l + sample*2-1;
		labels(l:r) = [zeros(sample, 1); ones(sample, 1)];
	end
	labels = labels + 1;

	% test surfaces for each run
	test_surfs = {[5,6,7,8,9,10,20], [2,3,4,23,24,25,26], [12,13,15,16,17,18,19], [1,11,14,21,22]};

	trainSet = cell(N, 1);
	testSet = cell(N, 1);
	persistenceLimits = zeros(N, 2);

	% train test indices for each run
	for s = 1:26
		l = sample*2*(s-1)+1;
		r = l + sample*2-1;
		for i = 1:N
			if ismember(s, test_surfs{i})
				testSet{i} = [testSet{i} l:r];
			else
				trainSet{i} = [trainSet{i} l:r];
			end
		end
	end

	% get random subset for EXP-A
	for i = 1:N
		seedBig = i * initSeed;
		[trSample, teSample] = train_test_subsets(labels, nclasses, trainSet{i}, testSet{i}, 19*15, 7*15, seedBig);
		trainSet{i} = sort(trSample);
		testSet{i} = sort(teSample);
	end

	% load diagrams and move them, so all points has positive values
	pds_reps = cell(N,1);
	for i = 1:N
		load([dataPath, basename, '_s300_rep', num2str(i),'.mat'], 'pds');
		pds{1} = pds{1}(:);
		for s = 2:26
			pds{1} = [pds{1}; pds{s}(:)];
		end
		pds = pds{1};

		allPoints = cat(1, pds{:});
		min_birth = min(allPoints(:,1));
		for j = 1:length(pds)
			pds{j} = pds{j} - min_birth;
		end

		pds_reps{i} = pds;
	end

	disp('Descriptor objects created. Testing');
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

		for i = 1:N
			seedBig = i * initSeed;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);

			pds = pds_reps{i};
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

function [variants, name] = spbow_vs_sapi(~)
	res = [1, 5, 10, 15, 25];
	wf = {'const', 'lin', 'pow2', 'pow3'};
	name = 'spbow_vs_sapi';
	
	bow_sizes = 20:20:200;
	sample_sizes = [20000, 100000, 300000];

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

function [variants, name] = pi_vs_nspbow_test(~)
	res = 5:5:25;
	wf = {'const', 'lin', 'pow2', 'pow3'};
	name = 'pi_vs_nspbow';
	sigma = 1;
	sample_size = 50000;
	
	variants = {};
%  	%%% GRID+NORM - STABLE PBOW
% 	for g = res
% 		for f = wf
% 			variants{end+1} = {{g*g, 'sampleSize', sample_size, 'norm', true, ...
% 				'samplingWeight', f{:}, 'gridsize', g }, ...
% 				{'nspbow', ['nspbow_', num2str(g*g)]}}; %#ok<CCAT,AGROW>
% 		end
% 	end
	%%% PI
	for g = res
		for f = wf
			variants{end+1} = {{g, sigma, 'weightingFunction', f{:}}, ...
				{'pi', ['pi_', num2str(g), '_', num2str(1)]}}; %#ok<CCAT,AGROW>
		end
	end
end

function [variants, name] = nspbow_sample_size_test(~)
% 	res = [5, 10, 20, 30, 40];
	res = [30, 40];
	wf = {'const', 'lin', 'pow2'};
	cs = [10, 50, 100, 200, 400];
	name = 'sample_size';
	sample_sizes = [20000:20000:100000, 125000, 150000:50000:300000];
	
	variants = {};
 	%%% GRID+NORM - STABLE PBOW
	for g = res
		for c = cs
			for f = wf
				for ss = sample_sizes
					variants{end+1} = {{c, 'sampleSize', ss, 'norm', true, ...
						'samplingWeight', f{:}, 'gridsize', g }, ...
						{'nspbow', ['nspbow_', num2str(g)]}}; %#ok<CCAT,AGROW>
				end
			end
		end
	end
end