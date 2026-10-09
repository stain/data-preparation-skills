---
name: snakemake-data-pipeline
description: Add Snakemake to a data-preparation pipeline of existing download and transformation scripts, as an overlay that rebuilds only what is missing or out of date, never repeats external downloads, and keeps provenance files (manifests, RO-Crate metadata) intact. Use when wrapping download/clean/transform scripts in Snakemake, when a workflow re-downloads or deletes files unexpectedly, when outputs are written as side effects, or when planning Workflow Run Crate provenance for such a pipeline.
license: MIT
metadata:
  author: "Stian Soiland-Reyes (https://orcid.org/0000-0001-9842-9718), The University of Manchester"
  version: "0.2.1"
---

# Snakemake for data-preparation pipelines

How to put [Snakemake](https://snakemake.readthedocs.io/) on top of working data-preparation
scripts (download → extract → filter/validate → integrate → product) so that people can rebuild
one part without running everything, without re-fetching external data and without losing
provenance. Complements `reproducible-data-preparation` (the scripts and their manifests) and
`ro-crate-provenance` (the metadata they write).

For **general Snakemake authoring** (wildcards and `expand()`, checkpoints, resources, HPC
executor plugins, conda/container deployment, Snakemake vs Nextflow), use a general skill such as
[bioSkills `snakemake-workflows`](https://github.com/GPTomics/bioSkills/tree/main/workflow-management/snakemake-workflows)
(MIT) or the Snakemake documentation. This skill covers what is specific to data preparation.

Tested with Snakemake 9.27 (`snakemake-minimal` from **bioconda**; it is not on conda-forge, so
add both channels: `conda-forge` first, then `bioconda`).

## 1. Overlay first, rewrite later

Keep the scripts runnable on their own and add a `workflow/Snakefile` that only declares their
inputs and outputs and calls them in `shell:`. Benefits: no big-bang rewrite, the scripts' own
checks and manifests keep working, and staff can still run a script by hand. Snakemake finds
`workflow/Snakefile` from the repository root, and uses `workflow/profiles/default/config.yaml`
automatically:

```yaml
cores: 1                 # scripts sharing manifests/metadata must not run concurrently
rerun-triggers: [mtime]  # editing a script must not re-run (and re-download) everything
printshellcmds: true
```

The default rerun triggers (since 7.8) also include code, params, input and software
environment: convenient for analysis, dangerous for downloads. Use `--forcerun RULE` to rebuild
a step deliberately.

See [`assets/Snakefile.example`](assets/Snakefile.example) (a tested overlay of scripts for road
traffic counts and air-quality downloads) and [`assets/profile-config.yaml`](assets/profile-config.yaml).

## 2. Never repeat external downloads

Snakemake **deletes a job's declared outputs before running it**. A single "download everything"
rule therefore throws away every existing file (gigabytes, or data that can no longer be
retrieved identically) as soon as one output is missing. Instead:

- **One job per external file**: a wildcard rule whose output is one file, with
  `wildcard_constraints` listing the allowed file names (so it cannot match other paths), and the
  script called as `download.py --only {wildcards.file}`.
- **No upstream contact under Snakemake**: call scripts with a `--no-check` option, so a file that
  is present with a manifest entry is neither re-downloaded nor checked upstream. Check for
  upstream changes (new release, revised values) by running the scripts directly, outside the
  workflow.
- **Extraction as its own rule** (`input: X.zip`, `output: extracted/X.csv`), calling the same
  script with `--only X.zip --no-check`, so a missing extracted file does not trigger a download.
- **Downloads whose file names are only known at run time** (e.g. web-form requests derived from
  another table): declare a small summary report as the output, let the script skip files that
  exist, and make the rule depend on the table that defines the requests.
- **Keep backoff in the script, and limit parallel downloads.** One job per file means Snakemake
  may start many download jobs at once (`--cores N`). Give the download rule a
  `resources: downloads=1` and run with `--resources downloads=2` (or similar) so the server sees
  a handful of connections, and let the script do retry-with-backoff and pacing as described in
  `reproducible-data-preparation`. Avoid relying on `--retries`/`restart_times` for network
  errors: it restarts the job immediately, without waiting, and also retries permanent failures.
- Put every download in `rule all` (or a `downloads` target), otherwise a deleted file nobody
  depends on is silently not replaced.

## 3. Side effects: manifests and provenance metadata

Scripts that keep provenance usually **read their previous state** (download manifest, previous
`ro-crate-metadata.json`) to keep history, hashes and earlier actions. Declaring those files as
outputs would let Snakemake delete them before the job runs. So, in the overlay:

- **do not declare** manifests, schema captures and crate metadata as outputs; they are written
  as side effects;
- declare the **data files and reports** as outputs;
- make anything that depends on a side effect (e.g. an HTML preview of a crate) also depend on the
  jobs that rewrite it, with an input function:

  ```python
  CRATE_WRITERS = {"data/raw/src": DOWNLOADS + EXTRACTED}
  rule crate_preview:
      input: "{crate}/ro-crate-metadata.json",
             lambda w: CRATE_WRITERS.get(w.crate, [])
      output: "{crate}/ro-crate-preview.html"
      shell: "python -I scripts/crate_common.py preview {wildcards.crate}"
  ```

- generate previews in their own rule (`--no-preview` in the scripts), so a preview's network
  needs do not slow down every download job.

Later, make metadata generation a **separate rule that is a pure function** of the data and
manifests (move remembered facts such as agent, tool versions and action times into the
manifests); then the metadata can be a declared output, and a run can be described as a
[Workflow Run Crate](https://w3id.org/ro/wfrun/workflow) with the Snakefile as the workflow.
Do not assume Snakemake writes Workflow Run Crates for you; plan your own writer.

## 4. Rules for the remaining steps

- Transformations and validation: ordinary rules with the extracted/staged files as inputs and
  the interim files, validation CSVs and inventories as outputs. They are cheap to rerun and
  should be deterministic.
- Write outputs atomically (temporary name, then rename) so a failed job never leaves a
  plausible partial file.
- `cores: 1` while scripts share manifests or metadata; raise it only for independent rules (or
  use a resource such as `manifest_lock=1`).
- Use `python -I` in `shell:` when scripts read untrusted downloads.

### Snakemake best practices, applied to an overlay

From the [Snakemake best practices](https://snakemake.readthedocs.io/en/stable/snakefiles/best_practices.html)
(checked October 2026), what to adopt for data preparation:

- **Adopt:** `snakemake --lint` (§ 5) and `snakefmt` before sharing; short, informative file
  names with one separator style; the standard layout (`workflow/Snakefile`, `workflow/rules/`,
  `workflow/profiles/`, `config/`, `results/`, `logs/`); helper Python functions in
  `workflow/rules/common.smk` instead of `lambda`s in rules (the `crate_preview` input in
  `assets/Snakefile.example` uses a lambda for brevity: move it there once it grows); source
  lists, dates and sites in `config/` or a sample-sheet table rather than hard-coded in rules;
  a small test dataset or date range in the repository, run by CI (GitHub Actions) if the
  repository is shared.
- **Runtime settings stay out of config files:** threads, resources and output folders belong
  on the command line or in the profile (`--set-resources`, `--set-default-resources`,
  `--directory`); the `downloads` resource and `cores` of § 2 and § 4 are examples.
- **Adopt with judgement:** versioned conda/container annotations for every rule (see the lint
  advice in § 5); interactive reports with categories and labels (`report:`), useful when the
  workflow produces results people browse; wrappers (little to reuse for download scripts).
- **Layout trade-off:** the guidance assumes workflows write into `results/`. An overlay keeps
  the scripts' existing paths (`raw/`, manifests, crates) so provenance files stay valid; do
  not move them just to match the layout.

## 5. Test the overlay

Run these before relying on it, and record the results:

1. `snakemake -n` on a complete checkout: **nothing to be done** (or only cheap previews).
2. Delete one small downloaded file: only that file is fetched; its manifest/crate entry is
   updated; the preview is regenerated **in the same run**.
3. `snakemake --forcerun <transform rule>`: downstream rebuilt, outputs **byte-identical**
   (`git status` shows no change), no external requests.
4. `snakemake --lint`, and act on what it reports for an overlay of existing scripts:
   - *No log directive defined*: **fix it.** Give each rule `log: "logs/<rule>/{wildcards}.log"`
     and send the script's output there (`… > {log} 2>&1`), so concurrent download jobs do not
     mix on the terminal and failures, retries and back-offs can be found afterwards. Add `logs/`
     to `.gitignore`.
   - *Specify a conda environment or container for each rule*: consider it, but do not adopt it
     blindly. It documents the software a step needs, which suits a published workflow; for a
     course or one-off repository where the scripts run in one documented environment
     (`python -I`, a pinned requirements file), record that environment in `workflow/README.md`
     and say that you accepted this lint knowingly.
   Re-run `--lint` after changes; any remaining items should be deliberate and written down.
5. `snakemake --list-rules`, `snakemake --dag | dot -Tsvg > dag.svg` for documentation.

6. **Live end-to-end test from a sandbox** (an integration test): the steps above never prove that
   a *fresh* checkout can fetch everything and build the product. **Ask the user first.** It may
   take hours and sends real requests to the source servers; say roughly how many files and how
   much data, which servers, and the pacing and concurrency you will use, and offer a smaller
   scope (one or two small files, a short date range) or skipping it. Do not start it without a
   yes, and do not repeat it more than needed.
   - Work in a **clean clone** (`git clone` of the repository into a scratch directory, with no
     `raw/` or other untracked files), never in the working tree, so no real data, manifest or
     crate is overwritten. Commit what you want tested first: an unpushed clone from the local
     path is fine.
   - Run the normal command with `--forceall`, so every step runs, whatever exists
     (`snakemake --profile … --forceall`). In the clean clone this deletes nothing of value;
     in the working tree it would, which is another reason for the clone. Use the real
     retry/backoff and pacing settings; never loosen them to make the test faster.
   - Check: the run completes; manifests, hashes and schema captures match the committed ones (a
     `git diff` against the original shows only expected upstream changes); validation passes;
     RO-Crate metadata validates; a second run (without `--forceall`) reports **nothing to be done** and makes no
     external requests.
   - Report what happened (duration, retries, failures, differences) and what was not tested.
     Delete the sandbox afterwards, or ask whether to keep it.

Snakemake reports "jobs have missing provenance/metadata" for files created before the workflow
existed; this is informational.

## 6. Document it

A short `workflow/README.md`: the commands above, a table of rules (what each runs and declares),
why downloads are not repeated, which files are side effects, how to check upstream changes, and
the limitations. Add `.snakemake/` to `.gitignore`. Work on a branch until the tests pass.

## Checklist

- [ ] Scripts still runnable alone; Snakefile only declares inputs/outputs
- [ ] Profile: one core, mtime-only rerun triggers
- [ ] One job per external file; `wildcard_constraints`; scripts called with `--only … --no-check`
- [ ] All downloads in the default target; parallel downloads limited by a `downloads` resource
- [ ] Manifests and crate metadata not declared as outputs; previews depend on their writers
- [ ] Best practices considered (layout, `snakefmt`, `common.smk`, config); deviations written down
- [ ] `snakemake --lint`: log directives added; conda/container lint fixed or consciously accepted
- [ ] Tests: dry run clean; one missing file fetched alone; forced step byte-identical
- [ ] Live sandbox run offered to the user (asked first, not assumed); result reported
- [ ] `workflow/README.md`; `.snakemake/` ignored
- [ ] Plan for metadata as a pure-function rule and Workflow Run Crate
