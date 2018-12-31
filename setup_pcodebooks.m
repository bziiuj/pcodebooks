% Download dependencies
system('./get_dependencies.sh');

% Persistence Learning
cd ../persistence-learning


% PERSISTENCE LANDSCAPE
cd ../Persistent-Landscape-Wrapper/lib
build_functions
cd ../../pcodebooks

% VLFEAT
cd ../vlfeat/toolbox/
vl_setup
cd ../../pcodebooks

% PDSPHERE
cd ../pdsphere/matlab/libsvm-3.21
system('make')
cd matlab
make
cd ../../../../pcodebooks

% Download pds
system('./get_pds.sh');
