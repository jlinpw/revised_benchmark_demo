#!/bin/bash

#===============================
# Initializaton
#===============================
# Exit if any command fails!
# Sometimes workflow runs fine but there are SSH problems.
# This line is useful for debugging but can be commented out.
# set -ex
source inputs.sh

# Useful info for context
date
jobdir=${PWD}
jobnum=$(basename ${PWD})
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
wfname=benchmark-demo

echo Starting benchmark_demo workflow...
echo Execution is in main.sh, launched from the workflow.xml.
echo Running in $jobdir with job number: $jobnum
echo

#===============================
# Inputs from workflow.xml
#===============================

echo ==========================================================
echo INPUT ARGUMENTS:
echo ==========================================================
echo $(cat inputs.sh)

# Function to print date alongside with message.
echod() {
    echo $(date): $@
    }

export WFP_whost=${resource_publicIp}

# Testing echod
echod Testing echod. Currently on `hostname`.
echod Will execute as ${WFP_whost}

#===============================
# Run things
#===============================
echo
echo ==========================================================
echo Running workflow
echo ==========================================================
echo

# Everything that follows "ssh user@host" is a command executed on the host.
# If the host is a cluster head node, then srun/sbatch sends the execution to a
# compute node. The wrap option allows for multiple commands (changing to the
# work directory, then launching the job). Sleep commands are inserted to
# simulate long running jobs.

echod "Check connection to cluster"
# This line works, but since it uses srun, it will launch
# a worker node.  This slows down testing/adds additional
# failure points if the user specifies running on the
# head node only.
#ssh -f ${ssh_options} $WFP_whost srun -n 1 hostname
#
# This command only talks to the head node
sshcmd="ssh -f ${ssh_options} $WFP_whost"
${sshcmd} hostname

WFP_jobscript=${jsource}.sbatch 
scp ${jobdir}/slurm-jobs/generic/${WFP_jobscript} ${WFP_whost}:${HOME}

cat > ${jobdir}/wfenv.sh <<EOF
if [ ! -d "$HOME/spack" ]; then
    git clone -c feature.manyFiles=true https://github.com/spack/spack.git
fi
. $HOME/spack/share/spack/setup-env.sh
spack install intel-oneapi-mpi intel-oneapi-compilers
lmod=\$(ls -1 /usr/share/lmod | grep -E '^[0-9]+\.[0-9]+' | sort -V | tail -n 1)
source /usr/share/lmod/\${lmod}/init/bash
yes | spack module lmod refresh intel-oneapi-mpi intel-oneapi-compilers gcc-runtime glibc
export MODULEPATH=\$MODULEPATH:$HOME/spack/share/spack/lmod/linux-rocky8-x86_64/Core
echo \$MODULEPATH
module load gcc-runtime glibc
module load intel-oneapi-mpi intel-oneapi-compilers
EOF

scp ${jobdir}/wfenv.sh ${WFP_whost}:${HOME}