function [trids, teids] = train_test_indices(labels, nclass, p, seed)
	teN = zeros(nclass, 1);
	for n = 1:nclass
		teN(n) = floor(p * sum(labels==n));
		%teN = floor(p * length(labels)/nclass);
	end
	rng(seed);
	trids = [];
	teids = [];
	for n = 1:nclass
		id = find(labels == n);
		teidx = randperm(length(id),teN(n));
		tridx = id;
		tridx(teidx) = [];
		trids = [trids tridx'];
		teids = [teids id(teidx)'];
	end
end
