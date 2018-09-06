% First experiment
function experiment03_geomat()
	addpath('pcontrollers');
	addpath('../pdsphere/matlab');
	addpath('../pdsphere/matlab/libsvm-3.21/matlab');
	
	expPath = 'exp03_geomat/';
	
	dim = 1;
	scale = '400';
	basename = strcat('pds_', num2str(dim)', '_', scale);
	
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
	diagramLimits = [quantile(allPoints(:, 1), 0.01), ...
	  quantile(allPoints(:, 2), 0.99)];
	
	algorithm = 'linearSVM'; %small
	
	N = 25;
	
	objs = {};
	objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
	objs{end + 1} = {PersistenceKernelOne(1), {'pk1', 'pk1'}};
	objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
	for a = 50:50:250
	  objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
	end
	objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};
	for r = 10:10:50
		for s = 0.05:0.05:0.25
			objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
		end
	end
	for c = 10:10:100
		objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
	end
	for c = 10:10:100
		objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
	end
	for c = 10:10:100
		objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
	end
	for r = 10:10:50
		for s = 0.05:0.05:0.25
			objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
		end
	end
	for c = 10:10:100
		objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
	end
	for c = 10:10:100
		objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
	end
	for c = 10:10:100
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
		acc = zeros(N, nclasses + 1);
		for i = 1:N
			seedBig = i * 10000;
			obj = objs{o}{1};
			prop = objs{o}{2};
			fprintf('Computing: %s\n, repetition %d\n', prop{2}, i);
			
			labels = reshape(repmat(1:nclasses, [nexamples, 1]), [nclasses*nexamples, 1]);
			
			[accuracy, preciseAccuracy, time] = compute_accuracy(obj, pds, ...
				labels, nclasses, diagramLimits, algorithm, prop{1}, ...
				strcat(basename, '_', prop{2}), expPath, seedBig);
			acc(i, :) = [accuracy, preciseAccuracy]';
		end

		fid = fopen([expPath, 'results_', num2str(dim), '_', scale, '_', ...
				algorithm, '_', prop{1}, '.txt'], 'a');
		header = repmat('%s;', [1, 23]);
		header = sprintf(header, prop{1}, 'iter', 'time', 'acc', types{:});
		fprintf(fid, '%s\n', header);

		for i = 1:N
			% type;repetition;time;accuracy;preciseAccuracy
			basicLine = sprintf(['%s;%d;%f;%f', ...
			  ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f'], ...
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
		basicLine = sprintf(['%s; ; ;%f', ...
				';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f'], ...
				prop{1}, mean(acc));
		fprintf(fid, '%s\n', basicLine);
		fclose(fid);
	end
end
