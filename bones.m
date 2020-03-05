clear;
clc;

%%

method_name = 'PFV'; % empty or PI, PBoW, PFV
k = 100;
normalized = 0; % 0 or 1
dimension = 1;

analyze_correlation = 0;
regression = 1;

%%

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
        if normalized
            pd = readtable(['/media/data2/data/bones/normalized/', pdFile]);
        else
            pd = readtable(['/media/data2/data/bones/not_normalized/', pdFile]);
        end
        pd = table2array(pd(:, 1:4));
        pd = pd(pd(:, 2) == dimension, :);
        pd = pd(:, 3:4);
        pds{i, 1} = pd;
    else
        unknown = [unknown, i];
    end
end

pds(unknown, :) = [];
labels(unknown, :) = [];
limits = [min(min(cell2mat(pds(:)))), max(max(cell2mat(pds(:))))];

%%

% Create PersistenceBow object
if strcmp(method_name, 'PI')
    method = PersistenceImage(sqrt(k), 0.1,  @linear_ramp);
elseif strcmp(method_name, 'PBoW')
    method = PersistenceBow(k, @linear_ramp);
elseif strcmp(method_name, 'PFV')
    method = PersistenceFV(k, @linear_ramp);
end

% Get PBOWs representation for all examples
if strcmp(method_name, 'PI')
    reprCell = method.predict(pds(:), limits);
elseif strcmp(method_name, 'PBoW') || strcmp(method_name, 'PFV')
    % Train PBOW
    method = method.fit(pds, limits);

    reprCell = method.predict(pds(:));
end

% Transform PBOW representation into feature vector
features = zeros(method.feature_size, length(reprCell));
for i = 1:size(features, 2)
	features(:, i) = reprCell{i}(:)';
end

if analyze_correlation
    rs = [];
    ps = [];
    for i = 1:size(features, 1)
        [r, p] = corrcoef(features(i, :)', labels);
        rs = [rs, r(1, 2)];
        ps = [ps, p(1, 2)];
    end
    rs = abs(rs);
    [rs_sorted, rs_order] = sort(rs, 'descend');

    %Y = tsne(features');
    %scatter(Y(:, 1), Y(:, 2), 25, labels, 'filled');
    figure;
    for i = 1:12
        subplot(3, 4, i);
        scatter(features(rs_order(i), :), labels, 5);
        title([num2str(rs_order(i)), ' = ', num2str(rs_sorted(i))]);
    end
end

if regression
    rng(1); % For reproducibility
    Mdl = TreeBagger(100, features', labels, 'Method', 'regression', 'OOBPrediction', 'on');
    
    YP = predict(Mdl, features');
    YoobP = oobPredict(Mdl);

    subplot(1, 2, 1);
    plot(labels, YP, 'r*')
    subplot(1, 2, 2);
    plot(labels, YoobP, 'r*')
end
