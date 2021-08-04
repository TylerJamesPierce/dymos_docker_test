#!/bin/bash

set -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

docker run -p 5000:5000 \
    -v ${SCRIPT_DIR}:/app \
    -t dymos-test \
    /bin/bash -c "mkdir -p notebooks && /opt/conda/envs/PY3.8/bin/jupyter notebook \
    --notebook-dir=notebooks --ip='*' --port=5000 \
    --no-browser --allow-root"
