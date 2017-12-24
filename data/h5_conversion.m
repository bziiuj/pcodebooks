types = {'Random Cloud', 'Circle', 'Sphere', 'Clusters', ...
  'Clusters within Clusters', 'Torus'};

for j = 1:numel(types)
  if 1
    for i = 2:51
      % 3xN
      code = gauss_0_1{i, j};

      filePath = ['gauss_0_1/', types{j}, '/', num2str(i), '.h5'];
      h5create(filePath, '/code', size(code)) ;
      h5write(filePath, '/code', code) ;
    end
  else
    if 1
      filePath = ['gauss_0_1/', types{j}, '/', num2str(2), '.h5'];
      points = h5read(filePath, '/code');
      if j == 2
        subplot(2, 3, j); pcshow([points; zeros(1, 500)]'); legend(types{j});
      else
        subplot(2, 3, j); pcshow(points'); legend(types{j});
      end
    else
      filePath = ['gauss_0_1/', types{j}, '/', num2str(2), '.h5'];
      points = h5read(filePath, '/code');
      if j ~= 2
        DT = delaunayTriangulation(points(1,:)',points(2,:)',points(3,:)');
        subplot(2, 3, j); tetramesh(DT,'FaceAlpha',0.3);
      end
    end
  end
end
