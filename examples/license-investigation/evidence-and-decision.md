# Licence investigation: hourly air quality, Manchester Oxford Road (MAN1)

Example output of the `data-license-investigation` skill, from October 2026. It records the
evidence gathered, the classification, the decision, and how the terms were encoded in the
RO-Crate ([`license-placeholder-excerpt.json`](license-placeholder-excerpt.json)).

## Roles

| Role | Organisation |
|---|---|
| Owner | Manchester City Council (`https://ror.org/0558q2529`) |
| Operator / publisher | Air Quality England, run by Ricardo (`https://ror.org/05q07rr84`) |
| Aggregators | Defra UK-AIR ("locally managed" data); Clean Air Greater Manchester |
| Derived product | a teaching database containing hourly NO, NO2, NOx values |

## Evidence (checked 2026-10-09)

1. **Air Quality England** download page: no licence. Its only terms page
   (`/term-condition`) covers the air-pollution *alert service* (subscriptions, personal data,
   forecast liability), not the data.
2. **Clean Air Greater Manchester** data hub, disclaimer and terms: site copyright
   ("Copyright Clean Air Greater Manchester ©") and an accuracy disclaimer; nothing on reuse of
   monitoring data.
3. **Manchester City Council** open-data terms: "unless otherwise stated, the data you access on
   the Manchester City Council website is published under the Open Government Licence", with
   attribution, and the council retaining IPR. Covers data on the council's own website, not data
   downloaded from Air Quality England. *The council's sites blocked automated access (403,
   timeouts); quoted from search results.*
4. **Defra UK-AIR**: publishes its information under the Open Government Licence v3.0 and shows
   locally managed sites such as MAN1, but does not explicitly extend OGL to local-authority
   data. *UK-AIR was down for maintenance during the check.*

## Classification

**Probable, not confirmed**: OGL v3.0 is probably intended, but no statement covers data
downloaded from Air Quality England.

## Decision

By course staff, 2026-10-09:

- the data, and data derived from them, may be redistributed **within the university** for
  non-commercial teaching, with attribution, provided the terms and RO-Crate metadata accompany
  them;
- not published outside the institution until the licence is confirmed;
- raw downloads kept out of Git; metadata and checksums committed;
- licence enquiry emailed to the data owner on 2026-10-09; awaiting reply.

## Encoding

- Each downloaded file: `license` and `usageInfo` → `#licence-placeholder-air-quality-england`, a
  `CreativeWork` whose `description` records the checks, assumptions and decision, with the pages
  checked as `isBasedOn`.
- The crate root: `license` → `http://spdx.org/licenses/CC-BY-NC-4.0` (the crate's own terms),
  which the files' own `license` overrides; `usageInfo` → the placeholder.
- `creditText` on every file names the owner, the publisher and the operator.

## On reply

Replace the placeholder with the confirmed licence (URL and attribution statement), regenerate
the metadata, and revise this record.
