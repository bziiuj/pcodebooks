addpath('pcontrollers');
addpath('../pdsphere/matlab/libsvm-3.21/matlab');
addpath('../pdsphere/matlab');
seed = 31415;

T = readtable('/media/data2/data/bones/mechanical_data.csv');
M = readtable('/media/data2/data/bones/matching.csv','Delimiter', ';');
pds = cell(length(T.subject), 1);
labels = T.apparentStrength;
unknown = [];
for i=1:length(T.subject)
    subject = T.subject{i};
    if sum(strcmp(M.name, subject)) > 0
        pdFile = M.pdFile{strcmp(M.name, subject)};
        pd = readtable(['/media/data2/data/bones/normalized/', pdFile]);
        pd = pd(:, 3:4); % possibly limit to those with specific values at the other columns
        pd = table2array(pd);
        pds{i, 1} = pd;
    else
        unknown = [unknown, i];
    end
end

pds(unknown, :) = [];
labels(unknown, :) = [];

%%

% Create PersistenceBow object
pbow = PersistenceBow(5, @linear_ramp);

% Randomly choose train and test subsets
teidx = randi(length(pds), 1, floor(length(pds) / 5));
tridx = setdiff(1:length(pds), teidx);

tr_pds = pds(tridx);
te_pds = pds(teidx);
limits = [min(min(cell2mat(tr_pds(:)))), max(max(cell2mat(tr_pds(:))))];

%%

% Train PBOW
pbow = pbow.fit(tr_pds, limits);

% Get PBOWs representation for all examples
reprCell = pbow.predict(pds(:));

% Transform PBOW representation into feature vector
features = zeros(pbow.feature_size, length(reprCell));
for i = 1:size(pds(:), 1)
	features(:, i) = reprCell{i}(:)';
end

%%

Y = tsne(features');
scatter(Y(:, 1), Y(:, 2), 25, labels, 'filled');

%%

% Test using SVM
[accuracy, preciseAccuracy] = new_PD_svmclassify(features, labels, ...
    tridx, teidx, 'vector');

% Print accuracy
disp(strcat('Classification accuracy: ', num2str(accuracy)));
