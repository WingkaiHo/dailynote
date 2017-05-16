#!/bin/bash
IPDETECT=`ifconfig enp2s0 |grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
echo "$IPDETECT"
