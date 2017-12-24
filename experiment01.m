% First experiment
function experiment01()
  addpath('pcontrollers')

  libPath = 'data/';
  expPath = 'exp01/';
  
  pds = prepareDiagrams(libPath, expPath);

  N = 1;
  algorithm = 'pam'; %small

  accuracies = zeros(N, 6);
  for i = 1:N
    seedBig = i * 100000;

    objs = {};
    objs{end + 1} = {PersistenceWasserstein(), {'pw', 'pw'}};
    objs{end + 1} = {PersistenceKernelOne(), {'pk1', 'pk1'}};
    objs{end + 1} = {PersistenceKernelTwo(1, -1), {'pk2e', 'pk2e'}};
    for a = 50:50:250
      objs{end + 1} = {PersistenceKernelTwo(0, a), {'pk2a', ['pk2a_', num2str(a)]}};
    end
    objs{end + 1} = {PersistenceLandscape(), {'pl', 'pl'}};
    for r = 10:10:50
      for s = 0.05:0.05:0.25
        objs{end + 1} = {PersistenceImage(r, s, @linear_ramp, [0, 0.1841]), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
      end
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceBow(c, @linear_ramp, [0, 0.1841]), {'pbow', ['pbow_', num2str(c)]}};
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceFV(c, @linear_ramp, [0, 0.1841]), {'pfv', ['pfv_', num2str(c)]}};
    end

    for o = 1:numel(objs)
      obj = objs{o}{1};
      prop = objs{o}{2};

      fprintf('Computing: %s\n', prop{2});

      [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, algorithm, expPath, prop{1}, prop{2}, seedBig);

      % TODO: save time
      fid = fopen([expPath, 'results_', algorithm, '_', prop{1}, '.txt'], 'a');
      % type;repetition;time;accuracy;preciseAccuracy
      basicLine = sprintf('%s;%d;%f;%f;%f;%f;%f;%f;%f;%f', ...
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
          % basicLine;resolution;sigma;weightingFunction;diagramLimits
          f = functions(obj.weightingFunction);
          fprintf(fid, '%s;%d;%f;%s;%f;%f\n', basicLine, obj.resolution, obj.sigma, ...
            f.function, obj.diagramLimits);
        case {'pbow', 'pfv'}
          f = functions(obj.weightingFunction);
          % basicLine;numWords;weightingFunction;diagramLimits
          fprintf(fid, '%s;%d;%s;%f;%f\n', basicLine, obj.numWords, ...
            f.function, obj.diagramLimits);
        otherwise
          throw(MException('Error', 'Representation is not saved'));
      end
      fclose(fid);
    end
  end
end

function pds = prepareDiagrams(libPath, expPath)
  types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
    'Clusters within Clusters', 'Torus'};

  PLOT = 0;

  % load pds
  if ~exist([expPath, 'pd.mat'], 'file')
    pds = cell(numel(types), 50);
    for i = 2:51
      for j = 1:numel(types)
        filePath = [libPath, 'pd_gauss_0_1/', types{j}, '/', num2str(i), '.h5.pc.simba.1.00001_3.persistence'];
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

function [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, algorithm, expPath, name, detailName, seedBig)
  kernelPath = [expPath, detailName, '.mat'];

  switch name
    case {'pw'}
      if ~exist(kernelPath, 'file')
        throw(MException('Error', 'Wasserstein distance is currently not implemented'));
      else
        load(kernelPath);
        time = -1;
      end
    case {'pk1', 'pk2e', 'pk2a', 'pl', 'pi'}
      if ~exist(kernelPath, 'file')
        tic;
        repr = obj.train(pds(:));
        time = toc;
        K = obj.generateKernel(repr);
        save(kernelPath, 'K', 'time');
      else
        load(kernelPath);
      end
    otherwise
      tic;
      repr = obj.train(pds(:));
      time = toc;
      K = obj.generateKernel(repr);
  end

  [accuracy, preciseAccuracy] = computeAccuracyK(K, algorithm, seedBig);
end

function [accuracy, preciseAccuracy] = computeAccuracyK(K, algorithm, seedBig)
  rng(seedBig);

  K = max(K, K');

  clusterIndices = [repmat(1, [1, 50]), ...
    repmat(2, [1, 50]), ...
    repmat(3, [1, 50]), ...
    repmat(4, [1, 50]), ...
    repmat(5, [1, 50]), ...
    repmat(6, [1, 50])]';

  function d = functionK(i, j)
    d = K(i, j);
  end

  [idx, ~, ~, ~, midx] = kmedoids((1:300)', 6, ...
    'Distance', @functionK, ...
    'Replicates', 100, ...
    'Start', 'sample', ...
    'Algorithm', algorithm);
  newIdx = idx;
  for i = 1:6
    isIndex = idx(midx(i));
    shouldBeIndex = clusterIndices(midx(i));
    newIdx(idx == isIndex) = shouldBeIndex;
  end

  accuracy = sum(newIdx == clusterIndices) / 300;
  preciseAccuracy = [sum(newIdx(clusterIndices==1) == 1), ...
    sum(newIdx(clusterIndices==2) == 2), ...
    sum(newIdx(clusterIndices==3) == 3), ...
    sum(newIdx(clusterIndices==4) == 4), ...
    sum(newIdx(clusterIndices==5) == 5), ...
    sum(newIdx(clusterIndices==6) == 6)] / 50;
end
