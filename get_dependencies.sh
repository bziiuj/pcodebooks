#!/bin/bash

# Download and setup required libraries/projects 
 

echo 'PERSISTENCE LEARNING'
mkdir ../persistence-learning
git clone https://github.com/rkwitt/persistence-learning ../persistence-learning
cd ../persistence-learning
git pull
git submodule update --init --recursive
cd code/dipha-pss
mkdir build
cd build
cmake ..
make
cd ../../../../pcodebooks

echo 'PERSISTENCE LANDSCAPE'
mkdir ../Persistent-Landscape-Wrapper
git clone https://github.com/queenBNE/Persistent-Landscape-Wrapper.git ../Persistent-Landscape-Wrapper
wget https://www.math.upenn.edu/%7Edlotko/source.zip
unzip -j source.zip -d ../Persistent-Landscape-Wrapper/cpp
rm source.zip

echo 'PERSISTENCE IMAGES'
mkdir ../PersistenceImages
git clone https://github.com/CSU-TDA/PersistenceImages.git ../PersistenceImages

echo 'PDSPHERE'
mkdir ../pdsphere
git clone https://github.com/rushilanirudh/pdsphere.git ../pdsphere

# TODO: temporary solution, problem with compilation
echo 'VLFEAT'
# mkdir ../vlfeat
VLFEAT_VER='vlfeat-0.9.21'
# git clone https://github.com/vlfeat/vlfeat.git ../vlfeat
wget http://www.vlfeat.org/download/vlfeat-0.9.21-bin.tar.gz 
tar -C .. -xzf $VLFEAT_VER-bin.tar.gz $VLFEAT_VER 
rm $VLFEAT_VER-bin.tar.gz
mv ../$VLFEAT_VER ../vlfeat
