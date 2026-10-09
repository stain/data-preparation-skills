---
name: ro-crate-provenance
description: Describe downloaded and derived data files with RO-Crate metadata (ro-crate-metadata.json and HTML preview), including licences, attribution, checksums and the actions that produced them (Process Run Crate), and validate the result. Use when packaging datasets, recording provenance of a data pipeline, or when asked for RO-Crate, Process/Workflow Run Crate, or FAIR metadata for files. Targets RO-Crate 1.3.
license: MIT
metadata:
  author: "Stian Soiland-Reyes (https://orcid.org/0000-0001-9842-9718), The University of Manchester"
  version: "0.1.0"
---

# RO-Crate provenance for data files

How to write, generate and validate [RO-Crate](https://www.researchobject.org/ro-crate/)
metadata for a directory of data files. **Target: RO-Crate 1.3**
(`https://w3id.org/ro/crate/1.3`, context `https://w3id.org/ro/crate/1.3/context`), with the
[Process Run Crate 0.6](https://w3id.org/ro/wfrun/process/0.6) profile, which extends RO-Crate
1.3, for provenance. If a newer RO-Crate version exists, read its changelog before switching.
Pairs with `reproducible-data-preparation` (generate the crate from the download/transform
scripts) and `data-license-investigation` (what to put in `license`).

## 1. Read the specification you claim to follow

Do not rely on memory: versions change details (e.g. which properties are required, profile
entity types, context term mappings).

1. **Confirm the version exists and its URIs resolve**:
   - spec permalink, e.g. `https://w3id.org/ro/crate/1.3` (used in `conformsTo`; the HTML spec is
     at `https://www.researchobject.org/ro-crate/specification/1.3/`);
   - JSON-LD context, e.g. `https://w3id.org/ro/crate/1.3/context`;
   - profile permalinks, e.g. `https://w3id.org/ro/wfrun/process/0.6`.
2. **Read the relevant pages as text** (`curl` + strip tags): root data entity, data entities,
   contextual entities (licensing section), provenance, profiles; and the profile's own page
   (requirements table, examples).
3. **Check the context defines every term you use** (load the context JSON and look up
   `sha256`, `creditText`, `usageInfo`, `Geometry`, `asWKT`, `ActionStatusType`, …). Unknown
   terms silently become meaningless.
4. Where the spec and a profile's example disagree, follow the spec and record why (e.g. RO-Crate
   1.3 requires `Profile` in a profile entity's `@type`; the Process Run Crate example omits it).

## 2. Minimum structure

```text
ro-crate-metadata.json ──about──▶ ./ (Dataset)
./  conformsTo profile(s); name, description, datePublished, license, author, publisher,
    creditText; hasPart → every file/directory; mentions → every action
File  name, description, encodingFormat [media type, {PRONOM}], contentSize, sha256,
      url (where downloaded), sdDatePublished (retrieval), dateModified (upstream),
      license, publisher, creditText, mainEntityOfPage / subjectOf (documentation)
extracted/ (Dataset) hasPart → files that are isBasedOn their archive
contextual entities: licences (CreativeWork), organisations (ROR @id), people (ORCID @id),
      PRONOM formats (["WebPage","Standard"]), places (Place + Geometry asWKT), profile
```

Practical choices that worked:

- **Identifiers**: organisations by ROR (`https://api.ror.org/v2/organizations?query=…`), people
  by ORCID, licences by their URL (prefer SPDX, e.g. `http://spdx.org/licenses/CC-BY-NC-4.0`)
  with a `CreativeWork` entity (`name`, `identifier`, `url`, `description`).
- **Formats**: media type plus PRONOM id; check the actual file (`head -c 8 file.pdf` →
  `%PDF-1.6` → `fmt/20`, not a guessed version).
- **Distinguish data publisher from crate publisher**: the data's publisher goes on each file;
  the crate's author/publisher on the root.
- **Places**: `spatialCoverage` → `Place` with `geo` → `Geometry` `asWKT "POINT (lon lat)"`.
- **Variables**: `variableMeasured` → `PropertyValue` with `propertyID`, `unitText`.
- **The preview is not a data entity** (it renders the metadata).

## 3. Provenance with actions (Process Run Crate)

- One `CreateAction` per step (download, extract, transform), listed in the root's `mentions`:
  `name`, `description`, `object` (inputs; for web forms the page plus `PropertyValue`s for the
  parameters), `result` (outputs), `startTime`, `endTime`, `actionStatus`, `agent`.
- `instrument` is **required** by the profile: the software that ran (`SoftwareApplication` with
  `version` — the RO-Crate 1.3 validator requires `version`, not only `softwareVersion`). If the
  pipeline's own scripts are not to be described yet, use the libraries that did the work (HTTP
  library, zip module) with **version-specific `@id`s** so later runs can coexist.
- **Deterministic action ids**: `urn:uuid:` + UUIDv5 of `"<result>|<endTime>"`, so re-runs are
  byte-identical but a genuinely new execution gets a new id.
- **Keep history**: when regenerating, keep previously recorded actions (with their original
  instrument and agent); only fill in what is missing.
- `actionStatus` → `http://schema.org/CompletedActionStatus`, with an `ActionStatusType` entity.
- Agent: the person running the pipeline (ORCID), with a command-line override.
- Later, for a workflow manager: Workflow Run Crate (`https://w3id.org/ro/wfrun/workflow`) with
  the workflow as `instrument`; generate the crate as a pure function of data and manifests.

## 4. Generating the crate

- Generate it from the pipeline scripts, never by hand; share helpers (author, publisher,
  profile, formats, actions collector, writing metadata and preview) in one module.
- **Determinism**: derive `datePublished` from the latest action, reuse hashes of unchanged
  large files (same size and timestamp as recorded), stable ordering; check a re-run is
  byte-identical.
- Track `ro-crate-metadata.json` and the preview in Git even when the data are ignored
  (`.gitignore` negation: `raw/*`, `!raw/src/`, `raw/src/*`, `!raw/src/ro-crate-*`).
- **Uncertain licences**: point the file's `license` (and `usageInfo`) at a local placeholder
  `CreativeWork` (`#licence-placeholder-<source>`) whose `description` records what was checked
  and assumed; one per source, reused by every crate containing that source's data. A file's own
  `license` overrides the root's, so set the root licence (required) to the crate's own terms.

## 5. HTML preview

- `ro-crate-html-lite` (`npm install ro-crate-html-lite`, pin the version in `package.json`, use
  `npm ci`): `npx --no-install roc-html -l <layout> <crate dir>`.
- Without `-l` it fetches its layout from a moving `main` branch: **pin the layout URL to a
  commit** for reproducible previews.

## 6. Validate

```bash
python -m venv /tmp/rocval && /tmp/rocval/bin/pip install roc-validator
rocrate-validator profiles list                     # which profiles/versions exist
rocrate-validator validate -p ro-crate-1.3 --requirement-severity REQUIRED    <crate dir>
rocrate-validator validate -p ro-crate-1.3 --requirement-severity RECOMMENDED <crate dir>
rocrate-validator validate -p process-run-crate-0.5 --requirement-severity RECOMMENDED <crate dir>
```

- Use `--output-format json`; the output may be followed by a log block, so parse the first JSON
  value (`json.JSONDecoder().raw_decode`).
- Run as `< /dev/null` to avoid interactive prompts.
- `--metadata-only` (`-m`) validates the metadata without requiring the data files, for crates
  whose payload is not present (e.g. git-ignored data, metadata-only examples).
- Target: **no REQUIRED failures** for the base spec. Treat RECOMMENDED as a review list and
  OPTIONAL output as noise.
- **Check the validator's profile against your target version**: `profiles list`, and the
  profile's `profile.ttl` (`prof:isProfileOf`). E.g. a Process Run Crate 0.5 validator profile
  built on RO-Crate 1.1 fails a 1.3 crate's `conformsTo` — a version mismatch, not an error.
- **Before "fixing" a warning, read the SHACL shape** in the installed package
  (`site-packages/rocrate_validator/profiles/…/*.ttl`) and compare with the spec. See
  [references/validator-findings.md](references/validator-findings.md) for false positives and
  version mismatches seen with roc-validator 0.12.2.
- Fix real findings (e.g. missing `version`, missing root `license`, unlinked actions →
  `mentions`, profile entity type, ROR ids).
- Record results, accepted warnings and false positives with reasons in the repository
  (e.g. a `RO-CRATE.md`), with validator version and date.

## 7. Document decisions

Keep a short document explaining: which specs and profiles, the entity model (ASCII diagram),
each choice among optional features and why, validation commands and results, false positives,
and open decisions (contact points, persistent identifiers, licence confirmations).

## Checklist

- [ ] Spec/profile versions confirmed; context terms checked
- [ ] Every file in `hasPart` with type, size, sha256, licence, attribution, source URL, dates
- [ ] Extracted/derived files linked with `isBasedOn` and a `CreateAction`
- [ ] Actions with instrument (versioned), agent, times, deterministic ids, in `mentions`
- [ ] Licence entities with SPDX/URL ids; placeholders for uncertain terms
- [ ] Author/publisher (ORCID/ROR); profile entity `["CreativeWork","Profile"]`
- [ ] Preview generated with pinned tool and layout
- [ ] Re-run byte-identical; validated with no REQUIRED failures; findings documented
