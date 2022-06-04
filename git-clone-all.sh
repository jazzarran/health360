#!/bin/bash
cd ..

repos=(health360-infrastructure.git health360-organization-service.git)
for repo in ${repos[*]}; do
    git clone https://github.com/jazzarran/${repo}
 done
