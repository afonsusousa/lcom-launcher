#!/bin/bash

VM_NAME="${LCOM_VM_NAME:-MINIX-LCOM}"
SSH_CMD="ssh lcom@localhost -p 2222"
START_TYPE="headless"
CONNECT_SSH=false

for arg in "$@"; do
    case $arg in
        --stop)
            echo "Stopping VM '$VM_NAME'..."
            VBoxManage controlvm "$VM_NAME" poweroff 2>/dev/null
            exit 0
            ;;
        --show)
            START_TYPE="gui"
            ;;
        --ssh)
            CONNECT_SSH=true
            ;;
        *)
            echo "Unknown argument: $arg"
            echo "Usage: $0 [--stop] [--show] [--ssh]"
            exit 1
            ;;
    esac
done

VM_STATE=$(VBoxManage showvminfo "$VM_NAME" --machinereadable 2>/dev/null | grep '^VMState=' | cut -d'"' -f2)

if [ "$VM_STATE" == "running" ]; then
    echo "VM '$VM_NAME' is already running."
    if [ "$START_TYPE" == "gui" ]; then
        echo "(VM already running)"
    fi
else
    echo "Starting VM '$VM_NAME' in $START_TYPE mode..."
    VBoxManage startvm "$VM_NAME" --type "$START_TYPE"
fi

if [ "$CONNECT_SSH" = true ]; then
    if [ "$VM_STATE" != "running" ]; then
        echo "Waiting for SSH to become available..."
        sleep 10
    fi
    echo "Connecting via SSH..."
    $SSH_CMD
fi
