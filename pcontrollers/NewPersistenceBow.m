classdef NewPersistenceBow < PersistenceRepresentation
%%%%% PERSISTENCEBOW

	properties
		numWords
%		options
			% samplesize
			% samplingweight; 'lin', 'const', 'exp', 'pow2', 'pow3'
			% predictweight; 'lin', 'const'
			% method; 'kmeans', 'wkmeans'
			% norm
			% scale
			% gridsize
		% normalization options: limits and scale of training data
		persLimits
		birthLimits
		range
		kdwords
		kdtree
		% for wkmeans
		wkmeansWeights
		% for hierarchical clustering
		sample
		clusters		
	end
 
	methods
		function obj = NewPersistenceBow(numWords, varargin)
			obj = obj@PersistenceRepresentation();

			obj.numWords = numWords;
			obj.feature_size = obj.numWords;
			
			obj.options = struct('samplesize', 10000, ...
				'samplingweight', 'const', ...
				'predictweight', 'const', ...
				'method', 'kmeans', ...
				'norm', true, 'scale', [1 1], ...
				'gridsize', 1, 'kmeansweight', 'lin');
			obj.options = named_options(obj.options, varargin{:});
		end

		function setup(obj)
			setup@PersistenceRepresentation(obj);
			pbow_path = which('PersistenceBow');
			[filepath, ~, ~] = fileparts(pbow_path);
			run(strcat(filepath,'/../../vlfeat/toolbox/vl_setup'))
			addpath(strcat(filepath,'/../../vlfeat/toolbox'))
			addpath(strcat(filepath,'/../../vlfeat/toolbox/misc'))
			addpath(strcat(filepath,'/../../vlfeat/toolbox/mex'))
			if ismac
			  addpath(strcat(filepath,'/../../vlfeat/toolbox/mex/mexmaci64'))
			elseif isunix
			  addpath(strcat(filepath,'/../../vlfeat/toolbox/mex/mexa64'))
			end
		end
		
		function sufix = getSufix(obj)
			sufix = ['c', num2str(obj.numWords), '-', ...
				obj.options.samplingweight, '-', ...
				obj.options.predictweight, '-', ...
				obj.options.method, '-', ...
				num2str(obj.options.gridsize), 'x', num2str(obj.options.gridsize), '-',...
				iif(obj.options.norm, 'norm', 'nonorm')	];
		end

		function [samplePointsPersist, obj] = getSample(obj, diagrams)
			allPoints = cat(1, diagrams{:});
			%%% transform points from [birth, death] to [birth, persistence]
			allBPpoints = [allPoints(:, 1), allPoints(:, 2) - allPoints(:, 1)];
			%%% compute birth and persistence Limits
			obj.birthLimits = [min(allBPpoints(:,1)), max(allBPpoints(:,1))];
% 			obj.persLimits = [quantile(allBPpoints(:,2), 0.01), max(allBPpoints(:,2))];
			obj.persLimits =  [min(allBPpoints(:,2)), max(allBPpoints(:,2))];
% 			obj.birthLimits = [quantile(allBPpoints(:,1), 0.001), quantile(allBPpoints(:,1), 0.999)]; 
			
			%%% remove outlayers from a sample
% 			allBPpoints = allBPpoints(allBPpoints(:,2) >= obj.persLimits(1) & allBPpoints(:,2) <= obj.persLimits(2),:);
% 			allBPpoints = allBPpoints(allBPpoints(:,1) >= obj.birthLimits(1) & allBPpoints(:,1) <= obj.birthLimits(2),:);

% 			obj.range = [1, 1];
% 			obj.range = [obj.birthLimits(2) - obj.birthLimits(1), obj.persLimits(2) - obj.persLimits(1)];
			obj.range = [obj.birthLimits(2) - obj.birthLimits(1), obj.persLimits(2) - obj.persLimits(1)];

			
			% normalize sample, i.e. fit it into the square [0, 1]x[0, 1]
			if obj.options.norm
					allBPpoints = allBPpoints - [obj.birthLimits(1), obj.persLimits(1)];
				allBPpoints = allBPpoints ./ obj.range;
				allBPpoints = allBPpoints .* obj.options.scale;
			end

% 			if length(allBPpoints) > obj.options.samplesize
			switch obj.options.samplingweight
				case 'const'
					weights = ones(length(allBPpoints),1);
				case 'lin'
					weights = allBPpoints(:,2);
					weights = weights / obj.range(2);
					weights = weights * obj.options.scale(2);
				case 'exp'
					weights = exp(allBPpoints(:,2));
					weights = weights / sum(weights);
				case 'pow2'
					weights = power(allBPpoints(:,2), 2);
					weights = weights / sum(weights);
				case 'pow3'
					weights = power(allBPpoints(:,2), 3);
					weights = weights / sum(weights);
				otherwise
					error('Not supported function');
			end
% 			end

			gN = obj.options.gridsize;
			gridpoints = cell(gN, gN);
			grank = cell(gN, gN);
			samplePointsPersist = zeros(obj.options.samplesize, 2);
			if obj.options.norm
				gx = linspace(0, obj.options.scale(1), gN+1);
				gy = linspace(0, obj.options.scale(2), gN+1);
			else
				gx = linspace(obj.birthLimits(1), obj.birthLimits(2), gN+1);
				gy = linspace(obj.persLimits(1), obj.persLimits(2), gN+1);
			end
			for i = 1:gN
				for j = 1:gN
					gpidxs = allBPpoints(:,1) >= gx(i) & allBPpoints(:,1) <= gx(i+1) & ...
						allBPpoints(:,2) >= gy(j) & allBPpoints(:,2) <= gy(j+1);
					gridpoints{i, j} = allBPpoints(gpidxs, :);
					grank{i,j} = randsample(1:size(gridpoints{i, j}, 1), ...
							size(gridpoints{i, j}, 1), true, weights(gpidxs));
				end
			end
			
			s = 1;
			k = 1;
			while true
				for i = 1:gN
					for j = 1:gN
						if length(grank{i, j}) >= k
							samplePointsPersist(s, :) = gridpoints{i,j}(grank{i,j}(k), :);
							s = s+1;
						end
						if s == obj.options.samplesize
							return;
						end
					end
				end
				k = k+1;
			end

% 			samples = cell(gN, gN);
% 			for i = 1:gN
% 				for j = 1:gN
% 					subidxs = allBPpoints(:,1) >= gx(i) & allBPpoints(:,1) <= gx(i+1) & ...
% 						allBPpoints(:,2) >= gy(j) & allBPpoints(:,2) <= gy(j+1);
% 					subsample = allBPpoints(subidxs,:);
% 					if length(subsample) > obj.options.samplesize
% 						samples{i,j} = subsample(randsample(1:size(subsample, 1), ...
% 							obj.options.samplesize, true, weights(subidxs)), :);
% 					else
% 						samples{i,j} = subsample;
% 					end
% 				end
% 			end
% 			samplePointsPersist = cat(1, samples{:});

% 			if length(allBPpoints) > obj.sampleSize
% 				if strcmp(func2str(obj.weightingFunction), 'linear_ramp')
% 					weights = allBPpoints(:,2);
% 					weights = weights/obj.scale(2);
% 	% 				weights = weights / sum(weights);
% 					samplePointsPersist = allBPpoints(randsample(1:size(allBPpoints, 1), obj.sampleSize, true, weights), :);
% 				elseif strcmp(func2str(obj.weightingFunction), 'exp')
% 					weights = exp(allBPpoints(:,2));
% % 					weights = weights/obj.scale(2);
% 					weights = weights / sum(weights);
% 					samplePointsPersist = allBPpoints(randsample(1:size(allBPpoints, 1), obj.sampleSize, true, weights), :);
% 				elseif strcmp(func2str(obj.weightingFunction), 'constant_one')
% 					samplePointsPersist = allBPpoints(randsample(1:size(allBPpoints, 1), obj.sampleSize), :);
% 				else
% 					error('Not supported function');
% 				end
% 			else
% 				samplePointsPersist = allBPpoints;
% 			end
		end

		function obj = fit(obj, diagrams)
			disp('Fitting New Persistence BoW');

			[sampleBpPoints, obj] = obj.getSample(diagrams);
			obj.sample = sampleBpPoints;

			tic;
			switch obj.options.method
				case 'kmeans'
					obj.kdwords = vl_kmeans(sampleBpPoints', obj.numWords, ...
					  'verbose', 'algorithm', 'ann', 'initialization', 'plusplus') ;
				case 'wkmeans'
					[~, obj.kdwords] = weighted_kmeans(sampleBpPoints, ...
						obj.numWords, 'wf', obj.options.kmeansweight);
					obj.kdwords = obj.kdwords';
				case 'pkmeans'
					[~, obj.kdwords] = persistence_kmeans(sampleBpPoints, obj.numWords-1);
					obj.kdwords = obj.kdwords';
				case 'wpkmeans'
					[~, obj.kdwords] = weighted_persistence_kmeans(sampleBpPoints, obj.numWords-1);
					obj.kdwords = obj.kdwords';
				case 'hier_avg'
					dend = linkage(sampleBpPoints, 'weighted');
					obj.sample  = sampleBpPoints;
					obj.clusters = cluster(dend, 'maxclust', obj.numWords);
					return
			end
			obj.kdtree = vl_kdtreebuild(obj.kdwords, 'numTrees', 2) ;
% 			disp(strcat('4: ', num2str(toc)))
		end

		function repr = predict(obj, diagrams)
			
			repr = cell(numel(diagrams), 1);
			for i = 1:numel(diagrams)
				if isempty(diagrams{i})
					z = zeros(obj.numWords, 1); 
				else
					% prepare diagrams
					ndiag = obj.prepare_diagram(diagrams{i});
% 					[diagrams{i}(:, 1), diagrams{i}(:, 2) - diagrams{i}(:, 1)];
% 					if obj.options.norm
% 						ndiag = ndiag - [obj.birthLimits(1), obj.persLimits(1)];
% 						ndiag = ndiag ./ obj.range;
% 						ndiag = ndiag .* obj.scale;
% 					end

					switch obj.options.method
						case {'pkmeans', 'wpkmeans'}
							words = obj.pers_query(ndiag);
						case {'kmeans', 'wkmeans'}
							[words, ~] = vl_kdtreequery(obj.kdtree, obj.kdwords, ...
								ndiag', 'MaxComparisons', 100);
						case {'hier_avg'}
							words = obj.hier_query(ndiag);
					end
					
					% count words using weights or not
					switch obj.options.predictweight
						case 'const'
							z = vl_binsum(zeros(obj.numWords, 1), 1, double(words));
						case 'lin'
							z = zeros(obj.numWords, 1);
% 							weights = obj.options.predictweight(ndiag, [0 1]);
							if obj.options.norm
								weights = ndiag(:,2)/(obj.options.scale(2));
							else
								weights = (ndiag(:,2)-obj.persLimits(1))/(obj.persLimits(2)-obj.persLimits(1));
							end
							weights = min(max(weights, 0),1);
							for x = 1:length(words)
								z(words(x)) = z(words(x)) + weights(x);
							end
						case 'pow2'
							z = zeros(obj.numWords, 1);
							weights = power(ndiag(:,2), 2);
							for x = 1:length(words)
								z(words(x)) = z(words(x)) + weights(x);
							end
						otherwise
							error('Not supported weight function');
					end
% 					if ~isempty(obj.options.predictWeight) ...
% 						&& ~strcmp(func2str(obj.options.predictWeight), 'constant_one')
% 						z = zeros(obj.numWords, 1);
% 						weights = obj.options.predictWeight(ndiag, [0 1]);
% 						for x = 1:length(words)
% 							z(words(x)) = z(words(x)) + weights(x);
% 						end
% 					else
% 						z = vl_binsum(zeros(obj.numWords, 1), 1, double(words));
% 					end
					% normalize codebook
					z = sign(z) .* sqrt(abs(z));
					z = bsxfun(@times, z, 1./max(1e-12, sqrt(sum(z .^ 2))));
				end
				repr{i} = z;
			end
		end
		
		function words = pers_query(obj, points)
			words = zeros(length(points),1);
			dist = zeros(length(points), obj.numWords);
			dist(:, obj.numWords) = points(:,2);
			for i = 1:length(points)
				dist(i,1:(obj.numWords-1)) = sum((obj.kdwords'-points(i,:)).^2, 2);
				[~, l] = min(dist(i,:));
				words(i) = l;
			end
		end
		
		function words = hier_query(obj, points)
			words = zeros(length(points),1);
			dist = zeros(length(points), length(obj.clusters));
			for i = 1:length(points)
				dist(i,:) = sum((obj.sample-points(i,:)).^2, 2);
				[~, l] = min(dist(i,:));
				words(i) = obj.clusters(l);
			end
		end
		
		function show_pcodebook(obj, diagrams)
			data = obj.prepare_diagram(cat(1, diagrams{:}));
			[labels, ~] = vl_kdtreequery(obj.kdtree, obj.kdwords, ...
						data', 'MaxComparisons', 100);
			sz = 6;
% 			figure;
			scatter(data(:,1), data(:,2), sz, labels', 'filled');
			hold on;
			scatter(obj.kdwords(1,:), obj.kdwords(2,:), sz*10, 1:length(obj.kdwords), 'filled');
			voronoi(obj.kdwords(1,:),obj. kdwords(2,:))
		end
		
		
% 		function pbow = saveobj(obj)
% 			pbow.numWords = obj.numWords;
% 			pbow.options.weightingFunction = obj.options.weightingFunction;
% 			pbow.options.sampleSize = obj.options.sampleSize;
% 			pbow.kdwords = obj.kdwords;
% 			pbow.kdtree = obj.kdtree;
% 		end
		
		function ndiag = prepare_diagram(obj, diagram)
			ndiag = [diagram(:, 1), diagram(:, 2) - diagram(:, 1)];
			if obj.options.norm
				ndiag = ndiag - [obj.birthLimits(1), obj.persLimits(1)];
				ndiag = ndiag ./ obj.range;
				ndiag = ndiag .* obj.options.scale;
			end
		end
		
		function limits = get_pd_limits(obj)
			if obj.options.norm
				limits = [0 obj.options.scale(1) 0 obj.options.scale(2)];
			else
				limits = [pbow.birthLimits pbow.persLimits];
			end
		end

	end %methods
 
	methods (Static)

		function obj = loadobj(pbow)
			obj = PersistenceBow(pbow.numWords, pbow.options.samplingweight, pbow.options.samplesize);
			obj.kdwords = pbow.kdwords;
			obj.kdtree = pbow.kdtree;
		end

	end %methods (Static)
end %classdef
