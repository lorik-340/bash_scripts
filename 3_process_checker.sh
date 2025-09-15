#!/bin/bash

# Script to check and display all processes for the current user

# Get processes for current user using ps aux and grep
echo "========================================="
echo "Current processes for user '$USER' using ps aux | grep:"
echo "========================================="

ps aux | grep "^$USER" | grep -v grep

echo

echo "=============================================="
echo "Alternative view: "
echo "=============================================="

# Using ps with more specific filtering
ps -u "$USER" -o pid,ppid,pcpu,pmem,stat,start_time,time,cmd