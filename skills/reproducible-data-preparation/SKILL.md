---
name: reproducible-data-preparation
description: Download external datasets and transform them into an analysis-ready data product with a reproducible, validated, provenance-recording pipeline. Use when gathering data from public sources (government statistics, monitoring networks, web download forms), integrating sources with different grains, time bases or locations, or preparing a database/files for analysts or students.
license: MIT
metadata:
  author: "Stian Soiland-Reyes (https://orcid.org/0000-0001-9842-9718), The University of Manchester"
  version: "0.2.0"
---

# Reproducible data preparation

A method for turning external downloads into a trustworthy data product: scripted downloads
with provenance, explicit typing and validation, deliberate transformations with stated grain,
and a product whose meaning travels with it. Combine with the `ro-crate-provenance` skill (for
describing downloads and products) and the `data-license-investigation` skill (before
redistributing anything).

Worked example behind this skill: UK Department for Transport road traffic counts and hourly
air-quality measurements from a nearby monitoring site, prepared as a DuckDB teaching database.

## 0. Before downloading anything

1. **Purpose first.** Write down the questions the data must answer and, for the target,
   "**One row represents …**". The question decides sources, grain, scope and what may be lost.
2. **Read the source documentation** (metadata PDFs, "notes and definitions", quality reports).
   Extract: variable definitions, units, time basis, missing-value conventions, revision policy,
   licence. Note what the documentation does *not* say.
3. **Inventory candidate files** cheaply: `curl -sIL` for size, `Last-Modified`, `ETag`, server
   hashes (e.g. `x-goog-hash` on Google Cloud Storage), before downloading.
4. **Check you have the right file.** If someone expects "about 5 million rows", count them
   (`unzip -p x.zip | wc -l`) and look *inside* archives (`unzip -l`). Per-entity convenience
   downloads often have a **different schema** from the bulk file (fewer columns, other names,
   rounded coordinates): treat them as cross-checks, not substitutes.
5. **Measure scope options before choosing.** A small table of "scope → entities → rows" (e.g.
   1 site / 500 m / 1 km / region) turns a vague choice into a concrete one, and shows which
   source actually limits the useful data.

## 1. Downloads with provenance

Write one download script per source. For every file record, in a committed manifest CSV:

- source URL, retrieval time (UTC), upstream `Last-Modified`, `ETag`, size;
- MD5 and SHA-256 of the local file; **verify** against any hash the server publishes;
- for form-based sources: the request parameters, and the generated download URL (often
  temporary).

Rules:

- **Never edit raw files.** Keep them in `raw/` (git-ignored if large or not redistributable);
  commit the manifests and metadata instead.
- **Do not re-download what exists.** Skip when the local file matches the manifest/server hash;
  offer `--force`, `--only FILE` (one file) and `--no-check` (no upstream request for files
  present) so a workflow manager can call the script per file without network traffic.
- **Record the schema** (column headers per file) in a committed file and **fail on change**
  unless explicitly accepted (`--accept-schema-change`); a Git diff then shows upstream changes.
- **Extract archives in the download step**, so one step owns everything under `raw/<source>/`
  and its provenance (extracted file `isBasedOn` the archive).
- **Multi-step web forms**: reproduce the form steps with a session (fetch the form, read hidden
  fields such as query ids, submit, find the generated file link), be polite (`sleep`), and
  name local files deterministically from the request (e.g. `site_<from>_<to>.csv`).
- **Untrusted content**: put downloads in their own directory, keep scripts elsewhere, run
  Python with `-I`, never execute anything from a download.
- Fail loudly on unexpected responses (missing form fields, no file link, hash mismatch).

## 2. Read with explicit types; never invent values

- Declare column types explicitly (DuckDB `read_csv(..., columns = {...})`), and read the
  source's **missing-value tokens** (`NA`, empty cells) as NULL. Never convert missing to 0.
- Keep source column names in staged data; use `lower_case_with_underscores` for derived ones.
- Split **packed values** only as far as needed (e.g. `"R ugm-3 (Ref.eq)"` → status, unit,
  method) and assert the parts you do not model are constant.
- Classify checks as **error** (stop) or **warning** (report): duplicate keys, sums that must
  reconcile (classes vs totals), non-negative counts, coordinate bounds, allowed codes. Write
  the results to a validation CSV; exit non-zero on any error.
- Expect real-data surprises and record them in a data-sources document: undocumented codes,
  lower-case variants, a negative count, labels that change over time for the same entity
  (road names `A57` → `A57M` → `A57(M)`), coordinates that move between years, an entity
  counted in one direction only.

## 3. Time: verify, do not assume

- Write each source's **time basis** explicitly: local clock time vs UTC/GMT; hour *beginning*
  vs hour *ending*; instantaneous vs period mean.
- **Test it empirically.** Download data spanning daylight-saving changes: GMT/UTC series have
  24 hourly rows on every day; local-time series have 23 in spring and 25 (or duplicates) in
  autumn. Record the result as a manifest (hours per day).
- When documentation is silent, infer carefully (e.g. "counts 7am–7pm between March and October
  for daylight reasons" ⇒ local clock time), label it an inference, and state the **alignment
  rule** with an example (`source A hour h (BST) = [h−1, h) GMT = source B row ending h:00`).
- Handle notations like `24:00:00` (end of day) explicitly.
- Keep source timestamps beside derived ones; name columns by basis (`_local`, `_gmt`).

## 4. Transform deliberately (just enough of the classic principles)

1. **State the grain** of every output.
2. **Change grain deliberately**, and name what is lost (combining directions, summing classes).
3. **Join only at a compatible grain**; check for fan-out (row counts before and after a join;
   key uniqueness). Pairing an observation with *every* nearby site multiplies rows: prefer
   a stated rule such as "the single nearest site operating on that date, within X m".
4. **Add representations; never modify sources**: derived columns come from new views;
   materialise (e.g. Parquet via `COPY … TO`) only at step boundaries, for expensive steps, or
   for the hand-over product.
5. **Windows are defined on time**, not on row order: sparse observations (e.g. 12-hour count
   days years apart) make `LAG()` over rows pair unrelated hours. Lags join on
   `timestamp + INTERVAL`, or partition by the observation day.
6. **Validate every step**; fail loudly on unknown codes.

Geography:

- Great-circle (haversine) distance on WGS84 lat/lon is enough at city scale and needs no
  spatial extension; state the formula and radius.
- Use the **coordinates as on the observation date** when locations move between years.
- Select candidate sites by **operating period on the date** (sites open and close).
- Carry distances into the data as covariates: they are part of the uncertainty.
- Make tie-breaking deterministic.

## 5. The product

Distinguish:

- the **warehouse**: prepared observations at source grain, aligned and validated (staff work);
- **analytical products**: question-specific, often lossy views built on it (analyst work).

Decide what the analyst should do themselves (e.g. define metrics) and stop the preparation
there; provide prepared, aligned inputs (e.g. a table of pollution values already aligned to each
traffic hour) rather than doing the analysis for them.

For a database hand-out (DuckDB worked well):

- one database file with **tables** (not views over file paths) so it is self-contained;
- `COMMENT ON TABLE/COLUMN` carrying grain and definitions, plus a `data_dictionary.csv`;
- the single SQL script that builds it, and CSV/Parquet **exports** for other tools;
- write with `STORAGE_VERSION 'v1.0.0'` (or similar) so older clients can open it;
- a README with what one row represents, usage terms, and how to open it from each language;
- check the users' environments: disk quotas, existing installations (e.g. a 2 GB home
  directory cannot hold a 2 GB conda environment; `pip install duckdb` is ~20 MB);
- test every snippet you give to users against a real or mock database.

## 6. Determinism and workflow

- Re-running without upstream changes should leave every output **byte-identical**
  (deterministic ordering, ids derived from content and time, no "now" timestamps unless
  something changed). Check by re-running and diffing.
- Commit in small steps with messages that record decisions; keep a plan with an explicit
  **decision points** list; record decided items with dates.
- A workflow manager can be added as an **overlay** of the working scripts, rebuilding only
  what is missing without re-downloading or losing provenance: see the `snakemake-data-pipeline`
  skill.

## 7. Reporting

- Report findings, not just actions: unexpected data properties, failed checks, inferences.
- Say what was **not** verified (e.g. a page that was down, a behaviour inferred from docs).
- Correct yourself visibly when a claim turns out wrong (e.g. row counts, licence assumptions).

## Checklist

- [ ] Questions and target grain written down
- [ ] Source docs read; time basis, units, missing values, licence noted
- [ ] Right files confirmed (inside archives; expected row counts)
- [ ] Download scripts with manifest, hashes, schema capture, no re-download
- [ ] Explicit types; NULL not 0; validation CSV with errors/warnings
- [ ] Time basis tested empirically; alignment rule documented
- [ ] Grain stated for every output; fan-out checked; windows on time
- [ ] Product with comments, dictionary, build script, exports, README, usage terms
- [ ] Re-run is byte-identical; provenance metadata (RO-Crate) generated and validated
- [ ] Licence investigated before any redistribution
