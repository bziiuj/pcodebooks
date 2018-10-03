classdef PersistenceKernelOne < PersistenceRepresentation
  %PERSISTENCEKERNELONE
  
  properties
    sigma
  end
  
  methods
    function obj = PersistenceKernelOne(sigma)
      obj = obj@PersistenceRepresentation();

      obj.sigma = sigma;
    end
    
    function setup(obj)
      addpath('../persistence-learning/code/matlab/');
      pl_setup();
    end
    
    function obj = fit(obj, diagrams)
		disp('PersistenceKernelOne does not need fitting.');
    end
    
    function repr = predict(obj, diagrams)
		repr = diagrams;
    end

    function K = generateKernel(obj, repr)
      dim = 1; % TODO: does it matter?

      diagram_distance = '../persistence-learning/code/dipha-pss/build/diagram_distance';
    
      outDir = 'temp';
      if exist(outDir)
        rmdir(outDir, 's');
      end
      mkdir(outDir);

      % Number of diagrams to create
      for i=1:numel(repr)
          data = [ones(size(repr{i}, 1), 1) * dim, repr{i}];

          outFile = sprintf('test_%d', i);
          outFile = fullfile(outDir, outFile);
          pl_write_persistence_diagram(outFile, 'dipha', data);
      end

      K = zeros(numel(repr));
      for i=1:numel(repr)
          disp(strcat('krenel one: ', num2str(i), '/', num2str(numel(repr))));
        for j=i+1:numel(repr)
          listFile = fullfile(outDir, 'list.txt');
          fid = fopen(listFile, 'w');
          fprintf(fid, '%s/test_%d.bin\n', outDir, i);
          fprintf(fid, '%s/test_%d.bin\n', outDir, j);
          fclose(fid);

          % GRAM matrix
          gram_matrix_file_wIFGT = fullfile(outDir, ...
              sprintf('K_wIFGT.txt'));

          options = ['--time ', num2str(obj.sigma), ...
              ...%' --use_fgt ', ...
              ' --dim ', num2str(dim) ' '];
          exec = [diagram_distance ' ' options listFile ' > ' gram_matrix_file_wIFGT];
          system(exec);

          oneK = load(gram_matrix_file_wIFGT);
          K(i, j) = oneK(1, 2);
        end
      end
    end
  end
end
