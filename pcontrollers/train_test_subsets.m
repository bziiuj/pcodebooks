function [trids, teids] = train_test_subsets(labels, nclasses, ...
	trainExamples, testExamples, subsetTrain, subsetTest, seed)
%%% nex - number of examples per class
% 	trN = zeros(nclasses, 1);
% 	teN = zeros(nclasses, 1);
% 	for n = 1:nclasses
% 		trN(n) = floor(subset * sum(labels(trainExamples)==n));
% 		teN(n) = floor(subset * sum(labels(testExamples)==n));
% 	end

	train_pos = zeros(length(labels),1);
	test_pos = zeros(length(labels),1);
	train_pos(trainExamples) = 1;
	test_pos(testExamples) = 1;

	rng(seed);
	trids = [];
	teids = [];
	for n = 1:nclasses
		id = find(labels == n & train_pos);
% 		tridx = id(sort(randsample(1:length(id), trN(n))));
		tridx = id(sort(randsample(1:length(id), subsetTrain)));
		trids = [trids; tridx];

		id = find(labels == n & test_pos);
		teidx = id(sort(randsample(1:length(id), subsetTest)));
		teids = [teids; teidx];
	end
end
