#!/bin/bash

CONTAINERS=(20 33 55)

for CT in "${CONTAINERS[@]}"; do
    STATUS=$(pct status "$CT" 2>/dev/null)

    if [ $? -ne 0 ]; then
        echo "[ERROR] CT $CT not found"
        continue
    fi

    if echo "$STATUS" | grep -q "stopped"; then
        echo "[SKIP]  CT $CT already stopped"
    else
        echo "[STOP]  CT $CT..."
        pct stop "$CT"
        echo "[OK]    CT $CT stopped"
    fi
done
