# Changelog

## 0.2.2 (2026-10-09)

- `snakemake-data-pipeline`: run `snakemake --lint`; add `log:` directives, and fix or consciously
  accept the conda/container lint; section on the official best practices applied to an overlay.

## 0.2.1 (2026-10-09)

- `reproducible-data-preparation`: downloads must retry transient failures with exponential
  backoff and jitter (honouring `Retry-After`), pause between requests, limit concurrency, and
  write partial files under a temporary name; stricter pacing for many files.
- `snakemake-data-pipeline`: limit parallel downloads with a `downloads` resource; keep backoff
  in the script rather than Snakemake `--retries`; new test step: live end-to-end run from a
  sandbox, only after asking the user.

## 0.2.0 (2026-10-09)

- New skill `snakemake-data-pipeline`: Snakemake as an overlay of existing download and
  transformation scripts (one job per external file, `--only`/`--no-check`, side-effect manifests
  and RO-Crate metadata, previews depending on their writers, mtime-only profile, tests), with a
  tested example Snakefile and profile; general Snakemake authoring deferred to bioSkills
  `snakemake-workflows`.
- `reproducible-data-preparation` now points to it instead of listing the workflow details.

## 0.1.0 (2026-10-09)

First release.

- Skills: `reproducible-data-preparation`, `ro-crate-provenance` (RO-Crate 1.3, Process Run
  Crate 0.6, with `references/validator-findings.md` for roc-validator 0.12.2) and
  `data-license-investigation`, each with `agents/openai.yaml`.
- Claude Code plugin and marketplace (`.claude-plugin/`); Codex plugin and marketplace
  (`.codex-plugin/`, `.agents/plugins/`).
- `examples/`: two RO-Crates with previews, download manifests, schema captures, validation
  reports, a daylight-saving time-basis check, and a licence investigation record.
- `codemeta.json` (CodeMeta 3.1); MIT licence.
- `AGENTS.md`/`CLAUDE.md` development guide and `tools/check.sh`.
