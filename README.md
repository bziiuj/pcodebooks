# pcodebooks
Persistence Codebooks

A. This code contains experiments presented in "Persistence Bag-of-Words for Topological Data Analysis" (/https://arxiv.org/abs/1812.09245). It was tested on Debian Stretch 9.6 x64 and OS 10.13 (High Sierra). The Statistics and Machine Learning Toolbox is required.

B. Instalation steps:

	1. All needed dependencies and experiment data should download and build automatically by running setup_pcodebook.m matlab script (in cases of some environments, it is necessary to run ./get_dependencies.sh script directly from the console).

C. Test persistence codebooks (only vlfeat library needed):

	1. In order to test only the persistence codebooks, you can run:

	simple_test();

D. Run experiments (all libraries needed):

	1. In Matlab run one of the file 'experiment0...', e.g.:

	experiment01_synthetic(2, 0, 0)

	2. Arguments are described in every file, but in general:

		- First argument describes set of descriptors to be tested.
		- Second, type of svm, using precomputed kernel or feature vector.
		- Third, in case of Persistence Image, you can use parallel computing, while generating descriptors.
		- Forth, if dataset is used both in EXP-A and EXP-B, you can decide to compute experiment only for a subset of data.

	3. Results are stored in appropiate files in respective experiment directory.

	4. You can additionally change set of tested parameters in experiment files.

E. Notice, that SW.h was extracted from the GUDHI open source library:
	http://gudhi.gforge.inria.fr/
