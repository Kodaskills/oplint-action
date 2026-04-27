#!/bin/bash
set -euo pipefail

formats="${INPUT_REPORTING_FORMATS:-md}"
output_dir="${INPUT_REPORTING_OUTPUT_DIR:-.}"

"$OPLINT_BIN" lint "$INPUT_PATH" -f "$formats" -o "$output_dir"
