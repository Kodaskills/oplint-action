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

comment_header="## OPLint Results"
comment_body=""
comment_footer=""

comment_body+="**Score:** $score/100 ($grade)"
if [[ "$partial_coverage" == "true" ]]; then
    comment_body+=" *(partial coverage)*"
fi
comment_body+=$'\n'"**Violations:** $total_violations ($errors errors, $warnings warnings, $infos infos)"

total_issues=$(jq -r '.issues | length // 0' "$OUTPUT_JSON")
if [[ "$total_issues" -gt 0 ]]; then
    comment_body+=$'\n\n'"### Top Issues"

    issue_count=0
    while read -r issue; do
        if [[ -n "$issue" ]] && [[ "$issue" != "null" ]]; then
            severity=$(echo "$issue" | jq -r '.severity // "info"')
            rule_id=$(echo "$issue" | jq -r '.rule_id // ""')
            message=$(echo "$issue" | jq -r '.message // ""')
            file=$(echo "$issue" | jq -r '.file // ""')

            emoji="ℹ️"
            case "$severity" in
                error) emoji="❌" ;;
                warning) emoji="⚠️" ;;
                info) emoji="ℹ️" ;;
            esac

            comment_body+=$'\n'"- $emoji [$rule_id] $message ($file)"

            issue_count=$((issue_count + 1))
            if [[ "$issue_count" -ge 10 ]]; then
                break
            fi
        fi
    done < <(jq -c '.issues // [] | .[]' "$OUTPUT_JSON")

    remaining=$((total_issues - issue_count))
    if [[ "$remaining" -gt 0 ]]; then
        comment_body+=$'\n'"_and $remaining more..._"
    fi
fi

comment_footer="*[View Website](https://oplint.kodaskills.co) • [Configure](https://github.com/kodaskills/oplint-action)*"

full_comment="$comment_header"$'\n\n'"$comment_body"$'\n\n'"$comment_footer"

if [[ -n "${EVENT_NUMBER:-}" ]]; then
    gh pr comment "$EVENT_NUMBER" --body "$full_comment"
    echo "Comment posted to PR #$EVENT_NUMBER"
else
    echo "Warning: No PR number available, skipping comment"
fi
