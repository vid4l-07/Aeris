#!/bin/bash

for i in {1..254}; do
	timeout 1 bash -c "ping -c 1 10.10.0.$i" > /dev/null 2>&1 && echo "host 10.10.0.$i connected" &
done

