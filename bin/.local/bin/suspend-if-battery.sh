#!/bin/bash
# Suspends the system only when on battery power.
# Used by hypridle — started on idle timeout, killed on resume.

while [ "$(cat /sys/class/power_supply/AC/online)" = "1" ]; do
    sleep 60
done
systemctl suspend
