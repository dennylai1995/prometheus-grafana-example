#!/bin/bash

set -e

# NOTE: different "-p [project name]" is necessary
# https://medium.com/@lotus3698/%E5%9C%A8-docker-compose-up-%E9%81%87%E5%88%B0%E5%AE%B9%E5%99%A8%E8%A2%AB%E5%AE%B9%E5%99%A8%E6%93%A0%E6%8E%89%E7%9A%84%E6%83%85%E6%B3%81-779708acaf2a

# NOTE: to link multiple compose yaml files as one
# https://medium.com/@mehdi_hosseini/how-to-link-multiple-docker-compose-files-7250f10063a9

docker-compose -p observability_stack -f docker-compose.yml -f docker-compose.exporters.yml down

echo "[Observability stack stopped]"