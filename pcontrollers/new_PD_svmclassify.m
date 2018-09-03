function svmscore = new_PD_svmclassify(f, Label, type)
%%% type - 'vector' or 'kernel'

nClass = length(unique(Label));

teN = 5;
teN = floor(0.2 * length(f)/nClass);

for k = 1:100
    rng(k);
    trids = [];
    teids = [];
    for n = 1:nClass
        id = find(Label==n);
        teidx = randperm(length(id),teN);
        tridx = id;
        tridx(teidx) = [];
        trids = [trids tridx'];
        teids = [teids id(teidx)'];
    end
    
    g = 1/size(f,1);
    C = 1e1;
    switch type
        case 'vector'
            model = svmtrain(Label(trids), f(:,trids)', ['-s 0 -c ',num2str(C),' -t 0 -g ',num2str(g)]);
            [predict_label, accuracy, prob_values] = svmpredict(Label(teids), f(:,teids)', model);
        case 'kernel'
            K = [(1:length(trids))', f(trids, trids)];
            KK = [(1:length(teids))', f(teids, trids)];
            model = svmtrain(Label(trids), K, ['-s 0 -c ',num2str(C),' -t 4 -g ',num2str(g)]);
            [predict_label, accuracy, prob_values] = svmpredict(Label(teids), KK, model);
    end
    svmscore(k) = accuracy(1);
end
end