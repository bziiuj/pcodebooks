% Second experiment
function experiment02()
  addpath('pcontrollers')
  addpath('exp02');
  addpath('../pdsphere/matlab/');
  addpath('../pdsphere/matlab/libsvm-3.21/matlab/');

  rawPath = '../pdsphere/matlab/';
  expPath = 'exp02/';
  
  [pds, labels] = prepareDiagrams(rawPath, expPath);

  % calculate diagram limits
  pdsTemp = pds(:, 2);
  for r = 1:size(pdsTemp, 1)
    for c = 1:size(pdsTemp{r}, 1)
      pds{r, c} = pdsTemp{r}{c};
    end
  end
  diagramLimits = cell(1, size(pds, 2));
  for i = 1:size(pds, 2)
    allPoints = cat(1, pds{:, i});
    diagramLimits{i} = [quantile(allPoints(:, 1), 0.05), ...
      quantile(allPoints(:, 2), 0.95)];
  end

  algorithm = 'linearSVM';

  N = 1;

  for i = 1:N
    fprintf('repetition %d\n', i);

    seedBig = i * 100000;

    objs = {};
    for r = 10:10:50
      for s = 0.05:0.05:0.25
        objs{end + 1} = {PersistenceImage(r, s, @linear_ramp), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
      end
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceBow(c, @linear_ramp), {'pbow', ['pbow_', num2str(c)]}};
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceVLAD(c, @linear_ramp), {'pvlad', ['pvlad_', num2str(c)]}};
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceFV(c, @linear_ramp), {'pfv', ['pfv_', num2str(c)]}};
    end
    for r = 10:10:50
      for s = 0.05:0.05:0.25
        objs{end + 1} = {PersistenceImage(r, s, @constant_one), {'pi', ['pi_', num2str(r), '_', num2str(s)]}};
      end
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceBow(c, @constant_one), {'pbow', ['pbow_', num2str(c)]}};
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceVLAD(c, @constant_one), {'pvlad', ['pvlad_', num2str(c)]}};
    end
    for c = 10:10:50
      objs{end + 1} = {PersistenceFV(c, @constant_one), {'pfv', ['pfv_', num2str(c)]}};
    end
    for r = 10:10:50
      for s = 0.1:0.1:0.5
        for d = 25:25:100
          objs{end + 1} = {PersistencePds(r, s, d), {'pds', ['pds_', num2str(r), '_', num2str(s), '_', num2str(d)]}};
        end
      end
    end

    for o = 2:numel(objs)
      obj = objs{o}{1};
      prop = objs{o}{2};

      fprintf('Computing: %s\n', prop{2});

      [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, labels, ...
        diagramLimits, algorithm, prop{1});

      % TODO: save time
      fid = fopen([expPath, 'results_', algorithm, '_', prop{1}, '.txt'], 'a');
      % type;repetition;time;accuracy;preciseAccuracy
      basicLine = sprintf(['%s;%d;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f', ...
        ';%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f;%f'], ...
        prop{1}, i, time, accuracy, preciseAccuracy);
      switch prop{1}
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
        case {'pds'}
          % basicLine;resolution;sigma;dim
          fprintf(fid, '%s;%d;%f;%d\n', basicLine, obj.resolution, ...
            obj.sigma, obj.dim);
        otherwise
          throw(MException('Error', 'Representation is not saved'));
      end
      fclose(fid);
    end
  end
end

function [pds, labels] = prepareDiagrams(rawPath, expPath)
  % load pds
  if ~exist([expPath, 'pd.mat'], 'file')
    load([rawPath, 'PD.mat']);
    pds = PD;
    load([rawPath, 'Label_mocap.mat']);
    labels = Label;

    save([expPath, 'pd.mat'], 'pds', 'labels');
  else
    load([expPath, 'pd.mat']);
  end
end

function [accuracy, preciseAccuracy, time] = computeAccuracy(obj, pds, labels, ...
  diagramLimits, algorithm, name)

  switch name
    case {'pi', 'pbow', 'pvlad', 'pfv'}
      tic;
      reprCell = cell(size(pds, 1), size(pds, 2));
      for i = 1:size(pds, 2)
        reprCell(:, i) = obj.train(pds(:, i), diagramLimits{i});
        for j = 1:size(reprCell, 1)
          reprCell{j, i} = reprCell{j, i}(:);
        end
      end
      repr = zeros(size(reprCell, 2) * numel(reprCell{1, 1}), size(reprCell, 1));
      for i = 1:size(pds, 1)
        repr(:, i) = cat(1, reprCell{i, :});
      end
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
      preciseAccuracy = PD_svmclassify(repr, labels);
  end
  accuracy = mean(preciseAccuracy);
end
