function [accuracy, preciseAccuracy, times, obj] = compute_accuracy(obj, pds, ...
	  labels, nclass, diagramLimits, algorithm, name, detailName, ...
	  expPath, seed)
  %%% OUTPUT:
  %     accuracy - overall accuracy
  %     preciseAccuracy - accuracy for every class
  %     times - cell array {descriptor creation time, kernel creation time}
  %     obj   - 
	
    
	times = [-1, -1];
	kernelPath = [expPath, detailName, '.mat'];
	[tridx, teidx] = train_test_indices(labels, nclass, 0.2, seed);
	switch name
		case {'pw'}
			if ~exist(kernelPath, 'file')
			    throw(MException('Error', 'Wasserstein distance is currently not implemented'));
			else
			    load(kernelPath);
			    K = double(K);
			end
		case {'pk1', 'pk2e', 'pk2a', 'pl'}
			if ~exist(kernelPath, 'file')
				tic;
				repr = obj.train(pds(:));
			
				K = obj.generateKernel(repr);
				times(2) = toc;
				save(kernelPath, 'K', 'time');
			else
				load(kernelPath);
			end
			% K is uppertriangular, so ...
			K = K + K';
		case {'pi', 'pbow', 'pvlad', 'pfv', 'pbow_st', 'svlad'}
			tic;
			
			if strcmp(name, 'pi')
				reprCell = obj.train(pds(:), diagramLimits);
			else
				tr_pds = pds(tridx);
				te_pds = pds(teidx);
				obj = obj.train(tr_pds, diagramLimits);
				reprCell = obj.test(pds(:));
			end
			times(1) = toc;
			tic;
			K = obj.generateKernel(reprCell);
			times(2) = toc;
			features = zeros(obj.feature_size, length(reprCell));
			for i = 1:size(pds(:), 1)
				features(:, i) = reprCell{i}(:)';
            end
		case {'pds'}
			tic;
			% compute diagram limits
			reprNonCell = obj.train(pds(:), diagramLimits);
			times(1) = toc;
			% this is hack - modify it in the future, so that all representations
			% return the same thing
			features = cell(1, size(reprNonCell, 2));
			for i = 1:size(reprNonCell, 2)
			  features{i} = reprNonCell(:, i);
			end
			tic;
			K = obj.generateKernel(cat(1, features));
			times(2) = toc;
	end
	
	switch algorithm
		case 'linearSVM-kernel'
		  [accuracy, preciseAccuracy] = new_PD_svmclassify(1-K, labels, tridx, teidx, ...
		        'kernel');
		case 'linearSVM-vector'
		  [accuracy, preciseAccuracy] = new_PD_svmclassify(features, labels, tridx, teidx, ...
		        'vector');
	end
end
