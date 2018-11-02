function [accuracy, precise_accuracy, confusion_matrix] = new_PD_svmclassify(f, labels, train_idx, test_idx, type)
%%% INPUT:
%	f 		- features, for vector svm, matrix of size [feature vector size, num of examples],
%			for kernel svm, square matrix of distances between elements
%	type 	- 'vector' or 'kernel'
%%% 

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

test_labels = labels(test_idx);

nclass = length(unique(labels));
confusion_matrix = zeros(nclass);
for i = 1:nclass
	class_i = test_labels == i;
	class_i_size = sum(class_i);
	for j = 1:nclass
		guessed_j = sum(predict_label(class_i) == j);
		confusion_matrix(i,j) = (guessed_j/class_i_size) * 100.;
	end
end

guessed = test_labels == predict_label;
precise_accuracy = zeros(1, nclass);
accuracy = 100. * sum(guessed)/length(test_idx);
for n = 1:nclass
    n_ids = labels(test_idx)==n;
    precise_accuracy(n) = sum(guessed(n_ids))/sum(n_ids);
end
precise_accuracy = precise_accuracy * 100.;
end
