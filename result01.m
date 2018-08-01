expPath = 'exp01/';
algorithm = 'pam'; %small

forBoxplot = zeros(25, 13);

rrr = 3;
ccc = 5;
clim = [0.65, 0.95];

figure;

fid = fopen([expPath, 'results_', algorithm, '_pw.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 1) = cellArray{4};
pw = mean(cellArray{4});
subplot(rrr, ccc, 1); imagesc(pw, clim); title('pw'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk1.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 2) = cellArray{4};
pk1 = mean(cellArray{4});
subplot(rrr, ccc, 2); imagesc(pk1, clim); title('pk1'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk2e.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 3) = cellArray{4};
pk2e = mean(cellArray{4});
subplot(rrr, ccc, 3); imagesc(pk2e, clim); title('pk2e'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk2a.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 4) = cellArray{4}(cellArray{12} == 50);
pk2a = zeros(1, 5);
for a = 50:50:250
  pk2a(a / 50) = mean(cellArray{4}(cellArray{12} == a));
end
subplot(rrr, ccc, 4); imagesc(pk2a, clim); title('pk2a'); xlabel('N');
xticks([1, 2, 3, 4, 5]); xticklabels({'50', '100', '150', '200', '250'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pl.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 5) = cellArray{4};
pl = mean(cellArray{4});
subplot(rrr, ccc, 5); imagesc(pl, clim); title('pl'); xticklabels({''}); yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pi.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %f %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 6) = cellArray{4}(cellArray{11} == 10 & ...
  round(cellArray{12} / 0.05) == round(0.05 / 0.05) & ...
  strcmp(cellArray{13}, 'constant_one'));
pi = zeros(5, 5);
for r = 10:10:50
  for s = 0.05:0.05:0.25
    pi(r / 10, round(s / 0.05)) = mean(cellArray{4}(cellArray{11} == r & ...
      round(cellArray{12} / 0.05) == round(s / 0.05) & ...
      strcmp(cellArray{13}, 'constant_one')));
  end
end
subplot(rrr, ccc, 6); imagesc(pi, clim); title('pi'); xlabel('resolution');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma');
yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

fid = fopen([expPath, 'results_', algorithm, '_pi.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %f %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 7) = cellArray{4}(cellArray{11} == 10 & ...
  round(cellArray{12} / 0.05) == round(0.05 / 0.05) & ...
  strcmp(cellArray{13}, 'linear_ramp'));
pi = zeros(5, 5);
for r = 10:10:50
  for s = 0.05:0.05:0.25
    pi(r / 10, round(s / 0.05)) = mean(cellArray{4}(cellArray{11} == r & ...
      round(cellArray{12} / 0.05) == round(s / 0.05) & ...
      strcmp(cellArray{13}, 'linear_ramp')));
  end
end
subplot(rrr, ccc, 7); imagesc(pi, clim); title('pi (weight)'); xlabel('resolution');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma');
yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

%%

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 8) = cellArray{4}(cellArray{11} == 40 & strcmp(cellArray{12}, 'constant_one'));
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'constant_one')));
end
subplot(rrr, ccc, 8); imagesc(pbow, clim); title('pbow');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 9) = cellArray{4}(cellArray{11} == 40 & strcmp(cellArray{12}, 'linear_ramp'));
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'linear_ramp')));
end
subplot(rrr, ccc, 9); imagesc(pbow, clim); title('pbow (weight)');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pvlad.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 10) = cellArray{4}(cellArray{11} == 10 & strcmp(cellArray{12}, 'constant_one'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'constant_one')));
end
subplot(rrr, ccc, 10); imagesc(pfv, clim); title('pvlad'); xlabel('k');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pvlad.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 11) = cellArray{4}(cellArray{11} == 20 & strcmp(cellArray{12}, 'linear_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'linear_ramp')));
end
subplot(rrr, ccc, 11); imagesc(pfv, clim); title('pvlad (weight)');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 12) = cellArray{4}(cellArray{11} == 10 & strcmp(cellArray{12}, 'constant_one'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'constant_one')));
end
subplot(rrr, ccc, 12); imagesc(pfv, clim); title('pfv'); xlabel('k');
xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 13) = cellArray{4}(cellArray{11} == 10 & strcmp(cellArray{12}, 'linear_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'linear_ramp')));
end
subplot(rrr, ccc, 13); imagesc(pfv, clim); title('pfv (weight)');
xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'});
yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pds.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %f %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 14) = cellArray{4}(cellArray{11} == 20 & ...
  round(cellArray{12} / 0.1) == round(0.1 / 0.1) & ...
  cellArray{13} == 25);
pds = zeros(3, 4);
r = 20;
for s = 0.1:0.1:0.3
  for d = 25:25:100
    pds(round(s / 0.1), d / 25) = mean(cellArray{4}(cellArray{11} == r & ...
      round(cellArray{12} / 0.1) == round(s / 0.1) & ...
      cellArray{13} == d));
  end
end
subplot(rrr, ccc, 14); imagesc(pds, clim); title('pds (resolution = 20)');
xlabel('dim'); xticks([1, 2, 3, 4]); xticklabels({'25', '50', '75', '100'});
ylabel('sigma'); yticks([1, 2, 3]); yticklabels({'0.1', '0.2', '0.3'});

%%

labels = {'pw', 'pk1', 'pk2e', 'pk2a (n = 50)', 'pl', ...
  'pi (resolution = 10, sigma = 0.05, no weighting)', ...
  'pi (resolution = 10, sigma = 0.05, weighting)', ...
  'pbow (k = 40, no weighting)', ...
  'pbow (k = 40, weighting)', ...
  'pvlad (k = 10, no weighting)', ...
  'pvlad (k = 20, weighting)', ...
  'fv (k = 10, no weighting)', ...
  'fv (k = 10, weighting)', ...
  'pds (r = 20, sigma = 0.1, dim = 25)'};

figure;
boxplot(forBoxplot);
xtickangle(30);
xticklabels(labels);

for i = 1:numel(labels)
  fprintf('%s & %f pm %f\n', labels{i}, mean(forBoxplot(:, i)), std(forBoxplot(:, i)));
end
