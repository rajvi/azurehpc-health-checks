#!/bin/bash
set -e

NVCC=/usr/local/cuda/bin/nvcc
SRC_DIR=$1
EXE_DIR=$2

# location for any source files default current directory
if [[ -z "$SRC_DIR" ]];then
	SRC_DIR=.
fi

# location where we will be putting execuatble. Must match custom tests.
if [[ -z "$EXE_DIR" ]];then
	EXE_DIR=/opt/azurehpc/test/nhc
fi

mkdir -p $EXE_DIR

# CUDA BW Test Setup
#Test if nvcc is installed and if so install gpu-copy test.
if test -f "$NVCC"; then
	#Compile the gpu-copy benchmark.

	cufile="$SRC_DIR/gpu-copy.cu"
	outfile="$EXE_DIR/gpu-copy"

	#Test if the default gcc compiler is new enough to compile gpu-copy.
	#If it is not then use the 9.2 compiler, that should be installed in
	#/opt.
	if [ $(gcc -dumpversion | cut -d. -f1) -gt 6 ]; then
		$NVCC -lnuma $cufile -o $outfile
	else
		$NVCC --compiler-bindir /opt/gcc-9.2.0/bin \
			-lnuma $cufile -o $outfile
	fi
else
  echo "$NVCC not found. Exiting setUP"
fi

# create perf-test executables
VERSION=4.5-0.12
VERSION_HASH=ge93c538
apt-get install -y libpci-dev
pushd ${EXE_DIR}
wget https://github.com/linux-rdma/perftest/releases/download/v${VERSION}/perftest-${VERSION}.${VERSION_HASH}.tar.gz
tar xvf perftest-${VERSION}.${VERSION_HASH}.tar.gz
pushd perftest-4.5
./configure CUDA_H_PATH=/usr/local/cuda/include/cuda.h
make
rm ${EXE_DIR}/perftest-${VERSION}.${VERSION_HASH}.tar.gz
popd
popd
# copy all custom test to the nhc scripts dir
cp $SRC_DIR/*.nhc /etc/nhc/scripts

exit 0