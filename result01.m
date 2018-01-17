expPath = 'exp01/';
algorithm = 'pam'; %small

forBoxplot = zeros(50, 13);

rrr = 3;
ccc = 5;

figure;

fid = fopen([expPath, 'results_', algorithm, '_pw.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 1) = cellArray{4};
pw = mean(cellArray{4});
subplot(rrr, ccc, 1); imagesc(pw, [0.5, 1]); title('pw'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk1.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 2) = cellArray{4};
pk1 = mean(cellArray{4});
subplot(rrr, ccc, 2); imagesc(pk1, [0.5, 1]); title('pk1'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk2e.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 3) = cellArray{4};
pk2e = mean(cellArray{4});
subplot(rrr, ccc, 3); imagesc(pk2e, [0.5, 1]); title('pk2e'); xticklabels({''}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pk2a.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %d', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 4) = cellArray{4}(cellArray{12} == 50);
pk2a = zeros(1, 5);
for a = 50:50:250
  pk2a(a / 50) = mean(cellArray{4}(cellArray{12} == a));
end
subplot(rrr, ccc, 4); imagesc(pk2a, [0.5, 1]); title('pk2a'); xlabel('N'); xticks([1, 2, 3, 4, 5]); xticklabels({'50', '100', '150', '200', '250'}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pl.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 5) = cellArray{4};
pl = mean(cellArray{4});
subplot(rrr, ccc, 5); imagesc(pl, [0.5, 1]); title('pl'); xticklabels({''}); yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pi.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %f %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 6) = cellArray{4}(cellArray{11} == 10 & ...
  round(cellArray{12} / 0.05) == round(0.05 / 0.05) & ...
  strcmp(cellArray{13}, 'one_ramp'));
pi = zeros(5, 5);
for r = 10:10:50
  for s = 0.05:0.05:0.25
    pi(r / 10, round(s / 0.05)) = mean(cellArray{4}(cellArray{11} == r & ...
      round(cellArray{12} / 0.05) == round(s / 0.05) & ...
      strcmp(cellArray{13}, 'one_ramp')));
  end
end
subplot(rrr, ccc, 6); imagesc(pi, [0.5, 1]); title('pi'); xlabel('resolution'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma'); yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

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
subplot(rrr, ccc, 7); imagesc(pi, [0.5, 1]); title('pi (weight)'); xlabel('resolution'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); ylabel('sigma'); yticks([1, 2, 3, 4, 5]); yticklabels({'0.05', '0.10', '0.15', '0.20', '0.25'});

%%

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 8) = cellArray{4}(cellArray{11} == 40 & strcmp(cellArray{12}, 'one_ramp'));
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'one_ramp')));
end
subplot(rrr, ccc, 8); imagesc(pbow, [0.5, 1]); title('pbow'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pbow.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 9) = cellArray{4}(cellArray{11} == 40 & strcmp(cellArray{12}, 'linear_ramp'));
pbow = zeros(1, 5);
for c = 10:10:50
  pbow(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'linear_ramp')));
end
subplot(rrr, ccc, 9); imagesc(pbow, [0.5, 1]); title('pbow (weight)'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pvlad.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 10) = cellArray{4}(cellArray{11} == 10 & strcmp(cellArray{12}, 'one_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'one_ramp')));
end
subplot(rrr, ccc, 10); imagesc(pfv, [0.5, 1]); title('pvlad'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pvlad.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 11) = cellArray{4}(cellArray{11} == 20 & strcmp(cellArray{12}, 'linear_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'linear_ramp')));
end
subplot(rrr, ccc, 11); imagesc(pfv, [0.5, 1]); title('pvlad (weight)'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

%%

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 12) = cellArray{4}(cellArray{11} == 10 & strcmp(cellArray{12}, 'one_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'one_ramp')));
end
subplot(rrr, ccc, 12); imagesc(pfv, [0.5, 1]); title('pfv'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

fid = fopen([expPath, 'results_', algorithm, '_pfv.txt'], 'r');
cellArray = textscan(fid, '%s %d %f %f %f %f %f %f %f %f %d %s %f %f', 'delimiter', ';');
fclose(fid);
forBoxplot(:, 13) = cellArray{4}(cellArray{11} == 10 & strcmp(cellArray{12}, 'linear_ramp'));
pfv = zeros(1, 5);
for c = 10:10:50
  pfv(c / 10) = mean(cellArray{4}(cellArray{11} == c & strcmp(cellArray{12}, 'linear_ramp')));
end
subplot(rrr, ccc, 13); imagesc(pfv, [0.5, 1]); title('pfv (weight)'); xlabel('k'); xticks([1, 2, 3, 4, 5]); xticklabels({'10', '20', '30', '40', '50'}); yticklabels({''});

%%

figure;
boxplot(forBoxplot);
xticklabels({'pw', 'pk1', 'pk2e', 'pk2a', 'pl', 'pi', 'pi (weight)', 'pbow', 'pbow (weight)', 'pvlad', 'pvlad (weight)', 'fv', 'fv (weight)'});
xtickangle(30);
