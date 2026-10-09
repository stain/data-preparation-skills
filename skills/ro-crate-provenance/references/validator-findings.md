# roc-validator findings for RO-Crate 1.3 crates

Observed with [rocrate-validator](https://github.com/crs4/rocrate-validator) (`roc-validator`)
0.12.2 on RO-Crate 1.3 crates using Process Run Crate 0.6. Re-check with newer validator
versions; record your own findings with version and date.

## Version mismatches (not errors in the crate)

- **No `process-run-crate-0.6` profile**: the closest is `process-run-crate-0.5`, whose
  `profile.ttl` declares `prof:isProfileOf <https://w3id.org/ro/crate/1.1>`. It reports
  "The RO-Crate metadata file descriptor MUST have a `conformsTo` property with the RO-Crate
  specification version" for a crate that correctly declares RO-Crate 1.3. Validate the base
  spec with `-p ro-crate-1.3` and treat the 0.5 profile as indicative.

## False positives (crate follows the spec; the shape does not)

| Message | Why it is a false positive |
|---|---|
| "If the Action has an actionStatus, it should be http://schema.org/CompletedActionStatus …" | The shape (`process-run-crate/should/1_create_action.ttl`) uses `sh:in` with **string literals**; the spec's examples use an `{"@id": …}` reference. |
| "object and result SHOULD point to entities of type MediaObject, Dataset, …" | No RDFS subclass inference: `DataDownload` is a schema.org subtype of `MediaObject`, `WebPage` of `CreativeWork`. |
| "Encoding format entities SHOULD include WebPage and/or Standard types" | Reported even for PRONOM entities typed `["WebPage", "Standard"]`, exactly as in the RO-Crate 1.3 example. |
| "Missing or invalid `encodingFormat` linked to the `File Data Entity`" (process-run-crate-0.5) | Each file has a media type and a PRONOM reference; probably the same issue. |
| "RO-Crate Metadata Entity SHOULD include at least one Schema.org type" on a `Geometry` | `Geometry` (GeoSPARQL) is defined in the RO-Crate 1.3 context and another check recommends it for `Place.geo`. |
| OPTIONAL "MAY have `url` / `subjectOf` / `mainEntityOfPage` …" | Reported even for files that have these properties; OPTIONAL output is not a quality signal. |

## Real findings worth fixing

- `SoftwareApplication` without `version` (REQUIRED in the RO-Crate 1.3 profile; `softwareVersion`
  alone is not enough).
- Root data entity without `license` (REQUIRED). Use the crate's own licence (e.g. SPDX
  `http://spdx.org/licenses/CC-BY-NC-4.0`) with a `CreativeWork` entity; data files with
  different or uncertain terms carry their own `license`.
- Actions not referenced from the root (`mentions`).
- Profile entity not typed `["CreativeWork", "Profile"]`.
- Organisations without ROR identifiers where one exists.

## Accepted warnings (deliberate)

- No `contactPoint` on organisations or authors (avoids publishing email addresses).
- Licence placeholder entity without an absolute URL (there is no licence to link to yet).
- Organisations with no ROR identifier (e.g. a web service rather than an organisation).
