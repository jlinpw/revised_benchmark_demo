#!/bin/bash

#SBATCH -N 10
#SBATCH --ntasks-per-node=4
#SBATCH -o /home/jlin/run_bench_%j.out
#SBATCH -e /home/jlin/run_bench_%j.out

# source wfenv to load intel modules
source wfenv.sh
source inputs.sh

# verify environment
echo "verifying loaded modules..."
module list

# build ior and mdtest
# install prerequisites
sudo yum -y install automake

# get src code
git clone https://github.com/hpc/ior.git

# build ior
cd ior
./bootstrap
./configure
make clean && make

# test build
echo "running test build"
mpirun ./src/ior > $HOME/test_build_$SLURM_JOB_ID.txt

# run dir setup
mkdir -p /lustre/bench/ior/bin_$SLURM_JOB_ID /lustre/bench/ior/run_$SLURM_JOB_ID
mkdir -p /lustre/bench/mdtest/bin_$SLURM_JOB_ID /lustre/bench/mdtest/run_$SLURM_JOB_ID

# copy executables to lustre 
cp $HOME/ior/src/ior /lustre/bench/ior/bin_$SLURM_JOB_ID/ior
cp $HOME/ior/src/mdtest /lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest

# standard mdtest 
echo "running standard mdtest"
mpirun -ppn $SLURM_CPUS_ON_NODE /lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest -n 20840 -e 4096 -w 4096 -i 3 -u -d /lustre/bench/mdtest/run_$SLURM_JOB_ID > $HOME/standard_mdtest_$SLURM_JOB_ID.txt
