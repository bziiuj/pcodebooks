function [accuracy_test, precise_accuracy_test, confusion_matrix_test, ...
	accuracy_train, precise_accuracy_train, confusion_matrix_train, C, times] = ...
		new_PD_svmclassify(f, labels, train_idx, test_idx, type)
%%% INPUT:
%	f 		- features, for vector svm, matrix of size [feature vector size, num of examples],
%			for kernel svm, square matrix of distances between elements
%	type 	- 'vector' or 'kernel'
%%% OUTPUT:
%	C		- svm C parameter determined by crossvalidation
%	times	- [cross-validation time, main svm time]
%

	folds = 5;
	g = 1/size(f,1);
	C = [0.1, 1, 10, 100, 1000];
	cv_acc = zeros(numel(C), 1);

	% Training with crossvalidation 
	tic;
	for i=1:numel(C)
%	for c=C
		switch type
			case 'vector'
				cv_acc(i) = svmtrain(labels(train_idx), f(:,train_idx)', ...
					['-s 0 -c ', num2str(C(i)), ' -t 0 -g ', num2str(g), ...
					' -v ', num2str(folds)]);
			case 'kernel'
				K = [(1:length(train_idx))', f(train_idx, train_idx)];
				cv_acc(i) = svmtrain(labels(train_idx), K, ...
					['-s 0 -c ', num2str(C(i)), ' -t 4 -g ', num2str(g), ...
					' -v ', num2str(folds)]);
		end
	end
	cv_time = toc;

	[~, idxC] = max(cv_acc);
	C = C(idxC);
	tic;
	% Main training
	switch type
		case 'vector'
			model = svmtrain(labels(train_idx), f(:,train_idx)', ['-s 0 -c ',num2str(C),' -t 0 -g ',num2str(g)]);
			[predict_label, accuracy, prob_values] = svmpredict(labels(test_idx), f(:,test_idx)', model);
			[predict_label_train, accuracy, prob_values] = svmpredict(labels(train_idx), f(:,train_idx)', model);
		case 'kernel'
			K = [(1:length(train_idx))', f(train_idx, train_idx)];
			KK = [(1:length(test_idx))', f(test_idx, train_idx)];
			model = svmtrain(labels(train_idx), K, ['-s 0 -c ', num2str(C),' -t 4 -g ',num2str(g)]);
			[predict_label, ~, ~] = svmpredict(labels(test_idx), KK, model);
			[predict_label_train, ~, ~] = svmpredict(labels(train_idx), K, model);
	end
	svm_time = toc;
	times = [cv_time, svm_time];

	% Confusion matrix test
	test_labels = labels(test_idx);

	nclass = length(unique(labels));
	confusion_matrix_test = zeros(nclass);
	for i = 1:nclass
		class_i = test_labels == i;
		class_i_size = sum(class_i);
		for j = 1:nclass
			guessed_j = sum(predict_label(class_i) == j);
%			confusion_matrix_test(i,j) = (guessed_j/class_i_size) * 100.;
			confusion_matrix_test(i,j) = guessed_j;
		end
	end

	% Confusion matrix train
	train_labels = labels(train_idx);

	nclass = length(unique(labels));
	confusion_matrix_train = zeros(nclass);
	for i = 1:nclass
		class_i = train_labels == i;
		class_i_size = sum(class_i);
		for j = 1:nclass
			guessed_j = sum(predict_label_train(class_i) == j);
%			confusion_matrix_train(i,j) = (guessed_j/class_i_size) * 100.;
			confusion_matrix_train(i,j) = guessed_j;
		end
	end

	% accuracy for test
	guessed = test_labels == predict_label;
	precise_accuracy_test = zeros(1, nclass);
	accuracy_test = 100. * sum(guessed)/length(test_idx);
	for n = 1:nclass
		n_ids = labels(test_idx)==n;
		precise_accuracy_test(n) = sum(guessed(n_ids))/sum(n_ids);
	end
	precise_accuracy_test = precise_accuracy_test * 100.;

	% accuracy for train
	guessed = train_labels == predict_label_train;
	precise_accuracy_train = zeros(1, nclass);
	accuracy_train = 100. * sum(guessed)/length(train_idx);
	for n = 1:nclass
		n_ids = labels(train_idx)==n;
		precise_accuracy_train(n) = sum(guessed(n_ids))/sum(n_ids);
	end
	precise_accuracy_train = precise_accuracy_train * 100.;

end
