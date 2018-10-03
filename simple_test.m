addpath('pcontrollers');
addpath('../pdsphere/matlab/libsvm-3.21/matlab');
addpath('../pdsphere/matlab');
seed = 31415;

% Load persistence diagrams
load('exp01/pd.mat');
% Number of classes
nclasses = 6;
% Number of examples in each class
nexamples = 50;
% Create labels vector
labels = reshape(repmat(1:nclasses, [nexamples, 1]), [nclasses*nexamples, 1]);

% Create PersistenceBow object
pbow = PersistenceBow(20, @linear_ramp);

% Randomly choose train and test subsets
[tridx, teidx] = train_test_indices(labels, nclasses, 0.2, seed);

tr_pds = pds(tridx);
te_pds = pds(teidx);
limits = [min(min(cell2mat(tr_pds(:)))), max(max(cell2mat(tr_pds(:))))];
% Train PBOW
pbow = pbow.fit(tr_pds, limits);

% Get PBOWs representation for all examples
reprCell = pbow.predict(pds(:));

% Transform PBOW representation into feature vector
features = zeros(pbow.feature_size, length(reprCell));
for i = 1:size(pds(:), 1)
	features(:, i) = reprCell{i}(:)';
end

% Test using SVM
[accuracy, preciseAccuracy] = new_PD_svmclassify(features, labels, ...
    tridx, teidx, 'vector');

% Print accuracy
disp(strcat('Classification accuracy: ', num2str(accuracy)));
