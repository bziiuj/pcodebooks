% First experiment
function experiment01_svm()
	addpath('pcontrollers');
	rawPath = 'rawdata/exp01_svm/';
	expPath = 'exp01_svm/';
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	addpath('../pdsphere/matlab');
	pbowsPath = strcat(expPath, 'pbows/');
	mkdir(pbowsPath);
  
	pds = prepareDiagrams(rawPath, expPath);

	% calculate diagram limits
	allPoints = cat(1, pds{:});
	diagramLimits = [quantile(allPoints(:, 1), 0.001), ...
    quantile(allPoints(:, 2), 0.999)];

	algorithm = 'linearSVM-kernel'; %small
% 	algorithm = 'linearSVM-vector'; %small

	types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
	    'Clusters within Clusters', 'Torus'};

	N = 30;
	test_kernel = false;
	test_vector = false;
	test_pdcodebooks = true;
	test_stable_pdcodebooks = false;
	test_all = false;
    
	% PI tested resolutions and relative sigmas
	pi_r = 10:10:50;
	pi_s = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2];
	% tested codebook sizes
	bow_sizes = 10:10:100;
	
	objs = {};
	%%% KERNEL APPROACHES
	if test_kernel || test_all
		objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
		for c = [0.5, 1., 1.5]
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', ['pk1_', num2str(c)]}};
			objs{end + 1} = {PersistenceKernelOne(c), {'pk1', 'pk1'}};
		end
		objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
		for a = 50:50:250
			objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
		end
		objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};
	end
	%%% OTHER VECTORIZED APPROACHES
	if test_vector || test_all
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
		for r = [20, 40]
			for s = 0.1:0.1:0.3
				for d = 25:25:100
					objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), ...
						'_', num2str(s), '_', num2str(d)]}};
				end
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

	for o = 1:numel(objs)
		acc = zeros(N, 7);
		all_times = zeros(N, 2);
		obj = objs{o}{1};
		prop = objs{o}{2};

		for i = 1:N
			seedBig = i * 10000;
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
			
			labels = [repmat(1, [1, 50]), ...
			    repmat(2, [1, 50]), ...
			    repmat(3, [1, 50]), ...
			    repmat(4, [1, 50]), ...
			    repmat(5, [1, 50]), ...
			    repmat(6, [1, 50])]';
			[accuracy, preciseAccuracy, times, obj] = compute_accuracy(obj, pds, ...
			    labels, 6, diagramLimits, algorithm, prop{1}, prop{2}, ...
			    expPath, seedBig);
			acc(i, :) = [accuracy, preciseAccuracy]';
			all_times(i, :) = times;

% 			if strcmp(prop{1}, 'pbow')
% 				repr = obj.test(pds(:));
% 				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
% 				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
% 				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
% 			end
		end
		
		print_results(expPath, obj, N, algorithm, '', types, prop, all_times, acc);
	end
end

function pds = prepareDiagrams(rawPath, expPath)
  types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
    'Clusters within Clusters', 'Torus'};

  PLOT = 0;

  % load pds
  if ~exist([expPath, 'pd.mat'], 'file')
    pds = cell(numel(types), 50);
    for i = 2:51
      for j = 1:numel(types)
        filePath = [rawPath, 'pd_gauss_0_1/', types{j}, '/', num2str(i), '.h5.pc.simba.1.00001_3.persistence'];
        pd = importdata(filePath, ' ');
        pd(isinf(pd(:, 3)) | pd(:, 1) ~= 1, :) = [];
        pds{j, i - 1} = pd(:, 2:3);

        if PLOT
          subplot(2, 3, i - 1);
          colors = {'y*', 'm*', 'c*', 'r*', 'g*', 'b*'};
          plot(pd(:, 2), pd(:, 3), colors{j}); xlim([0, 0.22]); ylim([0, 0.22]); legend(types);
          hold on;
        end
      end
    end
    pds = pds';
    save([expPath, 'pd.mat'], 'pds');
  else
    load([expPath, 'pd.mat']);
  end
end
