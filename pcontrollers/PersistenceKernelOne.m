classdef PersistenceKernelOne < PersistenceRepresentation
  %PERSISTENCEKERNELONE
  
  properties
  end
  
  methods
    function setup(obj)
      addpath('../persistence-learning/code/matlab/');
      pl_setup();
    end
    
    function repr = train(obj, diagrams)
      repr = obj.test(diagrams);
    end
    
    function repr = test(obj, diagrams)
      repr = diagrams;
    end

    function K = generateKernel(obj, repr)
      dim = 0; % TODO: does it matter?

      diagram_distance = '../persistence-learning/code/dipha-pss/build/diagram_distance';
    
      outDir = 'temp';
      rmdir(outDir, 's');
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
        for j=i+1:numel(repr)
          listFile = fullfile(outDir, 'list.txt');
          fid = fopen(listFile, 'w');
          fprintf(fid, '%s/test_%d.bin\n', outDir, i);
          fprintf(fid, '%s/test_%d.bin\n', outDir, j);
          fclose(fid);

          % GRAM matrix
          gram_matrix_file_wIFGT = fullfile(outDir, ...
              sprintf('K_wIFGT.txt'));

          options = ['--distance_squared --time ' ...
              num2str(1, '%e') ...
              ' --use_fgt ' ...
              ' --dim ' num2str(dim) ' '];
          exec = [diagram_distance ' ' options listFile ' > ' gram_matrix_file_wIFGT];
          system(exec);

          oneK = load(gram_matrix_file_wIFGT);
          K(i, j) = oneK(1, 2);
        end
      end
    end
  end
end
