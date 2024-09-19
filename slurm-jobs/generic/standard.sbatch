#!/bin/bash

#SBATCH -N 10
#SBATCH --ntasks-per-node=4
#SBATCH -o /home/jlin/run_bench_%j.out
#SBATCH -e /home/jlin/run_bench_%j.out

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

# standard ior
echo "======================"
echo "running standard ior"
mpirun -ppn $SLURM_CPUS_ON_NODE /hammerspace/bench/ior/bin_$SLURM_JOB_ID/ior -r -w -i 3 -o /hammerspace/bench/ior/run_$SLURM_JOB_ID/out -t 64m -b 64m -s 16 -F -C -e

# standard mdtest 
echo "======================"
echo "running standard mdtest"
mpirun -ppn $SLURM_CPUS_ON_NODE /hammerspace/bench/mdtest/bin_$SLURM_JOB_ID/mdtest -n 20840 -e 4096 -w 4096 -i 3 -u -d /hammerspace/bench/mdtest/run_$SLURM_JOB_ID 
