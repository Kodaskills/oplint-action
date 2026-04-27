#!/bin/bash
set -euo pipefail

OUTPUT_JSON="$RUNNER_TEMP/report.json"

style="${INPUT_BADGE_STYLE:-for-the-badge}"
endpoint_enabled="${INPUT_BADGE_ENDPOINT:-false}"
endpoint_output="${INPUT_BADGE_ENDPOINT_OUTPUT:-.oplint-badge.json}"

score=$(jq -r '.summary.score // 0' "$OUTPUT_JSON")
grade=$(jq -r '.summary.grade // "F"' "$OUTPUT_JSON")
partial_coverage=$(jq -r '.summary.partial_coverage // false' "$OUTPUT_JSON")

color="brightgreen"
if [[ "$score" -lt 50 ]]; then
    color="red"
elif [[ "$score" -lt 70 ]]; then
    color="orange"
elif [[ "$score" -lt 90 ]]; then
    color="yellow"
elif [[ "$score" -lt 100 ]]; then
    color="green"
fi

logo_base64="PHN2ZyB2aWV3Qm94PSIzNiAzMiA1NiA2NCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNNjQgMzYgTDg4IDQ0IFY2NCBDODggNzggNzYgODggNjQgOTIgQzUyIDg4IDQwIDc4IDQwIDY0IFY0NCBaIiBmaWxsPSJub25lIiBzdHJva2U9IndoaXRlIiBzdHJva2Utd2lkdGg9IjQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48cGF0aCBkPSJNNTIgNjQgTDYyIDc0IEw3OCA1NiIgZmlsbD0ibm9uZSIgc3Ryb2tlPSJ3aGl0ZSIgc3Ryb2tlLXdpZHRoPSI0IiBzdHJva2UtbGluZWNhcD0icm91bmQiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48L3N2Zz4="

prefix="oplint"
message="$grade ~ $score%"

if [[ "$partial_coverage" != "true" ]]; then
    message="$grade · $score%"
fi

urlencode() { printf '%s' "$1" | jq -rRs '@uri'; }

escaped_label=$(urlencode "$prefix")
escaped_message=$(urlencode "$message")
escaped_logo=$(urlencode "data:image/svg+xml;base64,${logo_base64}")

badge_url="https://img.shields.io/badge/$escaped_label-$escaped_message-$color?style=$style&logo=$escaped_logo"

echo "badge_url=$badge_url" >> "$GITHUB_OUTPUT"

badge_markdown="[![oplint]($badge_url)](https://oplint.kodaskills.co)"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "" >> "$GITHUB_STEP_SUMMARY"
    echo "$badge_markdown" >> "$GITHUB_STEP_SUMMARY"
fi

echo "Badge generated: $badge_url"

if [[ "$endpoint_enabled" == "true" ]]; then
    logo_svg='<svg viewBox="36 32 56 64" xmlns="http://www.w3.org/2000/svg"><path d="M64 36 L88 44 V64 C88 78 76 88 64 92 C52 88 40 78 40 64 V44 Z" fill="none" stroke="white" stroke-width="4" stroke-linejoin="round"/><path d="M52 64 L62 74 L78 56" fill="none" stroke="white" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/></svg>'

    jq -n \
        --arg lbl "$prefix" \
        --arg msg "$message" \
        --arg col "$color" \
        --arg sty "$style" \
        --arg svg "$logo_svg" \
        '{"schemaVersion": 1, "label": $lbl, "message": $msg, "color": $col, "style": $sty, "logoSvg": $svg}' \
        > "$endpoint_output"

    echo "badge_json_path=$endpoint_output" >> "$GITHUB_OUTPUT"
    echo "Endpoint badge JSON written to $endpoint_output"
fi
