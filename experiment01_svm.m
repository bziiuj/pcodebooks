% First experiment
function experiment01_svm()
  addpath('pcontrollers');

  rawPath = 'rawdata/exp01_svm/';
  expPath = 'exp01_svm/';
  
  pds = prepareDiagrams(rawPath, expPath);

  % calculate diagram limits
  allPoints = cat(1, pds{:});
  diagramLimits = [quantile(allPoints(:, 1), 0.0001), ...
    quantile(allPoints(:, 2), 0.9999)];

%   algorithm = 'pam'; %small
  algorithm = 'linearSVM'; %small

  N = 10;

  for i = 1:N
    fprintf('repetition %d\n', i);

    seedBig = i * 10000;

    objs = {};
%     objs{end + 1} = {PersistenceWasserstein(2), {'pw', 'pw'}};
%    objs{end + 1} = {PersistenceKernelOne(1), {'pk1', 'pk1'}};
%    objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
%    for a = 50:50:250
%      objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
%    end
%    objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};
%     for r = 10:10:50
% %     for r = 10:10:20
% %      for s = 0.05:0.05:0.10
%       for s = 0.05:0.05:0.25
%         objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
%       end
%     end
    for c = 10:10:50
      objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
    end
%    for c = 10:10:50
%      objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
%    end
   for c = 10:10:50
     objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
   end
%    for r = 10:10:50
%      for s = 0.05:0.05:0.25
%        objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
%      end
%    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
    end
%    for c = 10:10:50
%      objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
%    end
   for c = 10:10:50
     objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
   end
%    for r = [20, 40]
%      for s = 0.1:0.1:0.3
%        for d = 25:25:100
%          objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), ...
%            '_', num2str(s), '_', num2str(d)]}};
%        end
%      end
%    end

    for o = 1:numel(objs)
      obj = objs{o}{1};
      prop = objs{o}{2};

      fprintf('Computing: %s\n', prop{2});

      
    labels = [repmat(1, [1, 50]), ...
            repmat(2, [1, 50]), ...
            repmat(3, [1, 50]), ...
            repmat(4, [1, 50]), ...
            repmat(5, [1, 50]), ...
            repmat(6, [1, 50])]';
%       [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, diagramLimits, ...
%         algorithm, expPath, prop{1}, prop{2}, seedBig);
      [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, labels, ...
          diagramLimits, algorithm, prop{1}, prop{2}, expPath);

      fid = fopen([expPath, 'results_', algorithm, '_', prop{1}, '.txt'], 'a');
      % type;repetition;time;accuracy;preciseAccuracy
%       basicLine = sprintf('%s;%d;%f;%f;%f;%f;%f;%f;%f;%f', ...
%         prop{1}, i, time, accuracy, preciseAccuracy);
      basicLine = sprintf(['%s;%d;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f'], ...
        prop{1}, i, time, accuracy, preciseAccuracy);
    
      switch prop{1}
        case {'pw', 'pk1'}
          % basicLine
          fprintf(fid, '%s\n', basicLine);
        case {'pk2e', 'pk2a'}
          % basicLine;exact;n
          fprintf(fid, '%s;%d;%d\n', basicLine, obj.exact, obj.n);
        case 'pl'
          % basicLine
          fprintf(fid, '%s\n', basicLine);
        case 'pi'
          % basicLine;resolution;sigma;weightingFunction
          f = functions(obj.weightingFunction);
          fprintf(fid, '%s;%d;%f;%s\n', basicLine, obj.resolution, obj.sigma, ...
            f.function);
        case {'pbow', 'pvlad', 'pfv'}
          f = functions(obj.weightingFunction);
          % basicLine;numWords;weightingFunction
          fprintf(fid, '%s;%d;%s\n', basicLine, obj.numWords, ...
            f.function);
        case 'pds'
          % basicLine;resolution;sigma;dim
          fprintf(fid, '%s;%d;%f;%d\n', basicLine, obj.resolution, obj.sigma, ...
            obj.dim);
        otherwise
          throw(MException('Error', 'Representation is not saved'));
      end
      fclose(fid);
    end
  end
end

function pds = prepareDiagrams(rawPath, expPath)
  types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
    'Clusters within Clusters', 'Torus'};

  PLOT = 0;

  % load pds
  if ~exist([expPath, 'pd.mat'], 'file')
    pds = cell(numel(types), 50);
    for i = 2:51
      for j = 1:numel(types)
        filePath = [rawPath, 'pd_gauss_0_1/', types{j}, '/', num2str(i), '.h5.pc.simba.1.00001_3.persistence'];
        pd = importdata(filePath, ' ');
        pd(isinf(pd(:, 3)) | pd(:, 1) ~= 1, :) = [];
        pds{j, i - 1} = pd(:, 2:3);

        if PLOT
          subplot(2, 3, i - 1);
          colors = {'y*', 'm*', 'c*', 'r*', 'g*', 'b*'};
          plot(pd(:, 2), pd(:, 3), colors{j}); xlim([0, 0.22]); ylim([0, 0.22]); legend(types);
          hold on;
        end
      end
    end
    pds = pds';
    save([expPath, 'pd.mat'], 'pds');
  else
    load([expPath, 'pd.mat']);
  end
end

function [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, labels, ...
    diagramLimits, algorithm, name, detailName, expPath)
    
  kernelPath = [expPath, detailName, '.mat'];
  switch name
    case {'pw'}
        if ~exist(kernelPath, 'file')
            throw(MException('Error', 'Wasserstein distance is currently not implemented'));
        else
            load(kernelPath);
            time = -1;
        end
    case {'pi', 'pbow', 'pvlad', 'pfv'}
        tic;
        if strcmp(name, 'pi')
          repr = obj.train(pds(:), diagramLimits);
        else
          obj = obj.train(pds(:), diagramLimits);
          repr = obj.test(pds(:));
        end
        K = obj.generateKernel(repr);
        features = zeros(obj.feature_size, length(repr));
        for i = 1:size(pds(:), 1)
            features(:, i) = repr{i}(:)';
        end
%       reprCell = cell(size(pds, 1), size(pds, 2));
%       for i = 1:size(pds, 2)
%         reprCell(:, i) = obj.train(pds(:, i), diagramLimits{i});
%         for j = 1:size(reprCell, 1)
%           reprCell{j, i} = reprCell{j, i}(:);
%         end
%       end
%       repr = zeros(size(reprCell, 2) * numel(reprCell{1, 1}), size(reprCell, 1));
%       for i = 1:size(pds, 1)
%         repr(:, i) = cat(1, reprCell{i, :});
%       end
      time = toc;
    case {'pds'}
      tic;
      % compute diagram limits
      allDiagramLimits = cat(1, diagramLimits{:});
      diagramLimits = [min(allDiagramLimits(:, 1)), max(allDiagramLimits(:, 2))];
      repr = obj.train(pds, diagramLimits);
      time = toc;
  end

  switch algorithm
    case 'linearSVM'
%      preciseAccuracy = new_PD_svmclassify(features, labels, 'kernel');
      preciseAccuracy = new_PD_svmclassify(1-K, labels, 'kernel');
  end
  accuracy = mean(preciseAccuracy);
end


% function [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, diagramLimits, ...
%   algorithm, expPath, name, detailName, seedBig)
%   kernelPath = [expPath, detailName, '.mat'];
% 
%   switch name
%     case {'pw'}
% 	%return;
%    if ~exist(kernelPath, 'file')
% %	[~, repr] = obj.train(pds(:));
% %	K = obj.generateKernel(repr);
% %	save(kernelPath, 'K');
%     throw(MException('Error', 'Wasserstein distance is currently not implemented'));
%    else
%      load(kernelPath);
%      time = -1;
%    end
%     case {'pk1', 'pk2e', 'pk2a', 'pl', 'pi'}
%       if ~exist(kernelPath, 'file')
%         tic;
%         if strcmp(name, 'pi')
%           repr = obj.train(pds(:), diagramLimits);
%         else
%           repr = obj.train(pds(:));
%         end
%         K = obj.generateKernel(repr);
%         time = toc;
%         save(kernelPath, 'K', 'time');
%       else
%         load(kernelPath);
%       end
%     case {'pbow', 'pvlad', 'pfv'}
%       tic;
%       reprNonCell = obj.train(pds(:), diagramLimits);
%       % this is hack - modify it in the future, so that all representations
%       % return the same thing
%       repr = cell(1, size(reprNonCell, 2));
%       for i = 1:size(reprNonCell, 2)
%         repr{i} = reprNonCell(:, i);
%       end
%       K = obj.generateKernel(cat(1, repr{:}));
%       time = toc;
%     otherwise
%       tic;
%       reprNonCell = obj.train(pds(:), diagramLimits);
%       % this is hack - modify it in the future, so that all representations
%       % return the same thing
%       repr = cell(1, size(reprNonCell, 2));
%       for i = 1:size(reprNonCell, 2)
%         repr{i} = reprNonCell(:, i);
%       end
%       K = obj.generateKernel(cat(1, repr));
%       time = toc;
%   end
% 
%   [accuracy, preciseAccuracy] = computeAccuracyK(K, algorithm, seedBig);
% end
% 
% function [accuracy, preciseAccuracy] = computeAccuracyK(K, algorithm, seedBig)
%   rng(seedBig);
% 
%   K = max(K, K');
% 
%   clusterIndices = [repmat(1, [1, 50]), ...
%     repmat(2, [1, 50]), ...
%     repmat(3, [1, 50]), ...
%     repmat(4, [1, 50]), ...
%     repmat(5, [1, 50]), ...
%     repmat(6, [1, 50])]';
% 
%   function d = functionK(i, j)
%     d = K(i, j);
%   end
% 
%   [idx, ~, ~, ~, midx] = kmedoids((1:300)', 6, ...
%     'Distance', @functionK, ...
%     'Replicates', 100, ...
%     'Start', 'sample', ...
%     'Algorithm', algorithm);
%   newIdx = idx;
%     
%   for i = 1:6
%     isIndex = idx(midx(i));
% %    shouldBeIndex = clusterIndices(midx(i));
%     shouldBeIndex = mode(clusterIndices(idx==isIndex));
% %    disp([isIndex shouldBeIndex])
%     newIdx(idx == isIndex) = shouldBeIndex;
%   end
% 
%   m = zeros(6,6);
%   s = zeros(1,6);
%   for i = 1:6
%         s(i) = sum(idx == i);
%   end
%   for i = 1:6
%       for j = 1:6
%           m(i,j) = sum(idx(clusterIndices == i) == j);
%       end
%   end
%   disp(s);
%   disp(m);
%   
%   accuracy = sum(newIdx == clusterIndices) / 300;
%   preciseAccuracy = [sum(newIdx(clusterIndices==1) == 1), ...
%     sum(newIdx(clusterIndices==2) == 2), ...
%     sum(newIdx(clusterIndices==3) == 3), ...
%     sum(newIdx(clusterIndices==4) == 4), ...
%     sum(newIdx(clusterIndices==5) == 5), ...
%     sum(newIdx(clusterIndices==6) == 6)] / 50;
% 	disp([accuracy, preciseAccuracy]);
% end
