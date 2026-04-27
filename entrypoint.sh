#!/bin/bash
set -euo pipefail

INPUT_PATH="${INPUT_PATH:-.}"
INPUT_SUMMARY="${INPUT_SUMMARY:-false}"
INPUT_COMMENT="${INPUT_COMMENT:-false}"
INPUT_BADGE_ENABLED="${INPUT_BADGE_ENABLED:-false}"
INPUT_BADGE_STYLE="${INPUT_BADGE_STYLE:-for-the-badge}"
INPUT_BADGE_ENDPOINT="${INPUT_BADGE_ENDPOINT:-false}"
INPUT_BADGE_ENDPOINT_OUTPUT="${INPUT_BADGE_ENDPOINT_OUTPUT:-.oplint-badge.json}"
INPUT_REPORTING_ENABLED="${INPUT_REPORTING_ENABLED:-false}"
INPUT_REPORTING_FORMATS="${INPUT_REPORTING_FORMATS:-md}"
INPUT_REPORTING_OUTPUT_DIR="${INPUT_REPORTING_OUTPUT_DIR:-.}"
INPUT_FAIL_ON="${INPUT_FAIL_ON:-error}"

jq_installed() {
    command -v jq &> /dev/null
}

gh_installed() {
    command -v gh &> /dev/null
}

SOURCE_DIR="$(dirname "$0")"
OPLINT_BIN="$HOME/.local/bin/oplint"

if [[ ! -x "$OPLINT_BIN" ]]; then
    echo "Error: OPLint binary not found at $OPLINT_BIN"
    exit 1
fi

OUTPUT_JSON="$RUNNER_TEMP/report.json"
"$OPLINT_BIN" lint "$INPUT_PATH" -f json -o "$RUNNER_TEMP" > /dev/null 2>&1 || true

if [[ ! -f "$OUTPUT_JSON" ]]; then
    echo "Error: Failed to generate JSON output"
    exit 1
fi

SCORE=$(jq -r '.summary.score // 0' "$OUTPUT_JSON")
GRADE=$(jq -r '.summary.grade // "F"' "$OUTPUT_JSON")
PARTIAL_COVERAGE=$(jq -r '.summary.partial_coverage // false' "$OUTPUT_JSON")
TOTAL_VIOLATIONS=$(jq -r '.summary.total_violations // 0' "$OUTPUT_JSON")
ERRORS=$(jq -r '.summary.errors // 0' "$OUTPUT_JSON")
WARNINGS=$(jq -r '.summary.warnings // 0' "$OUTPUT_JSON")
INFOS=$(jq -r '.summary.infos // 0' "$OUTPUT_JSON")
PLUGIN_NAME=$(jq -r '.summary.plugin_name // "Unknown"' "$OUTPUT_JSON")

VIOLATIONS="$TOTAL_VIOLATIONS"
export OPLINT_BIN INPUT_PATH SCORE GRADE PARTIAL_COVERAGE VIOLATIONS \
  INPUT_BADGE_ENABLED INPUT_BADGE_STYLE INPUT_BADGE_ENDPOINT INPUT_BADGE_ENDPOINT_OUTPUT \
  INPUT_REPORTING_ENABLED INPUT_REPORTING_FORMATS INPUT_REPORTING_OUTPUT_DIR

echo "OPLint Results:"
echo "  Score: $SCORE/100 ($GRADE)"
echo "  Errors: $ERRORS, Warnings: $WARNINGS, Infos: $INFOS"
echo "  Partial Coverage: $PARTIAL_COVERAGE"

{
  echo "score=$SCORE"
  echo "grade=$GRADE"
  echo "partial_coverage=$PARTIAL_COVERAGE"
  echo "violations=$VIOLATIONS"
} >> "$GITHUB_OUTPUT"

if [[ "$INPUT_SUMMARY" == "true" ]] && [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    bash "$SOURCE_DIR/lib/summary.sh"
fi

if [[ "$INPUT_COMMENT" == "true" ]] && [[ -n "${EVENT_NUMBER:-}" ]]; then
    if gh_installed; then
        bash "$SOURCE_DIR/lib/comment.sh"
    else
        echo "Warning: gh CLI not installed, skipping PR comment"
    fi
fi

if [[ "$INPUT_BADGE_ENABLED" == "true" ]]; then
    bash "$SOURCE_DIR/lib/badge.sh"
fi

if [[ "$INPUT_REPORTING_ENABLED" == "true" ]]; then
    bash "$SOURCE_DIR/lib/report.sh"
fi

case "$INPUT_FAIL_ON" in
    none)
        ;;
    error)
        [[ "$ERRORS" -gt 0 ]] && exit 1 ;;
    warning)
        [[ "$ERRORS" -gt 0 || "$WARNINGS" -gt 0 ]] && exit 1 ;;
    info)
        [[ "$ERRORS" -gt 0 || "$WARNINGS" -gt 0 || "$INFOS" -gt 0 ]] && exit 1 ;;
    *)
        echo "Warning: unknown fail_on value '$INPUT_FAIL_ON', defaulting to error"
        [[ "$ERRORS" -gt 0 ]] && exit 1 ;;
esac

exit 0