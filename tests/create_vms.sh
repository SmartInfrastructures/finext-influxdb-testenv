#!/bin/bash

#curl -i -XPOST http://localhost:8086/query --data-urlencode "q=CREATE DATABASE sample_database"

for i in {0..50}
do
	vm_name="server_$i"
	vm_status=$(shuf -i0-1 -n1)
	vm_body="vms,host=$vm_name value=$vm_status"
	curl -i -XPOST 'http://172.28.128.3:8086/write?db=sample_database' --data-binary "$vm_body"
done
