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
if [ ! -d "$HOME/ior" ]; then
    git clone https://github.com/hpc/ior.git
fi

# build ior
cd ior
./bootstrap
./configure
make clean && make

# test build
echo "running test build"
mpirun ./src/ior

# run dir setup
mkdir -p /lustre/bench/ior/bin_$SLURM_JOB_ID /lustre/bench/ior/run_$SLURM_JOB_ID
mkdir -p /lustre/bench/mdtest/bin_$SLURM_JOB_ID /lustre/bench/mdtest/run_$SLURM_JOB_ID

# copy executables to lustre 
cp $HOME/ior/src/ior /lustre/bench/ior/bin_$SLURM_JOB_ID/ior
cp $HOME/ior/src/mdtest /lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest

# run intel mpi test
echo "running intel mpi test"
mpirun -ppn $SLURM_CPUS_ON_NODE IMB-MPI1 alltoall 

# make IOR command
ior_cmd="/lustre/bench/ior/bin_$SLURM_JOB_ID/ior"
ior_args="-i $ior_iterations -o /lustre/bench/ior/run_$SLURM_JOB_ID/out -t $ior_transfer_size -b $ior_block_size -s $ior_segment_count"

# Add flags based on conditions
[ "$ior_write" = true ] && ior_args="$ior_args -w"
[ "$ior_read" = true ] && ior_args="$ior_args -r"
[ "$ior_fpp" = true ] && ior_args="$ior_args -F"
[ "$ior_reorder" = true ] && ior_args="$ior_args -C"
[ "$ior_fsync" = true ] && ior_args="$ior_args -e"

# small ior
echo "running ior"
mpirun -ppn $SLURM_CPUS_ON_NODE $ior_cmd $ior_args

# small mdtest 
echo "running minimal mdtest"
mpirun -ppn $SLURM_CPUS_ON_NODE /lustre/bench/mdtest/bin_$SLURM_JOB_ID/mdtest -n 20840 -i 1 -u -d /lustre/bench/mdtest/run_$SLURM_JOB_ID 
