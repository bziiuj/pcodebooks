% Simple test of Persistence Bag of Words

addpath('pcontrollers');

% load persistence diagrams
expPath = 'exp01/';
load([expPath, 'pd.mat']);
allPoints = cat(1, pds{:});
diagramLimits = [quantile(allPoints(:, 1), 0.05), ...
  quantile(allPoints(:, 2), 0.95)];

% create new Persinstence BoW instance with number of clusters equals 20
pbow = PersistenceBow(20, @linear_ramp);

% you can use those Persistence VLAD and Persistence FV instead
% pbow = PersistenceVLAD(20, @linear_ramp);
% pbow = PersistenceFV(20, @linear_ramp);


% compute clusters for given training persistence diagrams
% (this method also return representation vectors as cell array)
reprNonCell = pbow.train(pds(:), diagramLimits);

% compute kernel based on the vectors
% (instead of computing kernel, representation vectors can be used in any ML method)
K = pbow.generateKernel(cat(1, reprNonCell));

% in this kernel, rows (and columns) from 1-50 represents random noise,
% 51-100 circle, etc.
imagesc(K);
