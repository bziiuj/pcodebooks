function [accuracy, preciseAccuracy, time, obj] = compute_accuracy(obj, pds, ...
	  labels, nclass, diagramLimits, algorithm, name, detailName, ...
	  expPath, seed)
	  
	kernelPath = [expPath, detailName, '.mat'];
	[tridx, teidx] = train_test_indices(labels, nclass, 0.2, seed);
	switch name
		case {'pw'}
			if ~exist(kernelPath, 'file')
			    throw(MException('Error', 'Wasserstein distance is currently not implemented'));
			else
			    load(kernelPath);
			    K = double(K);
			    time = -1;
			end
		case {'pk1', 'pk2e', 'pk2a', 'pl'}
			if ~exist(kernelPath, 'file')
				tic;
				repr = obj.train(pds(:));
			
				K = obj.generateKernel(repr);
				time = toc;
				save(kernelPath, 'K', 'time');
			else
				load(kernelPath);
			end
			% K is uppertriangular, so ...
			K = K + K';
		case {'pi', 'pbow', 'pvlad', 'pfv'}
			tic;
			
			if strcmp(name, 'pi')
				reprCell = obj.train(pds(:), diagramLimits);
			else
				tr_pds = pds(tridx);
                te_pds = pds(teidx);
                obj = obj.train(tr_pds, diagramLimits);
                reprCell = obj.test(pds(:));
			end
			K = obj.generateKernel(reprCell);
			features = zeros(obj.feature_size, length(reprCell));
			for i = 1:size(pds(:), 1)
				features(:, i) = reprCell{i}(:)';
            end
			time = toc;
		case {'pds'}
			tic;
			% compute diagram limits
			reprNonCell = obj.train(pds(:), diagramLimits);
			% this is hack - modify it in the future, so that all representations
			% return the same thing
			repr = cell(1, size(reprNonCell, 2));
			for i = 1:size(reprNonCell, 2)
			  repr{i} = reprNonCell(:, i);
			end
			K = obj.generateKernel(cat(1, repr));
			time = toc;
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
