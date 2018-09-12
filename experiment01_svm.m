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

	N = 25;
    
	types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
	    'Clusters within Clusters', 'Torus'};
	
	objs = {};
	objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
    for c = [0.5, 1., 1.5]
        objs{end + 1} = {PersistenceKernelOne(c), {'pk1', ['pk1_', num2str(c)]}};
%         objs{end + 1} = {PersistenceKernelOne(c), {'pk1', 'pk1'}};
    end
	objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
	for a = 50:50:250
		objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
	end
	objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};
	for r = 10:10:20
		for s = 0.05:0.05:0.10
	for r = 10:10:50
		for s = 0.05:0.05:0.25
			objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
		end
	end
	for c = 10:10:50
		objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
	end
	for c = 10:10:50
		objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
	end
	for c = 10:10:50
		objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
	end
	for r = 10:10:50
		for s = 0.05:0.05:0.25
			objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
		end
	end
	for c = 10:10:50
		objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
	end
	for c = 10:10:50
		objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
	end
	for c = 10:10:50
		objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
	end
	for r = [20, 40]
		for s = 0.1:0.1:0.3
			for d = 25:25:100
				objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), ...
					'_', num2str(s), '_', num2str(d)]}};
			end
		end
	end

	for o = 1:numel(objs)
		acc = zeros(N, 7);
		for i = 1:N
			seedBig = i * 10000;
			obj = objs{o}{1};
			prop = objs{o}{2};
			fprintf('Computing: %s\t, repetition %d\n', prop{2}, i);
			
			labels = [repmat(1, [1, 50]), ...
			    repmat(2, [1, 50]), ...
			    repmat(3, [1, 50]), ...
			    repmat(4, [1, 50]), ...
			    repmat(5, [1, 50]), ...
			    repmat(6, [1, 50])]';
			[accuracy, preciseAccuracy, time, obj] = compute_accuracy(obj, pds, ...
			    labels, 6, diagramLimits, algorithm, prop{1}, prop{2}, ...
			    expPath, seedBig);
			acc(i, :) = [accuracy, preciseAccuracy]';

% 			if strcmp(prop{1}, 'pbow')
% 				repr = obj.test(pds(:));
% 				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_book.mat'), 'obj');
% 				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_data.mat'), 'repr');
% 				save(strcat(pbowsPath, prop{2}, '_', char(obj.weightingFunction), '_', num2str(i), '_lbls.mat'), 'labels');
% 			end
		end
		
		fid = fopen([expPath, 'results_', algorithm, '_', prop{1}, '.txt'], 'a');
		basicLine = sprintf(['%s;%s;%s;%s', ...
		        ';%s;%s;%s;%s;%s;%s'], ...
		    prop{1}, 'iter', 'time', 'acc', types{1}, types{2}, types{3}, ...
		    types{4}, types{5}, types{6});
		fprintf(fid, '%s\n', basicLine);
		
		for i = 1:N
			% type;repetition;time;accuracy;preciseAccuracy
			  basicLine = sprintf(['%s;%d;%f;%f', ...
			      ';%f;%f;%f;%f;%f;%f'], ...
			  prop{1}, i, time, acc(i,:));
			
			switch prop{1}
				case {'pw', 'pk1'}
				  % basicLine
				  fprintf(fid, '%s\n', basicLine);
				case {'pk2e', 'pk2a'}
				  % basicLine;exact;n
				  fprintf(fid, '%s;%d;%d\n', basicLine, obj.exact, obj.n);
				case 'pl'
				  % basicLine
				  fprintf(fid, '%s\n', basicLine);
				case 'pi'
				  % basicLine;resolution;sigma;weightingFunction
				  f = functions(obj.weightingFunction);
				  fprintf(fid, '%s;%d;%f;%s\n', basicLine, obj.resolution, obj.sigma, ...
				    f.function);
				case {'pbow', 'pvlad', 'pfv'}
				  f = functions(obj.weightingFunction);
				  % basicLine;numWords;weightingFunction
				  fprintf(fid, '%s;%d;%s\n', basicLine, obj.numWords, ...
				    f.function);
				case 'pds'
				  % basicLine;resolution;sigma;dim
				  fprintf(fid, '%s;%d;%f;%d\n', basicLine, obj.resolution, obj.sigma, ...
				    obj.dim);
				otherwise
				  throw(MException('Error', 'Representation is not saved'));
			end
		end
		basicLine = sprintf(['%s;std:;%f;%f', ...
		        ';%f;%f;%f;%f;%f;%f'], ...
		    prop{1}, std(acc(:,1)), mean(acc));
		fprintf(fid, '%s\n', basicLine);
		
		fclose(fid);
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
