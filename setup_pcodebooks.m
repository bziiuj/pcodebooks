% Download data
system('./get_dependencies.sh');

% PERSISTENCE LANDSCAPE
cd ../Persistent-Landscape-Wrapper/lib
build_functions
cd ../../pcodebooks

% VLFEAT
cd ../vlfeat/toolbox/
vl_setup
cd ../../pcodebooks
