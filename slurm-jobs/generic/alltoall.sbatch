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

# run intel mpi test
echo "running intel mpi test"
mpirun -ppn $SLURM_CPUS_ON_NODE IMB-MPI1 alltoall > alltoall_$SLURM_JOB_ID.txt