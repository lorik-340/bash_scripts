#!/bin/bash

# # Script to check and display all processes for the current user with sorting options

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

echo ""
echo "=========================================="

# Display processes based on user choice
case $choice in
    1)
        echo "Sorted by CPU usage:"
        ps -u "$USER" -o pid,%cpu,%mem,cmd --sort=-%cpu
        ;;
    2)
        echo "Sorted by Memory usage:"
        ps -u "$USER" -o pid,%cpu,%mem,cmd --sort=-%mem
        ;;
    3)
        echo "Process list:"
        ps -u "$USER" -o pid,%cpu,%mem,cmd
        ;;
    *)
        echo "Invalid choice. Showing default list:"
        ps -u "$USER" -o pid,%cpu,%mem,cmd
        ;;
esac

# Show total process count
echo "=========================================="
count=$(ps -u "$USER" | wc -l)
echo "Total processes: $((count - 1))"
echo "=========================================="