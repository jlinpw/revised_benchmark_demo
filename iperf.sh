#!/bin/bash

jobdir=${PWD}
export WFP_whost=${resource_publicIp}

# copy iperf to cluster
${jobdir}/run_iperf.sh ${WFP_whost}:${HOME}

# execute the script
bash run_iperf.sh > iperf.out

echo Done!