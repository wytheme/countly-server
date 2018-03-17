#!/bin/bash

#check usage
cpupercentthreshold=80
mempercentthreshold=80
cpuover=""
memover=""
top=$(top -b -n 1 | sed -e "1,7d")
while read line; do
    cpuutil=$(echo ${line} | awk '{print $9}' | cut -d"." -f 1)
    memutil=$(echo ${line} | awk '{print $10}' | cut -d"." -f 1)
    procname=$(echo ${line} | awk '{print $12}' | cut -d"." -f 1)
    pid=$(echo ${line} | awk '{print $1}' | cut -d"." -f 1)
    if [ ${cpuutil} -ge ${cpupercentthreshold} ]; then
        cpuover=${cpuover}${procname}"(${pid}) "
    fi
    if [ ${memutil} -ge ${mempercentthreshold} ]; then
        memover=${memover}${procname}"(${pid}) "
    fi
done <<< "$top"
if ! [ -z "${cpuover}" ]; then
    echo "These processes are above CPU threshold limit: $cpuover"
fi
if ! [ -z "${memover}" ]; then
    echo "These processes are above MEM threshold limit: $memover"
fi

#check process count
appprocthreshold=1
apiprocthreshold=1
workersthreshold=$(nproc)
appproc=0
apiproc=0
workers=0
paths=$(ps -ax | grep node)
while read line; do
    path=$(echo ${line} | awk '{print $NF}')
    if [[ $path = *"frontend/express/app.js"* ]]; then
        appproc=$((appproc+1))
    fi
    if [[ $path = *"api/api.js"* ]] && ! [[ $path = *"/bin/config/"* ]]; then
        apiproc=$((apiproc+1))
    fi
    if [[ $path = *"api/api.js"* ]] && [[ $path = *"/bin/config/"* ]]; then
        workers=$((workers+1))
    fi
done <<< "$paths"
if [ ${appproc} -gt ${appprocthreshold} ]; then
    echo "Too many processes for app.js: "$appproc
elif [ ${appproc} == 0 ]; then
    echo "Process app.js is not found"
fi
if [ ${apiproc} -gt ${apiprocthreshold} ]; then
    echo "Too many processes for api.js: "$apiproc
elif [ ${apiproc} == 0 ]; then
    echo "Process api.js is not found"
fi
if [ ${workers} -gt ${workersthreshold} ]; then
    echo "Too many processes for api.js workers: "$apiproc
elif [ ${workers} -lt ${workersthreshold} ]; then
    echo "Too little processes for api.js workers: "$apiproc"    nproc: "$workersthreshold
fi
