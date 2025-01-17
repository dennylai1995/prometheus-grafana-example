#!/bin/bash

set -e

# NOTE: different "-p [project name]" is necessary
# https://medium.com/@lotus3698/%E5%9C%A8-docker-compose-up-%E9%81%87%E5%88%B0%E5%AE%B9%E5%99%A8%E8%A2%AB%E5%AE%B9%E5%99%A8%E6%93%A0%E6%8E%89%E7%9A%84%E6%83%85%E6%B3%81-779708acaf2a
docker-compose -p observability_exporters -f docker-compose.exporters.yml up -d
docker-compose -p observability_core up -d

echo "[Observability stack started]"