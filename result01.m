expPath = 'exp01/';
algorithm = 'pam'; %small

forBoxplot = zeros(100, 8);

figure;

fid = fopen([expPath, 'results_', algorithm, '_pw.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 1) = cellArray{4};
pw = mean(cellArray{4});
subplot(2, 4, 1); imagesc(pw, [0.5, 1]); title('pw'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk1.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 2) = cellArray{4};
pk1 = mean(cellArray{4});
subplot(2, 4, 2); imagesc(pk1, [0.5, 1]); title('pk1'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk2e.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 3) = cellArray{4};
pk2e = mean(cellArray{4});
subplot(2, 4, 3); imagesc(pk2e, [0.5, 1]); title('pk2e'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk2a.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 4) = cellArray{4}(cellArray{12} == 50);
pk2a = zeros(1, 5);
for a = 50:50:250
  pk2a(a / 50) = mean(cellArray{4}(cellArray{12} == a));
end
subplot(2, 4, 4); imagesc(pk2a, [0.5, 1]); title('pk2a'); xlabel('N'); xticks([1, 2, 3, 4, 5]); xticklabels({'50', '100', '150', '200', '250'}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pl.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 5) = cellArray{4};
pl = mean(cellArray{4});
subplot(2, 4, 5); imagesc(pl, [0.5, 1]); title('pl'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pi.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %f %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 6) = cellArray{4}(cellArray{11} == 10 & round(cellArray{12} / 0.05) == round(0.05 / 0.05));
pi = zeros(5, 5);
for r = 10:10:50
  for s = 0.05:0.05:0.25
    pi(r / 10, round(s / 0.05)) = mean(cellArray{4}(cellArray{11} == r & round(cellArray{12} / 0.05) == round(s / 0.05)));
  end
end
subplot(2, 4, 6); imagesc(pi, [0.5, 1]); title('pi'); xlabel('resolution'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma'); yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 7) = cellArray{4}(cellArray{11} == 50);
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{11} == c));
end
subplot(2, 4, 7); imagesc(pbow, [0.5, 1]); title('pbow'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 8) = cellArray{4}(cellArray{11} == 10);
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c));
end
subplot(2, 4, 8); imagesc(pfv, [0.5, 1]); title('pfv'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

figure;
boxplot(forBoxplot);
