<div align="center">

<img src="https://raw.githubusercontent.com/kodaskills/oplint/main/docs/logo.svg" alt="oplint logo" width="128" height="128" />

# oplint-action

### GitHub Action to run **OPLint** on your Obsidian plugin — compliance score, PR comments, badges, and report artifacts in one step.

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-obsidian--plugin--lint-purple?style=for-the-badge&logo=github)](https://github.com/marketplace/actions/obsidian-plugin-lint)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](LICENSE)

</div>

---

## ✨ What it does

| Feature | Description |
|---------|-------------|
| **Lint** | Runs `oplint lint` on your plugin and fails the job on errors |
| **Summary** | Writes score, grade, and violation list to the GitHub step summary |
| **PR comment** | Posts a formatted comment with results on every pull request |
| **Badge** | Static badge URL or dynamic endpoint JSON — deploy anywhere |
| **Reports** | Saves lint reports as workflow artifacts (Markdown, HTML, JSON) |

---

## 🚀 Quick Start

```yaml
name: Plugin compliance
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: kodaskills/oplint-action@v1
```

Installs the latest OPLint, lints the current directory, and fails the job if any `error`-severity rule is violated.

---

## ⚙️ Inputs

| Input | Default | Description |
|-------|---------|-------------|
| `path` | `.` | Path to the Obsidian plugin directory to lint |
| `version` | _(latest)_ | Pin a specific OPLint version (e.g. `1.2.0`) |
| `summary` | `false` | Write results to the GitHub step summary |
| `comment` | `false` | Post a results comment on pull requests |
| `token` | `github.token` | GitHub token for PR comments |
| `badge_enabled` | `false` | Generate a badge |
| `badge_style` | `for-the-badge` | Badge style: `flat` · `flat-square` · `for-the-badge` · `plastic` · `social` |
| `badge_endpoint` | `false` | Also generate a Shields.io endpoint JSON file |
| `badge_endpoint_output` | `.oplint-badge.json` | Output path for the endpoint JSON file |
| `reporting_enabled` | `false` | Generate additional report files |
| `reporting_formats` | `md` | Comma-separated formats: `md` · `html` · `json` |
| `reporting_output_dir` | `.` | Directory for generated report files |
| `fail_on` | `error` | Minimum severity that fails the job: `error` · `warning` · `info` · `none` |

---

## 📤 Outputs

| Output | Description |
|--------|-------------|
| `score` | Compliance score (0–100) |
| `grade` | Letter grade (`A+`, `A`, `B`, `C`, `D`, `F`) |
| `partial_coverage` | `true` when some rules are disabled or skipped |
| `violations` | Total number of violations found |
| `badge_url` | Shields.io static badge URL (when `badge_enabled` is `true`) |
| `badge_json_path` | Path to the endpoint badge JSON file (when `badge_endpoint` is `true`) |

---

## 🏷️ Badge

Two modes — pick one or both:

### Static badge URL

Shields.io generates the badge on the fly from a URL. Simple, no hosting needed.

```yaml
- uses: kodaskills/oplint-action@v1
  id: oplint
  with:
    badge_enabled: true
    badge_style: for-the-badge
```

Use the output in your README:

```markdown
[![oplint](PASTE_BADGE_URL_HERE)](https://oplint.kodaskills.co)
```

### Dynamic endpoint badge

Generates a `.oplint-badge.json` file in the [Shields.io endpoint format](https://shields.io/badges/endpoint-badge). You host the file — the badge URL points to it and stays live automatically on every push.

```yaml
- uses: kodaskills/oplint-action@v1
  id: oplint
  with:
    badge_enabled: true
    badge_endpoint: true
    badge_endpoint_output: .oplint-badge.json
    badge_style: for-the-badge
```

The generated file looks like:

```json
{
  "schemaVersion": 1,
  "label": "oplint",
  "message": "A · 95%",
  "color": "green",
  "style": "for-the-badge",
  "logoSvg": "<svg ...>"
}
```

Then point your README badge at the hosted URL:

```markdown
[![oplint](https://img.shields.io/endpoint?url=RAW_URL_TO_YOUR_JSON)](https://oplint.kodaskills.co)
```

#### Deploy to GitHub Pages (commit to repo)

```yaml
- uses: actions/checkout@v4
- uses: kodaskills/oplint-action@v1
  id: oplint
  with:
    badge_enabled: true
    badge_endpoint: true
    badge_endpoint_output: .oplint-badge.json

- name: Commit badge
  run: |
    git config user.name  "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"
    git add .oplint-badge.json
    git diff --cached --quiet || git commit -m "chore: update oplint badge"
    git push
```

README badge URL:
```
https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/YOUR_ORG/YOUR_REPO/main/.oplint-badge.json
```

#### Deploy to AWS S3

```yaml
- uses: kodaskills/oplint-action@v1
  id: oplint
  with:
    badge_enabled: true
    badge_endpoint: true
    badge_endpoint_output: .oplint-badge.json

- uses: aws-actions/configure-aws-credentials@v4
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1

- name: Upload badge to S3
  run: |
    aws s3 cp .oplint-badge.json s3://your-bucket/badges/oplint.json \
      --content-type application/json \
      --cache-control "no-cache, max-age=0"
```

README badge URL:
```
https://img.shields.io/endpoint?url=https://your-bucket.s3.amazonaws.com/badges/oplint.json
```

#### Deploy to Cloudflare R2 / any CDN

```yaml
- uses: kodaskills/oplint-action@v1
  id: oplint
  with:
    badge_enabled: true
    badge_endpoint: true
    badge_endpoint_output: .oplint-badge.json

- name: Upload badge to R2
  run: |
    aws s3 cp .oplint-badge.json s3://your-r2-bucket/badges/oplint.json \
      --endpoint-url https://<account>.r2.cloudflarestorage.com \
      --content-type application/json
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.R2_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.R2_SECRET_ACCESS_KEY }}
```

---

## 💬 PR Comment

Post a formatted comment with score, grade, and top violations on every PR:

```yaml
- uses: kodaskills/oplint-action@v1
  with:
    comment: true
```

Requires `permissions: pull-requests: write` in your workflow.

---

## 📄 GitHub Summary

Write results to the job summary page:

```yaml
- uses: kodaskills/oplint-action@v1
  with:
    summary: true
```

---

## 📁 Report Artifacts

Save lint reports in one or more formats:

```yaml
- uses: kodaskills/oplint-action@v1
  with:
    reporting_enabled: true
    reporting_formats: md,html,json
    reporting_output_dir: reports/

- uses: actions/upload-artifact@v4
  with:
    name: oplint-report
    path: reports/
```

**Formats:** `md` · `html` · `json`

---

## 🔧 Full Example

```yaml
name: Plugin compliance
on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: write
  pull-requests: write

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Run OPLint
        id: oplint
        uses: kodaskills/oplint-action@v1
        with:
          path: .
          summary: true
          comment: true
          badge_enabled: true
          badge_endpoint: true
          badge_endpoint_output: .oplint-badge.json
          badge_style: for-the-badge
          reporting_enabled: true
          reporting_formats: md,html
          reporting_output_dir: reports/

      - name: Commit badge
        if: github.ref == 'refs/heads/main'
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add .oplint-badge.json
          git diff --cached --quiet || git commit -m "chore: update oplint badge"
          git push

      - name: Upload report
        uses: actions/upload-artifact@v4
        with:
          name: oplint-report
          path: reports/
```

---

## 📊 Score & Grades

| Score | Grade | Label |
|-------|-------|-------|
| 100 | A+ | Perfect |
| 90–99 | A | Excellent |
| 80–89 | B | Good |
| 70–79 | C | Fair |
| 60–69 | D | Poor |
| 0–59 | F | Critical |

The job **fails** when any `error`-severity violation is found. Warnings and infos are reported but do not fail the build. Use an `.oplint.yaml` config file to disable or downgrade rules.

For the full scoring formula, see the [main README](https://github.com/kodaskills/oplint#-how-the-compliance-score-works).

---

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Maintained with ⚡ by the [Kodaskills](https://github.com/kodaskills) team**

</div>
