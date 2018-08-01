expPath = 'exp02/';
algorithm = 'linearSVM';

forBoxplot = zeros(100, 9);
forBoxplotTime = zeros(1, 9);

rrr = 3;
ccc = 4;
clim = [83, 93];

figure('Name', 'Accuracy for experiment 2');

%%

basicLine = ['%s %d %f %f', ...
        ' %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', ...
        ' %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', ...
        ' %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', ...
        ' %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f', ...
        ' %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f'];
fid = fopen([expPath, 'results_', algorithm, '_pi.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %f %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 1) = allAccuracies(cellArray{105} == 40 & ...
  round(cellArray{106} / 0.05) == round(0.1 / 0.05) & ...
  strcmp(cellArray{107}, 'constant_one'), :);
forBoxplotTime(:, 1) = cellArray{3}(cellArray{105} == 40 & ...
  round(cellArray{106} / 0.05) == round(0.1 / 0.05) & ...
  strcmp(cellArray{107}, 'constant_one'));
pi = zeros(5, 5);
for r = 10:10:50
  for s = 0.05:0.05:0.25
    pi(r / 10, round(s / 0.05)) = mean(cellArray{4}(cellArray{105} == r & ...
      round(cellArray{106} / 0.05) == round(s / 0.05) & ...
      strcmp(cellArray{107}, 'constant_one')));
  end
end
subplot(rrr, ccc, 1); imagesc(pi, clim); title('pi'); xlabel('resolution');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma');
yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

fid = fopen([expPath, 'results_', algorithm, '_pi.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %f %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 2) = allAccuracies(cellArray{105} == 50 & ...
  round(cellArray{106} / 0.05) == round(0.05 / 0.05) & ...
  strcmp(cellArray{107}, 'linear_ramp'), :);
forBoxplotTime(:, 2) = cellArray{3}(cellArray{105} == 50 & ...
  round(cellArray{106} / 0.05) == round(0.05 / 0.05) & ...
  strcmp(cellArray{107}, 'linear_ramp'));
pi = zeros(5, 5);
for r = 10:10:50
  for s = 0.05:0.05:0.25
    pi(r / 10, round(s / 0.05)) = mean(cellArray{4}(cellArray{105} == r & ...
      round(cellArray{106} / 0.05) == round(s / 0.05) & ...
      strcmp(cellArray{107}, 'linear_ramp')));
  end
end
subplot(rrr, ccc, 2); imagesc(pi, clim); title('pi (weight)'); xlabel('resolution');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma');
yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

%%

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 3) = allAccuracies(cellArray{105} == 10 & strcmp(cellArray{106}, 'constant_one'), :);
forBoxplotTime(:, 3) = cellArray{3}(cellArray{105} == 10 & strcmp(cellArray{106}, 'constant_one'));
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{105} == c & strcmp(cellArray{106}, 'constant_one')));
end
subplot(rrr, ccc, 3); imagesc(pbow, clim); title('pbow');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 4) = allAccuracies(cellArray{105} == 40 & strcmp(cellArray{106}, 'linear_ramp'), :);
forBoxplotTime(:, 4) = cellArray{3}(cellArray{105} == 40 & strcmp(cellArray{106}, 'linear_ramp'));
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{105} == c & strcmp(cellArray{106}, 'linear_ramp')));
end
subplot(rrr, ccc, 4); imagesc(pbow, clim); title('pbow (weight)');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pvlad.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 5) = allAccuracies(cellArray{105} == 50 & strcmp(cellArray{106}, 'constant_one'), :);
forBoxplotTime(:, 5) = cellArray{3}(cellArray{105} == 50 & strcmp(cellArray{106}, 'constant_one'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{105} == c & strcmp(cellArray{106}, 'constant_one')));
end
subplot(rrr, ccc, 5); imagesc(pfv, clim); title('pvlad'); xlabel('k');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pvlad.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 6) = allAccuracies(cellArray{105} == 50 & strcmp(cellArray{106}, 'linear_ramp'), :);
forBoxplotTime(:, 6) = cellArray{3}(cellArray{105} == 50 & strcmp(cellArray{106}, 'linear_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{105} == c & strcmp(cellArray{106}, 'linear_ramp')));
end
subplot(rrr, ccc, 6); imagesc(pfv, clim); title('pvlad (weight)');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 7) = allAccuracies(cellArray{105} == 50 & strcmp(cellArray{106}, 'constant_one'), :);
forBoxplotTime(:, 7) = cellArray{3}(cellArray{105} == 50 & strcmp(cellArray{106}, 'constant_one'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{105} == c & strcmp(cellArray{106}, 'constant_one')));
end
subplot(rrr, ccc, 7); imagesc(pfv, clim); title('pfv'); xlabel('k');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %s'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 8) = allAccuracies(cellArray{105} == 20 & strcmp(cellArray{106}, 'linear_ramp'), :);
forBoxplotTime(:, 8) = cellArray{3}(cellArray{105} == 20 & strcmp(cellArray{106}, 'linear_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{105} == c & strcmp(cellArray{106}, 'linear_ramp')));
end
subplot(rrr, ccc, 8); imagesc(pfv, clim); title('pfv (weight)');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pds.txt'], 'r');
cellArray = textscan(fid, [basicLine, '%d %f %d'], 'delimiter', ';');
fclose(fid);
allAccuracies = cat(2, cellArray{5:104});
forBoxplot(:, 9) = allAccuracies(cellArray{105} == 20 & ...
  round(cellArray{106} / 0.1) == round(0.2 / 0.1) & ...
  cellArray{107} == 25, :);
forBoxplotTime(:, 9) = cellArray{3}(cellArray{105} == 20 & ...
  round(cellArray{106} / 0.1) == round(0.2 / 0.1) & ...
  cellArray{107} == 25);
pds = zeros(3, 4);
r = 20;
for s = 0.1:0.1:0.3
  for d = 25:25:100
    pds(round(s / 0.1), d / 25) = mean(cellArray{4}(cellArray{105} == r & ...
      round(cellArray{106} / 0.1) == round(s / 0.1) & ...
      cellArray{107} == d));
  end
end
subplot(rrr, ccc, 9); imagesc(pds, clim); title('riemann (resolution = 20)');
xlabel('dim'); xticks([1, 2, 3, 4]); xticklabels({'25', '50', '75', '100'});
ylabel('sigma'); yticks([1, 2, 3]); yticklabels({'0.1', '0.2', '0.3'});

%%

labels = {'pi (resolution = 40, sigma = 0.1, no weighting)', ...
  'pi (resolution = 50, sigma = 0.05, weighting)', ...
  'pbow (k = 10, no weighting)', ...
  'pbow (k = 40, weighting)', ...
  'pvlad (k = 50, no weighting)', ...
  'pvlad (k = 50, weighting)', ...
  'pfv (k = 50, no weighting)', ...
  'pfv (k = 20, weighting)', ...
  'riemman (r = 20, sigma = 0.2, dim = 25)'};

figure('Name', 'Accuracy for experiment 2 (optimal parameters)');
boxplot(forBoxplot);
xtickangle(30);
xticklabels(labels);
ylabel('accuracy');

figure('Name', 'Mean time for experiment 2 (optimal parameters)');
plot(forBoxplotTime, 'r*');
xtickangle(30);
xticklabels(labels);
ylabel('time (s)');

for i = 1:numel(labels)
  fprintf('%s & %f & %f & %f\n', labels{i}, mean(forBoxplot(:, i)), std(forBoxplot(:, i)), mean(forBoxplotTime(:, i)));
end
