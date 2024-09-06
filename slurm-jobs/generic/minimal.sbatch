#!/bin/bash

#SBATCH -N 10
#SBATCH --ntasks-per-node=4
#SBATCH -o /home/Matt.Long/run_bench_%j.out
#SBATCH -e /home/Matt.Long/run_bench_%j.out

# source wfenv to load intel modules
source wfenv.sh
source inputs.sh
export UCX_TLS=tcp

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
mpirun ./src/ior

# run dir setup
mkdir -p /hammerspace/bench/ior/bin_$SLURM_JOB_ID /hammerspace/bench/ior/run_$SLURM_JOB_ID
mkdir -p /hammerspace/bench/mdtest/bin_$SLURM_JOB_ID /hammerspace/bench/mdtest/run_$SLURM_JOB_ID

# copy executables to hammerspace 
cp $HOME/ior/src/ior /hammerspace/bench/ior/bin_$SLURM_JOB_ID/ior
cp $HOME/ior/src/mdtest /hammerspace/bench/mdtest/bin_$SLURM_JOB_ID/mdtest

# run intel mpi test
echo "======================"
echo "running intel mpi test"
mpirun -ppn $SLURM_CPUS_ON_NODE IMB-MPI1 alltoall > alltoall_$SLURM_JOB_ID.txt

# small ior
echo "======================"
echo "running minimal ior"
mpirun -ppn $SLURM_CPUS_ON_NODE /hammerspace/bench/ior/bin_$SLURM_JOB_ID/ior -w -i 1 -o /hammerspace/bench/ior/run_$SLURM_JOB_ID/out -t 1m -b 16m -s 16 -F -C -e > minimal_ior_$SLURM_JOB_ID.txt

# small mdtest 
echo "======================"
echo "running minimal mdtest"
mpirun -ppn $SLURM_CPUS_ON_NODE /hammerspace/bench/mdtest/bin_$SLURM_JOB_ID/mdtest -n 20840 -i 1 -u -d /hammerspace/bench/mdtest/run_$SLURM_JOB_ID > minimal_mdtest_$SLURM_JOB_ID.txt
