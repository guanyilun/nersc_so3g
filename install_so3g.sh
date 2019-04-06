#!/bin/bash

# In this script contains my so3g setup steps
# It is very preliminary but can act as a first pass
# towards a better build script. Relevant sections
# can be commented off accordingly based on the 
# specific environment

######################
# user configuration #
######################

# installation directory
export LOCAL=${HOME}/.local/

# directory to build softwares
BUILD_DIR=${HOME}/software/

################
# main program #
################

# create local library
echo Setting up local build libraries...
mkdir -vp ${LOCAL}
mkdir -vp ${LOCAL}/bin
mkdir -vp ${LOCAL}/lib
mkdir -vp ${LOCAL}/include
mkdir -vp ${BUILD_DIR}

# include local into search path
export PATH=${LOCAL}/bin:${PATH}
export LD_LIBRARY_PATH=${LOCAL}/lib:${LD_LIBRARY_PATH}

# use gnu instead of intel for now
# TODO: figure out how to compile with intel
module swap PrgEnv-intel PrgEnv-gnu

# cloning repositories
echo Cloning repositories
cd $BUILD_DIR
git clone https://github.com/CMB-S4/spt3g_software
git clone https://github.com/simonsobs/so3g

# compiling boost
echo Building boost...
cd $BUILD_DIR
wget https://dl.bintray.com/boostorg/release/1.65.1/source/boost_1_65_1.tar.gz
tar -xzvf boost_1_65_1.tar.gz
rm -v boost_1_65_1.tar.gz
cd boost_1_65_1

# fix boost include python bug
ln -sv $(dirname `which python3`)/../include/python3.6m $(dirname `which python3`)/../include/python3.6

# configure build
./bootstrap.sh --prefix=$LOCAL --with-python=`which python3`

# build boost with 8 parallel processes
./b2 install -j8

# expose the build as environment variables
export BOOST_ROOT=${BUILD_DIR}/boost_1_65_1/
export BOOST_LIBRARYDIR=${LOCAL}/lib

# start to build spt3g_software
# first load some required modules
module load openmpi
module load netcdf/4.4.1
module load fftw/3.3.8

# update CXXFLAGS to suppress warnings otherwise it will cause errors
export CXXFLAGS="$CXXFLAGS -w -I/usr/common/software/netcdf/4.4.1/hsw/intel/include"

echo Building spt3g_software...
cd $BUILD_DIR/spt3g_software
mkdir build
cd build

# configure the build
cmake .. -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc

# compile spt3g_software with 8 processes
make -j8

echo Testing spt3g_software
python -c "from spt3g import core"
echo No error means we are good

# expose installation as environment variables
# other software (e.g. Lyrebird) that needs to link to this
export SPT3G_SOFTWARE_PATH=${BUILD_DIR}/spt3g_software
export SPT3G_SOFTWARE_BUILD_PATH=${SPT3G_SOFTWARE_PATH}/build

export PATH=${SPT3G_SOFTWARE_BUILD_PATH}/bin:$PATH
export LD_LIBRARY_PATH=${SPT3G_SOFTWARE_BUILD_PATH}/spt3g:$LD_LIBRARY_PATH
export PYTHONPATH=${SPT3G_SOFTWARE_BUILD_PATH}:$PYTHONPATH

# build so3g
echo Building so3g...
cd $BUILD_DIR/so3g
mkdir build
cd build
cmake .. -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc
make -j8
make install
echo If no error, installation is successful. 
echo Done!
