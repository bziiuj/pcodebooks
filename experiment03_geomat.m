% GeoMat experiment
function experiment03_geomat()
	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	
	expPath = 'exp03_geomat/';
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
	
	dim = 1;
	scale = '400';
    subset = '';
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
	
	algorithm = 'linearSVM-kernel'; %small
	
%	cluster = parcluster('local');
%	workers = 32;
%	cluster.NumWorkers = workers;
%	saveProfile(cluster);
%	pool = parpool(workers);

	N = 30;
	test_kernel = false;
	test_vector = false;
	test_pdcodebooks = true;
	test_stable_pdcodebooks = false;
	test_all = false;
	
	% PI tested resolutions and relative sigmas
	pi_r = 20:20:160;
	pi_s = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2];
	% tested codebook sizes
	bow_sizes = 10:20:150;

	objs = {};
	%%% KERNEL APPROACHES
	if test_kernel || test_all
		objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
		objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
		for a = 50:50:250
		  objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
		end
		objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};
	end
	%%% OTHER VECTORIZED APPROACHES
	if test_vector || test_all
		for r = [20, 40, 60, 80, 100]
	 %		for s = 0.1:0.1:0.3
			for s = [0.0001, 0.0005, 0.001, 0.002, 0.005, 0.01, 0.05]
				for d = 25:25:100
					objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), ...
					'_', num2str(s), '_', num2str(d)]}};
				end
			end
		end
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
	end
	%%% PERSISTENCE CODEBOOKS
	if test_pdcodebooks || test_all
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
	end
	%%% STABLE PERSISTENCE CODEBOOKS
	if test_stable_pdcodebooks || test_all
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

	for o = 1:numel(objs)
		acc = zeros(N, nclasses + 1);
		all_times = zeros(N, 2);
		obj = objs{o}{1};
		prop = objs{o}{2};
		
		for i = 1:N
			seedBig = i * 10101;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
			
			labels = reshape(repmat(1:nclasses, [nexamples, 1]), [nclasses*nexamples, 1]);
			
			[accuracy, preciseAccuracy, times, obj] = compute_accuracy(obj, pds, ...
				labels, nclasses, diagramLimits, algorithm, prop{1}, ...
				strcat(basename, '_', prop{2}), expPath, seedBig);
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

		print_results(expPath, obj, N, algorithm, sufix, types, prop, all_times, acc); 
	end
end
