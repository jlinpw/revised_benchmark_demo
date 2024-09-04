#!/bin/bash

set -ex
source inputs.sh
export UCX_TLS=ud,sm,self

jobdir=${PWD}
export WFP_whost=${resource_publicIp}
WFP_jobscript=${jsource}.sbatch 
echo Running on $WFP_whost

ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
sshcmd="ssh -f ${ssh_options} $WFP_whost"

echo "submitting batch job: $WFP_jobscript..."
jobid=$(${sshcmd} "sbatch -o ${HOME}/slurm_job_%j.out -e ${HOME}/slurm_job_%j.out -N ${nnodes} --ntasks-per-node=${ppn} ${WFP_jobscript};echo Runcmd done2 >> ~/job.exit" | tail -1 | awk -F ' ' '{print $4}')
echo "JOB ID: ${jobid}"

# Prepare kill script
echo "${sshcmd} \"scancel ${jobid}\"" > kill.sh

# Job status file writen by remote script:
while true; do    
    # squeue won't give you status of jobs that are not running or waiting to run
    # qstat returns the status of all recent jobs
    job_status=$($sshcmd squeue | awk -v id="$jobid" '$1 == id {print $5}')
    # If job status is empty job is no longer running
    if [ -z ${job_status} ]; then
        job_status=$($sshcmd "sacct -j ${jobid} --format=state" | tail -n1)
        echo "JOB STATUS: ${job_status}"
        break
    fi
    echo "JOB STATUS: ${job_status}"
    sleep 30
done 

echo "batch job done!"

# copy the job output files back to the workflow run dir
scp ${WFP_whost}:${HOME}/slurm_job_${jobid}.out ${jobdir}
scp ${WFP_whost}:${HOME}/test_build_${jobid}.txt ${jobdir}
scp ${WFP_whost}:${HOME}/${jsource}_ior_${jobid}.txt ${jobdir}
scp ${WFP_whost}:${HOME}/${jsource}_mdtest_${jobid}.txt ${jobdir}
