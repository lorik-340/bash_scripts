#!/bin/bash

# Simple process checker with sorting and limit options

echo "Processes for user: $USER"
echo "========================"

# Ask user for sorting preference
echo ""
echo "Sort by:"
echo "1 - CPU usage (high to low)"
echo "2 - Memory usage (high to low)"
echo "3 - Show without sorting"
echo ""

read -p "Enter choice (1, 2, or 3): " choice

# Ask user how many processes to show
echo ""
read -p "How many processes to show? [Enter for all]: " num_processes

# If user didn't enter a number, show all processes
if [ -z "$num_processes" ]; then
    num_processes="all"
fi

echo ""
echo "=========================================="

# Display processes based on user choice
case $choice in
    1)
        if [ "$num_processes" = "all" ]; then
            echo "All processes sorted by CPU usage:"
            ps -u "$USER" -o pid,%cpu,%mem,cmd --sort=-%cpu
        else
            echo "Top $num_processes processes by CPU usage:"
            ps -u "$USER" -o pid,%cpu,%mem,cmd --sort=-%cpu | head -n $((num_processes + 1))
        fi
        ;;
    2)
        if [ "$num_processes" = "all" ]; then
            echo "All processes sorted by Memory usage:"
            ps -u "$USER" -o pid,%cpu,%mem,cmd --sort=-%mem
        else
            echo "Top $num_processes processes by Memory usage:"
            ps -u "$USER" -o pid,%cpu,%mem,cmd --sort=-%mem | head -n $((num_processes + 1))
        fi
        ;;
    3)
        if [ "$num_processes" = "all" ]; then
            echo "All processes:"
            ps -u "$USER" -o pid,%cpu,%mem,cmd
        else
            echo "First $num_processes processes:"
            ps -u "$USER" -o pid,%cpu,%mem,cmd | head -n $((num_processes + 1))
        fi
        ;;
    *)
        echo "Invalid choice. Showing first 10 processes:"
        ps -u "$USER" -o pid,%cpu,%mem,cmd | head -n 11
        num_processes=10
        ;;
esac

# Show total process count
echo "=========================================="
count=$(ps -u "$USER" | wc -l)
total=$((count - 1))

if [ "$num_processes" = "all" ]; then
    echo "Total processes: $total"
else
    echo "Showing: $num_processes of $total processes"
fi
echo "=========================================="