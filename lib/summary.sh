#!/bin/bash
set -euo pipefail

OUTPUT_JSON="$RUNNER_TEMP/report.json"

score=$(jq -r '.summary.score // 0' "$OUTPUT_JSON")
grade=$(jq -r '.summary.grade // "F"' "$OUTPUT_JSON")
grade_label=$(jq -r '.summary.grade_label // ""' "$OUTPUT_JSON")
partial_coverage=$(jq -r '.summary.partial_coverage // false' "$OUTPUT_JSON")
total_violations=$(jq -r '.summary.total_violations // 0' "$OUTPUT_JSON")
errors=$(jq -r '.summary.errors // 0' "$OUTPUT_JSON")
warnings=$(jq -r '.summary.warnings // 0' "$OUTPUT_JSON")
infos=$(jq -r '.summary.infos // 0' "$OUTPUT_JSON")
total_files=$(jq -r '.summary.total_files // 0' "$OUTPUT_JSON")
duration_ms=$(jq -r '.summary.duration_ms // 0' "$OUTPUT_JSON")

coverage_label=""
if [[ "$partial_coverage" == "true" ]]; then
    coverage_label=" *(partial coverage)*"
fi

cat << EOF | tee -a "$GITHUB_STEP_SUMMARY"
## OPLint Results

| Metric | Value |
|--------|-------|
| **Score** | $score/100 ($grade)$coverage_label |
| **Files** | $total_files |
| **Violations** | $total_violations ($errors errors, $warnings warnings, $infos infos) |
| **Duration** | ${duration_ms}ms |

EOF

issues_json=$(jq -c '.issues // [] | .[0:10]' "$OUTPUT_JSON")
if [[ "$issues_json" != "[]" ]] && [[ -n "$issues_json" ]]; then
    echo "### Top Issues" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    
    jq -r '.issues // [] | .[0:10] | .[] | "* [\(.severity)] \(.rule_id): \(.message) (\(.file))"' "$OUTPUT_JSON" >> "$GITHUB_STEP_SUMMARY" 2>/dev/null || true
    echo "" >> "$GITHUB_STEP_SUMMARY"
fi

if [[ "$score" -lt 100 ]]; then
    echo "### Recommendations" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    cat << 'EOF' >> "$GITHUB_STEP_SUMMARY"
To improve your score, address the errors above. Run `oplint lint .` locally to see all issues.

Tips:
- Use `oplint init` to create a config file
- Whitelist rules you intentionally bypass with `whitelist` in `.oplint.yaml`
- Check the [rules reference](https://oplint.kodaskills.co/#rules) for explanations
EOF
fi

echo "Summary written to GitHub step summary"