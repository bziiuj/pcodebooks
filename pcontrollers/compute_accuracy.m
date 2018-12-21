function [accuracy, preciseAccuracy, confMats, C, times, obj] = ...
	compute_accuracy(obj, train_pds, test_pds, train_labels, test_labels, ...
	nclass, persistenceLimits, algorithm, name, detailName, expPath, sufix, seed)
%	compute_accuracy(obj, pds, labels, tridx, teidx, nclass, ...
% function [accTest, pAccTest, confMatTest, accTrain, pAccTrain, confMatTrain, ... 
% 		C, times, obj] = 
%%% OUTPUT:
%	accuracy - overall accuracy, two cells array, first for test, second for train
%	preciseAccuracy - accuracy for each class, two cells array, first for test, second for train
%	confMats - confusion matrix, two cells array, first for test, second for train
%	C - svm C parameter, deterimined by crossvalidation
%	times - 3 element array: descriptor fitting time, feature vectors/kernel creation time, svm duration time
%		(depending on descriptor some values are not filled) 
%   obj - escriptor object, it can modified by fitting process
	times = [-1, -1, -1, -1];

	kernelPath = [expPath, detailName,'_', num2str(seed), '.mat'];
	descrPath = [expPath, 'descriptors/', name, sufix, '_', obj.getSufix(), '_', num2str(seed), '.mat'];

	pds = cat(1, train_pds, test_pds);
	labels = cat(1, train_labels, test_labels);

%	[tridx, teidx] = train_test_indices(labels, nclass, 0.2, seed);
	switch name
	case {'pw'}
		disp(kernelPath);
		if ~exist(kernelPath, 'file')
			[K, tk] = obj.generateKernel(pds, num2str(seed));
			times(2) = tk;
			save(kernelPath, 'K', 'times');
		else
			load(kernelPath);
			K = double(K);
		end

	case {'pk1'}
		if ~exist(kernelPath, 'file')
			repr = obj.predict(pds);
			[K, tk] = obj.generateKernel(repr);
			times(2) = tk;
			save(kernelPath, 'K', 'times');
		else
			load(kernelPath);
		end
		% K is uppertriangular, so ...
		K = K + K';

	case {'pk2e', 'pk2a', 'pl'}
		if ~exist(kernelPath, 'file')
			tic;
			repr = obj.predict(pds);
			K = obj.generateKernel(repr);
			times(2) = toc;
			save(kernelPath, 'K', 'times');
		else
			load(kernelPath);
		end
		% K is uppertriangular, so ...
		K = K + K';

	case {'pi', 'pbow', 'pvlad', 'pfv', 'pbow_st', 'svlad'}
		if ~exist(descrPath, 'file')
			tic;
			if size(pds, 2) > 1
				nelem = size(pds, 1);
				% number of persistence diagrams representing an object
				nsubpds = size(pds, 2);
				% for each sub diagram do another classification
				reprCell = cell(nelem, nsubpds);
				for d = 1:nsubpds
					if strcmp(name, 'pi') %|| strcmp(name, 'pds')
						reprCell(:,d) = obj.predict(pds(:,d), persistenceLimits(d,:));
% 						reprCell(:,d) = obj.predict(pds(:,d), persistenceLimits{d});
					else
						obj = obj.fit(train_pds(:,d), persistenceLimits(d,:));
						reprCell(:,d) = obj.predict(pds(:,d));
% 						tr_pds = pds(tridx, d);
% 						obj = obj.fit(tr_pds, persistenceLimits{d});
% 						reprCell(:,d) = obj.predict(pds(:, d));
					end
				end
				times(1) = toc;
				features = zeros(obj.feature_size * nsubpds, nelem);
				for i = 1:nelem
					for d = 1:nsubpds
						l = (d-1)*obj.feature_size+1;
						r = d*obj.feature_size;
						features(l:r, i) = reprCell{i, d}(:)';
					end
				end
			else
				if strcmp(name, 'pi')
					reprCell = obj.predict(pds, persistenceLimits);
				else
% 					tr_pds = pds(tridx);
					obj = obj.fit(train_pds, persistenceLimits);
					reprCell = obj.predict(pds);
				end
				times(1) = toc;
				switch algorithm
					case 'linearSVM-kernel'
						tic;
						K = obj.generateKernel(reprCell);
						times(2) = toc;
					case 'linearSVM-vector'
						features = zeros(obj.feature_size, length(reprCell));
						for i = 1:size(pds, 1)
							features(:, i) = reprCell{i}(:)';
						end
				end
			end
%			save(descrPath, 'K', 'times', 'features', 'persistenceLimits');
		else
			load(descrPath);
		end

	case {'pds'}
		if ~exist(descrPath, 'file')
			% compute diagram limits 

			tic;
			if size(pds, 2) > 1
				nelem = size(pds, 1);
				% number of persistence diagrams representing an object
				nsubpds = size(pds, 2);
				% for each sub diagram do another classification
				features = zeros(obj.feature_size * nsubpds, nelem);
				for d = 1:nsubpds
					trainPoints = cat(1, train_pds{:,d});
					birthLimits = [quantile(trainPoints(:,1), 0.05), ...
						quantile(trainPoints(:,1), 0.95)];
					deathLimits = [quantile(trainPoints(:,2), 0.05), ...
						quantile(trainPoints(:,2), 0.95)];

					l = (d-1)*obj.feature_size+1;
					r = d*obj.feature_size;
					repr = obj.predict(pds(:,d), birthLimits, deathLimits);
					try
						features(l:r, :) = repr;
					catch
						disp(size(repr));
					end
				end
				times(1) = toc;
			else
				trainPoints = cat(1, train_pds{:});
				birthLimits = [quantile(trainPoints(:,1), 0.05), ...
					quantile(trainPoints(:,1), 0.95)];
				deathLimits = [quantile(trainPoints(:,2), 0.05), ...
					quantile(trainPoints(:,2), 0.95)];

				% compute diagram limits
				features = obj.predict(pds, birthLimits, deathLimits);
				times(1) = toc;
				% this is hack - modify it in the future, so that all representations
				% return the same thing
				reprNonCell = cell(1, size(features,2));
				for i = 1:size(features, 2)
				  reprNonCell{i} = features(:, i);
				end
				tic;
				K = obj.generateKernel(reprNonCell);
				times(2) = toc;
			end
%			save(descrPath, 'K', 'times', 'features', 'persistenceLimits');
		else
			load(descrPath);
		end
	end

	train_idx = 1:length(train_pds);
	test_idx = length(train_pds)+1:length(pds);
	switch algorithm
		case 'linearSVM-kernel'
			maxK = max(K(:));
			[accTest, pAccTest, confMatTest, ...
				accTrain, pAccTrain, confMatTrain, C, svm_time] = ...
				new_PD_svmclassify((maxK-K), labels, train_idx, test_idx, 'kernel');
		case 'linearSVM-vector'
			[accTest, pAccTest, confMatTest, ...
				accTrain, pAccTrain, confMatTrain, C, svm_time] = ...
				new_PD_svmclassify(features, labels, train_idx, test_idx, 'vector');
	end
	accuracy = {accTest, accTrain};
	preciseAccuracy = {pAccTest, pAccTrain};
	confMats = {confMatTest, confMatTrain};
	times(3) = svm_time(1);
	times(4) = svm_time(2);
end
