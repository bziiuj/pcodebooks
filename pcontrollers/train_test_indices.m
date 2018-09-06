function [trids, teids] = train_test_indices(labels, nclass, p, seed)
%%% nex - number of examples per class
    teN = floor(p * length(labels)/nclass);
    rng(seed);
    trids = [];
    teids = [];
    for n = 1:nclass
        id = find(labels == n);
        teidx = randperm(length(id),teN);
        tridx = id;
        tridx(teidx) = [];
        trids = [trids tridx'];
        teids = [teids id(teidx)'];
    end
end