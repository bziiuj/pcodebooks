# pcodebooks
Persistence Codebooks

A. This code contains experiments presented in "Persistence Codebooks for Topological Data Analysis" (https://arxiv.org/abs/1802.04852). It was tested on macOS High Sierra 10.13.3 and Linux Ubuntu 16.04 LTS.

B. Instalation steps:

  1. Download libraries

    a) You have to download the following dependencies:

      For PersistenceKernelOne (Reininghaus et al.): https://github.com/rkwitt/persistence-learning
      For PersistenceLandscape: https://github.com/queenBNE/Persistent-Landscape-Wrapper
      For PersistenceImage: https://github.com/CSU-TDA/PersistenceImages
      For PersistenceBow & PersistenceFV: https://github.com/vlfeat/vlfeat
      For PersistencePds (Carriere et al.): https://github.com/rushilanirudh/pdsphere/

    b) The mail folder of the project should contain the following files:

      pcodebooks
      pdsphere
      PersistenceImages
      persistence-learning
      Persistent-Landscape-Wrapper
      vlfeat

  2. Build and install dependency libraries

C. Test persistence codebooks (only vlfeat library needed):

  1. In order to test only the persistence codebooks, you can run:

    test();

D. Run experiments (all libraries needed):

  1. In order to recompute the results from Table 1, please run the following in Matlab:

    experiment01();
    result01();

  2. In order to recompute the results from Table 2, please run the following in Matlab:

    experiment02();
    result02();

E. Notice, that SW.h was extracted from the GUDHI open source library:
   http://gudhi.gforge.inria.fr/
