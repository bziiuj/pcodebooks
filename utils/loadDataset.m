function [types, pds, labels] = loadDataset(dataset)
	switch dataset
		case 'synthetic'
			types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
				'Clusters within Clusters', 'Torus', 'Random Cloud 2D'};
			labels = arrayfun(@(x) ones(50, 1)*x, 1:7, 'UniformOutput', false);
			labels = cat(1,labels{:});
			pds = prepareDiagrams('rawdata/exp01_synthetic/', 'exp01_synthetic/', types);
			pds = reshape(pds, 50*7, 1);
		case 'geomat'
			types = {'Asphalt', 'Brick', 'Cement - Granular', 'Cement - Smooth', ...
					'Concrete - Cast-in-Place', 'Concrete - Precast', 'Foliage', ...
					'Grass', 'Gravel', 'Marble', 'Metal - Grills', 'Paving', ...
					'Soil - Compact', 'Soil - Dirt and Vegetation', 'Soil - Loose', ...
					'Soil - Mulch', 'Stone - Granular', 'Stone - Limestone', 'Wood'};

			pds = load(['exp03_geomat/', 'exp03_pds.mat'], 'pds');
			pds = pds.pds;
			pds = reshape(cat(1, pds{:})', 600*19, 1);
			labels = arrayfun(@(x) ones(600, 1)*x, 1:19, 'UniformOutput', false);
			labels = cat(1,labels{:});
		case '3Dseg'
			load(['exp07_3Dseg/', 'exp07_pds.mat'], 'pds');
			load(['exp07_3Dseg/', 'exp07_pds.mat'], 'labels');
			pds = pds';
			labels = labels + 1;
			types = string(unique(labels));
		case 'motion'
			load(['exp02_motion/', 'pds_motion', '.mat'], 'pds');
			load(['exp02_motion/', 'pds_motion', '.mat'], 'labels');
% 			pds = pds';
			types = unique(labels);
			tmp = cell(158, 1);
			for i = 1:158
				tmp{i} = cat(1, pds{i,:});
			end
			pds = tmp;
		case 'petro'
			% labels preparation
			labels = zeros(26*300*2, 1);
			sample = 300;
			for s = 1:26
				l = sample*2*(s-1)+1;
				r = l + sample*2-1;
				labels(l:r) = [zeros(sample, 1); ones(sample, 1)];
			end
			types = unique(labels);
			
			% load diagrams and move them, so all points has positive values
			repetition = '2';
			load(['exp04_petroglyphs/', 'pds_petroglyphs', '_s300_rep', repetition,'.mat'], 'pds');
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
		otherwise
			disp('unknown dataset')
			types = {}
			pds = []
			labels = []
	end
end

% function fca = flattenCellArrays(ca)
% 	fca = {}
% 	i = 1
% 	for j = length(ca)
% 		for k = length
% 			fca{i} = ca{
% 		end
% 	end
% end

function pds = prepareDiagrams(rawPath, expPath, types)
	PLOT = 0;

	pdfilename = 'exp01_pds.mat';
	% load pds
	if ~exist([expPath, pdfilename], 'file')
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
		save([expPath, pdfilename], 'pds');
	else
		load([expPath, pdfilename]);
	end
end