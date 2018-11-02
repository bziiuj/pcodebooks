function [accuracy, preciseAccuracy, confusion_matrix, times, obj] = compute_accuracy(obj, pds, ...
	  labels, nclass, diagramLimits, algorithm, name, detailName, ...
	  expPath, seed)
  %%% OUTPUT:
  %     accuracy - overall accuracy
  %     preciseAccuracy - accuracy for every class
  %     times - cell array {descriptor creation time, kernel creation time}
  %     obj   - 
	times = [-1, -1];
	kernelPath = [expPath, detailName, '.mat'];
	descrPath = [expPath, 'descriptors/', name, '_', obj.getSufix(), '.mat'];
	[tridx, teidx] = train_test_indices(labels, nclass, 0.2, seed);
	switch name
	case {'pw'}
		disp(kernelPath);
		if ~exist(kernelPath, 'file')
		    throw(MException('Error', 'Wasserstein distance is currently not implemented'));
		else
		    load(kernelPath);
		    K = double(K);
		end
	case {'pk1', 'pk2e', 'pk2a', 'pl'}
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
						reprCell(:,d) = obj.predict(pds(:,d), diagramLimits{d});
					else
						tr_pds = pds(tridx, d);
						obj = obj.fit(tr_pds, diagramLimits{d});
						reprCell(:,d) = obj.predict(pds(:, d));
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
					reprCell = obj.predict(pds, diagramLimits);
				else
					tr_pds = pds(tridx);
					obj = obj.fit(tr_pds, diagramLimits);
					reprCell = obj.predict(pds);
				end
				times(1) = toc;
				tic;
				K = obj.generateKernel(reprCell);
				times(2) = toc;
				features = zeros(obj.feature_size, length(reprCell));
				for i = 1:size(pds, 1)
					features(:, i) = reprCell{i}(:)';
				end
			end
			save(descrPath, 'K', 'times', 'features');
		else
			load(descrPath);
		end
	case {'pds'}
		if ~exist(descrPath, 'file')
			tic;
			if size(pds, 2) > 1
				nelem = size(pds, 1);
				% number of persistence diagrams representing an object
				nsubpds = size(pds, 2);
				% for each sub diagram do another classification
				features = zeros(obj.feature_size * nsubpds, nelem);
				for d = 1:nsubpds
					l = (d-1)*obj.feature_size+1;
					r = d*obj.feature_size;
					repr = obj.predict(pds(:,d), diagramLimits{d});
					try
						features(l:r, :) = repr;
					catch
						disp(size(repr));
					end
				end
				times(1) = toc;
	% 			for i = 1:nelem
	% 				for d = 1:nsubpds
	% 					l = (d-1)*obj.feature_size+1;
	% 					r = d*obj.feature_size;
	% 					features(l:r, i) = reprCell{i, d}(:)';
	% 				end
	% 			end
			else
				% compute diagram limits
				features = obj.predict(pds, diagramLimits);
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
			save(descrPath, 'K', 'times', 'features');
		else
			load(descrPath);
		end
	end
	
	switch algorithm
		case 'linearSVM-kernel'
		  [accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(1-K, labels, tridx, teidx, ...
		        'kernel');
		case 'linearSVM-vector'
		  [accuracy, preciseAccuracy, confusion_matrix] = new_PD_svmclassify(features, labels, tridx, teidx, ...
		        'vector');
	end
end
