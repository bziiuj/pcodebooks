% petrogllyphs experiment
function experiment08_petro_database_size(test_type)
%%%	ARGS:
%		test_type:	0-kernels, 1-vectors, 2-codebooks, 3-stable codebooks
%		algorithm:	0-'linearSVM-kernel', 1-'linearSVM-vector'
%		initialize parallel pool (it is convinient to have a lot of workers while computing PI on a grid)
%		experiment using subset of data (true) or full dataset (false)

algorithm = 'linearSVM-vector';

%	if nargin < 4
%		sample = 300;
%	else
%		sample = subset;
%	end

	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	dataPath = 'exp04_petroglyphs/';
	expPath = 'exp08_petro_dataset_size/';
	mkdir(expPath);

%	parallel_pi = true; 

	sufix = strcat('s300');
%	sufix = strcat('s', num2str(sample));
	basename = strcat('pds_petroglyphs');
	sample = 300;
	nclasses = 2;

	types = {'no_engravement', 'engravement'};
	
	%%%%% EXPERIMENT PARAMETERS
	% Number of trials
	N = 4;
	bow_sizes = [50];
	sample_sizes = [10000];

	num_of_pds = 1000:1000:10000;
% 	num_of_pds = [5000, 10000];
	objs = {};
	switch test_type
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
				for o = [1]
					objs{end + 1} = {PersistenceFV(c, @linear_ramp, o), {'pfv', ['pfv_', num2str(c)]}};
					objs{end}{1}.sampleSize = sample_size;
				end
			end
			for c = bow_sizes
				objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				for o = [1]
					objs{end + 1} = {PersistenceFV(c, @constant_one, o), {'pfv', ['pfv_', num2str(c)]}};
					objs{end}{1}.sampleSize = sample_size;
				end
			end
		end
% 	%%% STABLE PERSISTENCE CODEBOOKS
% 	case 3
		for sample_size = sample_sizes
			disp(['Creating stable codebooks objects.', ' Sample size: ', num2str(sample_size)]);
			for c = bow_sizes
% 				objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
				objs{end + 1} = {PersistenceStableBow(c, @linear_ramp, 1), {'pbow_st', ['pbow_st_', num2str(c)]}};
				objs{end}{1}.sampleSize = sample_size;
			end
			for c = bow_sizes
				for o = [1]
					objs{end + 1} = {PersistenceStableBow(c, @constant_one, o), {'pbow_st', ['pbow_st_', num2str(c)]}};
					objs{end}{1}.sampleSize = sample_size;
				end
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
	disp('Descriptor objects created. Testing');
 
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

	trainSet = cell(length(num_of_pds), N, 1);
	testSet = cell(length(num_of_pds), N, 1);

	% train test indices for each run
	for s = 1:26
		l = sample*2*(s-1)+1;
		r = l + sample*2-1;
		for i = 1:N
			for ip = 1:length(num_of_pds)
				if ismember(s, test_surfs{i})
					testSet{ip,i} = [testSet{ip,i} l:r];
				else
					trainSet{ip,i} = [trainSet{ip,i} l:r];
				end
			end
		end
	end

	% get random subsets
	for ip = 1:length(num_of_pds)
		p = num_of_pds(ip)*0.5;
		for i = 1:N
			seedBig = i * initSeed;
			[trSample, teSample] = train_test_subsets(labels, nclasses, ...
				trainSet{ip,i}, testSet{ip,i}, p*0.9, p*0.1, seedBig);
			trainSet{ip,i} = sort(trSample);
			testSet{ip,i} = sort(teSample);
		end
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

	% compute persistence limits for each run
	persistenceLimits = zeros(length(num_of_pds), N, 2);
	for ip = 1:length(num_of_pds)
		for i = 1:N
			pds = pds_reps{i};
			trainPoints = cat(1, pds{trainSet{ip,i}});
			trainPointsPersist = trainPoints(:, 2) - trainPoints(:, 1);
			persistenceLimits(ip,i,:) = [quantile(trainPointsPersist, 0.05), ...
				quantile(trainPointsPersist, 0.95)];
		end
	end

	for o = 1:numel(objs)
		obj = objs{o}{1};
		prop = objs{o}{2};

		fid_summary = fopen([expPath, 'results_', sufix, ...
				algorithm, '_', prop{1}, '.txt'], 'a');
		header = [prop{1}, ';sample;fit_time;predict_time;svm_time;std;acc;', types{1}, ';', types{2}];
		fprintf(fid_summary, '%s\n', header);
		fclose(fid_summary);
 
		for ip = 1:length(num_of_pds)
			acc = zeros(N, nclasses + 1);
			all_times = zeros(N, 4);
			for i = 1:N

				seedBig = i * 10103;
				rng(seedBig);
				fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);

				[accTest, precAccTest, ~, ~, times, obj] = compute_accuracy_exp8(obj, ...
					pds(trainSet{ip,i}), pds(testSet{ip,i}), labels(trainSet{ip,i}), labels(testSet{ip,i}), ...
					nclasses, persistenceLimits(ip,i,:), algorithm, prop{1}, prop{2}, ...
					expPath, '', seedBig);

				acc(i, :) = [accTest{1}, precAccTest{1}]';
				all_times(i, :) = times;
			end

			fprintf('Saving results for: %s\n', prop{2});

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

			basicLine = sprintf(['%s;%f;%f;%f;%f;%f;%f;%f', repmat(';%f', [1, length(types)])], ...
				prop{1}, num_of_pds(ip), mean(all_times(:,1)), mean(all_times(:,2)), mean(all_times(:,3)), ...
				mean(all_times(:,4)), std(acc(:,1)), mean(acc));

			fprintf(fid_summary, '%s;%s\n', basicLine, specs);
			fclose(fid_summary);
		end
	end
end

function [accuracy, preciseAccuracy, confMats, C, times, obj] = ...
	compute_accuracy_exp8(obj, train_pds, test_pds, train_labels, test_labels, ...
	nclass, persistenceLimits, ~, name, detailName, expPath, sufix, seed)

	times = [-1, -1, -1, -1];

% 	kernelPath = [expPath, detailName,'_', num2str(seed), '.mat'];
% 	descrPath = [expPath, 'descriptors/', name, sufix, '_', obj.getSufix(), '_', num2str(seed), '.mat'];

	pds = cat(1, train_pds, test_pds);
	labels = cat(1, train_labels, test_labels);

	switch name
	case {'pbow', 'pvlad', 'pfv', 'pbow_st', 'svlad'}
		tic;
%		obj = obj.fit(flat_pds, diagramLimits);
		obj = obj.fit(train_pds, persistenceLimits);
		times(1) = toc;
		tic
		reprCell = obj.predict(pds);
%		reprCell = obj.predict(flat_pds);
		times(2) = toc;

		features = zeros(obj.feature_size, length(reprCell));
		for i = 1:length(reprCell)
			features(:, i) = reprCell{i}(:)';
		end

	otherwise
		error('wrong descriptor type');
	end

	train_idx = 1:length(train_pds);
	test_idx = length(train_pds)+1:length(pds);
	[accTest, pAccTest, ~, ...
		accTrain, pAccTrain, ~, C, svm_time] = ...
		new_PD_svmclassify(features, labels, train_idx, test_idx, 'vector');
	times(3) = svm_time(1);
	times(4) = svm_time(2);
	accuracy = {accTest, accTrain};
	preciseAccuracy = {pAccTest, pAccTrain};
	confMats = 0;

%	all_idx = 1:length(flat_labels);
%	tic
%	switch algorithm
%		case 'linearSVM-kernel'
%		  [accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(1-K, flat_labels+1, tridx, teidx, ...
%		        'kernel');
%		case 'linearSVM-vector'
%			[accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(...
%				features, flat_labels+1, all_idx, all_idx, 'vector');
%		otherwise
%			error('Only vectorSVM can be used for this experiment');
%	end
%	times(3) = toc;
end

% function [pds, train_surfs, diagramLimits] = load_data_nth_rep(n, path, basename, sample)
% 	% data is a cell array 26x1
% 	% each cell contains cell array samplex2
% 	% first column contains PDs not clasified as a picture
% 	% second column contains PDs clasified as a picture
% 	load([path, basename, '_rep', num2str(n),'.mat'], 'pds');
% 
% 	rng(n)
% 	train_surfs = sort(randsample(26,13))';
% 	%%%%% COMPUTE DIAGRAM LIMITS
% 	disp(strcat('Computing limits'));
% 	diagramLimits = [0, 0];
% 	dmax = max(pds{train_surfs(1)}{1,1}(:,2));
% 	dmin = min(pds{train_surfs(1)}{1,1}(:,1));
% 	dmaxs = [];
% 	dmins = [];
% 	for s = train_surfs
% 		for i = 1:sample
% 			for j = 1:2
% 				dmin = min(dmin, min(pds{s}{i,j}(:,1)));
% 				dmax = max(dmax, max(pds{s}{i,j}(:,2)));
% 				dmins = [dmins, min(pds{s}{i,j}(:,1))];
% 				dmaxs = [dmaxs, max(pds{s}{i,j}(:,2))];
% 			end
% 		end
% 	end
% 	diagramLimits = [dmin, dmax];
% 	disp(strcat('MinMax diagram values: ', num2str(diagramLimits)));
% 	diagramLimits = [quantile(dmins, 0.01), quantile(dmaxs, 0.99)];
% 	disp(strcat('Diagram limits: ', num2str(diagramLimits)));
% end
