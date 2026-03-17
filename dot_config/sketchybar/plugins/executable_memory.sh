#!/bin/bash

TOTAL_MEM=$(sysctl -n hw.memsize)
TOTAL_GB=$(echo "scale=0; $TOTAL_MEM / 1073741824" | bc)

PAGE_SIZE=$(sysctl -n hw.pagesize)
VM_STAT=$(vm_stat)
PAGES_FREE=$(echo "$VM_STAT" | awk '/Pages free/ {gsub(/\./,"",$3); print $3}')
PAGES_INACTIVE=$(echo "$VM_STAT" | awk '/Pages inactive/ {gsub(/\./,"",$3); print $3}')
PAGES_SPECULATIVE=$(echo "$VM_STAT" | awk '/Pages speculative/ {gsub(/\./,"",$3); print $3}')
PAGES_PURGEABLE=$(echo "$VM_STAT" | awk '/Pages purgeable/ {gsub(/\./,"",$3); print $3}')

FREE_BYTES=$(( (PAGES_FREE + PAGES_INACTIVE + PAGES_SPECULATIVE + PAGES_PURGEABLE) * PAGE_SIZE ))
USED_BYTES=$(( TOTAL_MEM - FREE_BYTES ))
USED_GB=$(echo "scale=1; $USED_BYTES / 1073741824" | bc)
PCT=$(echo "scale=0; $USED_BYTES * 100 / $TOTAL_MEM" | bc)

sketchybar --set $NAME icon.drawing=off label="mem ${USED_GB}/${TOTAL_GB}G ${PCT}%"
