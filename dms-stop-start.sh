#!/usr/bin/bash

# How to use this script:
# For stop all the DMS replication tasks: bash dms-stop-start.sh stop
# For start all the DMS replication tasks: bash dms-stop-start.sh start

action=$1

fetch_dms_tasks(){
    echo "Fetching DMS replication tasks ..."
    aws dms describe-replication-tasks | grep ReplicationTaskArn | cut -d '"' -f4 > /tmp/dms-tasks-arn.txt
}

fetch_dms_task_status(){
    aws dms describe-replication-tasks --filters Name=replication-task-arn,Values=$task_arn --query 'ReplicationTasks[].[ReplicationTaskIdentifier,Status]' --output text > /tmp/dms-task-status.txt
    dms_task_name=$(cut -f1 -d$'\t' /tmp/dms-task-status.txt)
    dms_task_status=$(cut -f2 -d$'\t' /tmp/dms-task-status.txt)
    rm -rf /tmp/dms-task-status.txt
}

if [ "$action" == "stop" ]
then
    fetch_dms_tasks
    echo "Stopping DMS replication tasks ..."
    for task_arn in $(cat /tmp/dms-tasks-arn.txt)
    do
        fetch_dms_task_status
        if [ "$dms_task_status" != "stopped" ]
        then
            aws dms stop-replication-task --replication-task-arn $task_arn > /dev/null 2>&1
            echo "$dms_task_name is stopping ..."
        fi
    done
elif [ "$action" == "start" ]
then
    fetch_dms_tasks
    echo "Starting DMS replication tasks ..."
    for task_arn in $(cat /tmp/dms-tasks-arn.txt)
    do
        fetch_dms_task_status
        if [ "$dms_task_status" == "stopped" ]
        then
            aws dms start-replication-task --replication-task-arn $task_arn --start-replication-task-type resume-processing > /dev/null 2>&1
            echo "$dms_task_name is starting ..."
        fi
    done
else
    echo "Incorrect Action"
fi

echo "Cleaing up ..."
rm -rf /tmp/dms-tasks.txt
rm -rf /tmp/dms-task-status.txt
