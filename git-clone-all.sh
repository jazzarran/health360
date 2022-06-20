#!/bin/bash
cd ..

repos=(health360-tenant-service.git)
for repo in ${repos[*]}; do
    git clone https://github.com/jazzarran/${repo}
 done
