%%%%% Test for creating topological descriptors
addpath('pcontrollers');

% class labels
types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
    'Clusters within Clusters', 'Torus'};
%%%%% Load persistence dagrams
data_path = 'exp01/';
load([data_path, 'pd.mat']);
allPoints = cat(1, pds{:});
diagramLimits = [quantile(allPoints(:, 1), 0.05), ...
  quantile(allPoints(:, 2), 0.95)];

%%%%%%%%
%%%%% PERSISTENCE BOW 
% Create new Persistence BoW instance with number of clusters equal 20
pbow = PersistenceBow(20, @linear_ramp);

% compute clusters for given training persistence diagrams
% (this method also return representation vectors as cell array)
reprNonCell = pbow.train(pds(:), diagramLimits);

% compute kernel based on the vectors
% (instead of computing kernel, representation vectors can be used in any ML method)
K = pbow.generateKernel(cat(1, reprNonCell));

% in this kernel, rows (and columns) from 1-50 represents random noise,
% 51-100 circle, etc.
f = figure('visible', 'off');
imagesc(K);
print -djpeg example_pbow.jpg
close(f)

%%%%%%%%
%%%%% PERSISTENCE RIEMANIAN REPRESENTATION 
% Create new Persistence PDs instance with resolution 32, sigma 0.1 and ...
%	dimension 64
pds_obj = PersistencePds(32, 0.1, 40);

% compute clusters for given training persistence diagrams
riem_pds = pds_obj.train(pds(:), diagramLimits);

%TODO: example of an output of Riemanian representation of PD?

%%%%%%%%
%%%%% PERSISTENCE IMAGE
% Create new Persistence Image instance

% pi_obj = PersistenceImage(32, 0.01, @constant_one);
% By setting -1, default sigma is computed (half of a pixel size).
pi_obj = PersistenceImage(64, -1, @linear_ramp);

% %% Persistence images can be computed in parallel, if Parallel computing ... 
% %%	package is present.
% cluster = parcluster('local');
% workers = 4;
% cluster.NumWorkers = workers;
% saveProfile(cluster);
% pool = parpool(workers);
% pi_obj.parallel = true;

PIs = pi_obj.test(pds(:), diagramLimits);
% %% dimiss workers
% delete(pool);

save('example_PIs.mat', 'PIs');
f = figure('visible', 'off');
for i = 1:30
	subplot(6,5,i);
	image(PIs{i*10}, 'CDataMapping', 'scaled');
	% colorbar;
end
print -djpeg example_pis.jpg
close(f)

%%%%%%%%
%%%%% PD AGG
pd_agg_obj = PersistencePdAgg();

pd_aggs = pd_agg_obj.test(pds(:));

% Reshape to the original size
pd_aggs = reshape(pd_aggs, size(pds));

% acc_pd_aggs = acc_pd_agg(pd_aggs);
% Boxplot for max persistence
f = figure('visible', 'off');
boxplot(pd_agg_boxplot_data(pd_aggs, 2));
title(pd_agg_obj.labels{3});
xlabel('Class');
ylabel('Value');
print -djpeg example_pd_agg_max_boxplot.jpg
% Boxplot for mean persistence
f = figure('visible', 'off');
boxplot(pd_agg_boxplot_data(pd_aggs, 3));
title(pd_agg_obj.labels{4});
print -djpeg example_pd_agg_mean_boxplot.jpg
close(f)

function data = pd_agg_boxplot_data(pd_aggs, var)
	data = cellfun(@(c) c(var), pd_aggs);
end
