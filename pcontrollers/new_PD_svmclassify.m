function [accuracy, preciseAccuracy] = new_PD_svmclassify(f, labels, train_idx, test_idx, type)
%%% type - 'vector' or 'kernel'

g = 1/size(f,1);
C = 1e1;
switch type
    case 'vector'
        model = svmtrain(labels(train_idx), f(:,train_idx)', ['-s 0 -c ',num2str(C),' -t 0 -g ',num2str(g)]);
        [predict_label, accuracy, prob_values] = svmpredict(labels(test_idx), f(:,test_idx)', model);
    case 'kernel'
        K = [(1:length(train_idx))', f(train_idx, train_idx)];
        KK = [(1:length(test_idx))', f(test_idx, train_idx)];
        model = svmtrain(labels(train_idx), K, ['-s 0 -c ',num2str(C),' -t 4 -g ',num2str(g)]);
        [predict_label, accuracy, prob_values] = svmpredict(labels(test_idx), KK, model);
end

guessed = labels(test_idx) == predict_label;

nclass = length(unique(labels));

preciseAccuracy = zeros(1, nclass);
accuracy = 100. * sum(guessed)/length(test_idx);
for n = 1:nclass
    n_ids = labels(test_idx)==n;
    preciseAccuracy(n) = sum(guessed(n_ids))/sum(n_ids);
end
preciseAccuracy = preciseAccuracy * 100.;
end
