#!/bin/bash

#SBATCH -N 10
#SBATCH --ntasks-per-node=4
#SBATCH -o /home/jlin/run_bench_%j.out
#SBATCH -e /home/jlin/run_bench_%j.out

# source wfenv to load intel modules
source wfenv.sh
source inputs.sh
export UCX_TLS=ud,sm,self

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

# small ior
echo "running minimal ior"
mpirun -ppn $SLURM_CPUS_ON_NODE /lustre/bench/ior/bin_$SLURM_JOB_ID/ior -w -i 1 -o /lustre/bench/ior/run_$SLURM_JOB_ID/out -t 1m -b 16m -s 16 -F -C -e > $HOME/minimal_ior_$SLURM_JOB_ID.txt

# small mdtest 
echo "running minimal mdtest"
mpirun -ppn $SLURM_CPUS_ON_NODE /lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest -n 20840 -i 1 -u -d /lustre/bench/mdtest/run_$SLURM_JOB_ID > $HOME/minimal_mdtest_$SLURM_JOB_ID.txt