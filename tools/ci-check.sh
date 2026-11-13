#!/usr/bin/env bash
set -euo pipefail

cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j"$(nproc)"
QT_QPA_PLATFORM=offscreen ctest --test-dir build --output-on-failure
shellcheck rename.sh
find package/contents -name '*.qml' -print0 | xargs -0 qmllint6
