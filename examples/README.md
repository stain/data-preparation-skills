# Example outputs

Real outputs from the project these skills were distilled from: preparing a teaching dataset of
UK Department for Transport road traffic counts near an air-quality monitoring site in
Manchester, joined to that site's hourly measurements. They show what applying the skills
produces. **Only metadata, manifests and reports are included; the data files themselves are
not** (they are large or under third-party terms), so the RO-Crates describe files that are not
present here.

| Folder / file | Produced by (skill, step) | Shows |
|---|---|---|
| [`traffic-counts-download/ro-crate-metadata.json`](traffic-counts-download/ro-crate-metadata.json) | `ro-crate-provenance` | RO-Crate 1.3 + Process Run Crate 0.6 for six downloads and three CSVs extracted from ZIPs: media types with PRONOM ids, sizes, SHA-256, source URLs, retrieval and upstream dates, OGL v3.0 licence and attribution, publisher by ROR, author by ORCID, one `CreateAction` per download/extraction with versioned instruments and deterministic ids |
| [`traffic-counts-download/ro-crate-preview.html`](traffic-counts-download/ro-crate-preview.html) | `ro-crate-provenance`, preview | The same crate as a human-readable page (ro-crate-html-lite, pinned layout) |
| [`traffic-counts-download/manifests/dft_downloads.csv`](traffic-counts-download/manifests/dft_downloads.csv) | `reproducible-data-preparation`, downloads | URL, retrieval time, `Last-Modified`, `ETag`, size, MD5 (checked against the server's hash) and SHA-256 per file |
| [`traffic-counts-download/manifests/dft_schemas.csv`](traffic-counts-download/manifests/dft_schemas.csv) | downloads | Recorded column headers; a change fails the next download |
| [`traffic-counts-download/manifests/dft_validation.csv`](traffic-counts-download/manifests/dft_validation.csv) | reading and validation | Error/warning checks with violation counts, including one real warning (a negative count in the source) |
| [`traffic-counts-download/manifests/dft_extracts.csv`](traffic-counts-download/manifests/dft_extracts.csv) | transformation | Each extract with its source row count, filter, row count and year range |
| [`traffic-counts-download/manifests/dft_6069_count_dates.csv`](traffic-counts-download/manifests/dft_6069_count_dates.csv) | inventory | One row per observed count day, with weekday, UK clock (BST/GMT), hours, directions, road name as on that day (it changes over the years) |
| [`air-quality-download/ro-crate-metadata.json`](air-quality-download/ro-crate-metadata.json) | `ro-crate-provenance` + `data-license-investigation` | A crate for downloads from a multi-step web form: request parameters as `PropertyValue` inputs, `Place` with WKT `Geometry`, `variableMeasured` with units, and the **licence placeholder** for uncertain terms |
| [`air-quality-download/manifests/man1_downloads.csv`](air-quality-download/manifests/man1_downloads.csv) | downloads | One row per form request: purpose, dates, parameters available and requested, generated URL, SHA-256, rows, valid values and status codes per pollutant |
| [`air-quality-download/manifests/man1_hours_per_day.csv`](air-quality-download/manifests/man1_hours_per_day.csv) | time basis, tested empirically | Hours per day across eight daylight-saving changes: 24 every day, so the timestamps are GMT, not local time |
| [`air-quality-download/manifests/man1_schemas.csv`](air-quality-download/manifests/man1_schemas.csv) | downloads | Column headers per downloaded file |
| [`license-investigation/evidence-and-decision.md`](license-investigation/evidence-and-decision.md) | `data-license-investigation` | Roles, evidence with dates, classification ("probable"), decision, encoding, follow-up |
| [`license-investigation/license-placeholder-excerpt.json`](license-investigation/license-placeholder-excerpt.json) | `data-license-investigation` + `ro-crate-provenance` | The placeholder `CreativeWork`, the pages checked, the crate licence, and one file using them |

Notes:

- The example crates keep their own licence statements: the traffic crate is OGL v3.0 (UK
  Government data); the air-quality crate is CC BY-NC 4.0 for the crate, with the files under the
  licence placeholder. The repository's MIT licence covers the skills, not these examples' data.
- Because the data files are not included, validate these crates with
  `rocrate-validator validate -p ro-crate-1.3 --metadata-only <folder>`: both pass with no
  REQUIRED issues (roc-validator 0.12.2). Without `--metadata-only` every data file is reported as
  missing from the payload.
- Validation results for the complete crates are summarised in
  [`../skills/ro-crate-provenance/references/validator-findings.md`](../skills/ro-crate-provenance/references/validator-findings.md).
