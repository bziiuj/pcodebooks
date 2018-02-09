# sonata01
Persistence BOW

A. This code was tested on macOS High Sierra 10.13.3 and Linux Ubuntu 16.04 LTS.

B. Instalation steps:

  Step 1. Downloading libraries (already downloaded in case of double review process)

    a) You have to download the following dependencies:
      For PersistenceKernelOne (Reininghaus et al.): https://github.com/rkwitt/persistence-learning
      For PersistenceLandscape: https://github.com/queenBNE/Persistent-Landscape-Wrapper
      For PersistenceImage: https://github.com/CSU-TDA/PersistenceImages
      For PersistenceBow & PersistenceFV: https://github.com/vlfeat/vlfeat
      For PersistencePds (Carriere et al): https://github.com/rushilanirudh/pdsphere/

    b) The mail folder of the project should contain the following files:
      pdsphere
      PersistenceImages
      persistence-learning
      Persistent-Landscape-Wrapper
      sonata01
      vlfeat

  Step 2. Compile dependency libraries

    a ) Run the following commands:
      cd ./persistence-learning/code/dipha-pss/
      mkdir build
      cd build
      cmake ..
      make

C. Running experiments:

  1. In order to recompute the results from Table 1, please run the following in Matlab:
    experiment01();
    result01();

  2. In order to recompute the results from Table 2, please run the following in Matlab:
    experiment02();
    result02();
