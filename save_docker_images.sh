#!/bin/bash

set -e

OUTPUT_FILE="observability-images.tar.gz"

# SOURCE: https://gist.github.com/jcataluna/1dc2f31694a1c301ab34dac9ccb385ea?permalink_comment_id=2222429#gistcomment-2222429
for img in $(docker-compose -f docker-compose.yml -f docker-compose.exporters.yml config | awk '{if ($1 == "image:") print $2;}'); do
    images="$images $img"
done

echo "Tarring docker images: $images"

docker save $images | gzip > "$OUTPUT_FILE"

echo ">> Result tar file: [$(pwd)/$OUTPUT_FILE]"