---
name: data-license-investigation
description: Find out under what terms a dataset may be used and redistributed, record the evidence, and encode the result (or the uncertainty) in metadata. Use before redistributing or publishing downloaded data, when a data portal shows no licence, or when the data owner, operator and publisher are different organisations.
license: MIT
metadata:
  author: "Stian Soiland-Reyes (https://orcid.org/0000-0001-9842-9718), The University of Manchester"
  version: "0.2.1"
---

# Investigating data licences

A licence question is rarely answered by one page. The site you download from is often not the
data owner, its "terms" page may cover a different service, and an aggregator may state a
licence that does not clearly cover the data you have. This skill gathers evidence, separates
what is **stated** from what is **assumed**, gets a decision from the responsible person, and
makes the terms travel with the data. It is not legal advice.

Worked example: hourly air-quality data for a Manchester monitoring site, downloaded from Air
Quality England (operated by a consultancy for the city council, also shown on Defra's UK-AIR),
where no licence was stated for the downloads.

## 1. Identify the roles

For the specific data you hold, write down:

| Role | Question | Example |
|---|---|---|
| **Owner** | Who collects the data / holds the rights? | Manchester City Council |
| **Operator** | Who runs the service or instrument? | Ricardo (Air Quality England) |
| **Publisher / host** | Where did you download it? | airqualityengland.co.uk |
| **Aggregators** | Who else republishes it, under what terms? | Defra UK-AIR, Clean Air Greater Manchester |
| **Derived products** | What will you redistribute? | a teaching database containing the values |

The licence that matters is the **owner's**, for **this data via this channel**, covering
**the use you plan** (internal use, redistribution within an organisation, publication).

## 2. Look in these places, in this order

1. The download page and its footer; the dataset's metadata or documentation.
2. The host's terms, licence, copyright, "about" pages. **Read what they cover**: terms are often
   about an alert or website service, not the data.
3. The **owner's open-data policy** (e.g. "unless otherwise stated, data on our website is
   published under the Open Government Licence"); note whether it covers data on *other* sites.
4. Aggregators' licence statements (e.g. a national portal under OGL) and whether they extend to
   third-party or locally managed data.
5. National data catalogues (data.gov.uk etc.) for the same dataset.
6. Documentation of software packages that fetch the data (they sometimes state terms).

Tactics:

- Fetch pages and grep for `licen[cs]e`, `copyright`, `open government`, `re-use`, `terms`,
  `attribution`. Many sites block automated fetches (403, timeouts) or are down: try a web search
  for quoted text, and record that the primary page could not be read.
- Quote **verbatim**, with URL and date checked, in the data-sources document.
- Distinguish site copyright ("© Clean Air Greater Manchester") from a data licence.

## 3. Classify the outcome

- **Confirmed**: a licence explicitly covering this data and channel (e.g. "OGL v3.0" on the
  download page). Record the licence URL and the required attribution statement.
- **Probable**: indirect evidence (owner's general policy, aggregator's licence) but nothing
  explicit for this data.
- **Unknown**: nothing found, or contradictory statements.

Do not upgrade "probable" to "confirmed" in metadata or documentation.

## 4. Decide, with the responsible person

For probable or unknown terms, present options and let the data owner's contact or the project
lead decide:

- **ask the owner** (draft below), and record that the enquiry was sent and when;
- **restrict use** while waiting: e.g. non-commercial internal teaching with attribution,
  redistribution only within the institution, not published openly;
- **let users obtain the data themselves** from the source, and distribute only scripts and
  metadata (checksums let them verify they obtained the same files);
- use an alternative source with a clear licence (e.g. a national network site under OGL).

Record the decision, who made it and the date, and what would change it.

Enquiry draft:

```text
Subject: Licence for reuse of <dataset> data from <site/portal>

We have downloaded hourly <variables> for <site> (<date ranges>) from <URL> for
<purpose, e.g. non-commercial university teaching>. We could not find a licence for reusing
these data. Could you confirm under which terms they may be used and redistributed (for
example the Open Government Licence v3.0), and the attribution you require?
```

## 5. Encode the terms in the metadata and documentation

- **Confirmed**: `license` → the licence URL (prefer SPDX ids or the official URL, e.g. OGL v3.0)
  with a licence entity; `creditText` → the required attribution statement.
- **Probable/unknown**: do not assert a licence. Point the data's `license` (and `usageInfo`) to
  a **local placeholder** entity (e.g. `#licence-placeholder-<source>`) whose description lists
  the checks (with dates and URLs), the assumptions, the decision and its conditions, and the
  contact to confirm with. Reuse one placeholder per source across all derived products, so a
  single update fixes everything.
- In RO-Crate, a file's own `license` overrides the root's: give the crate itself an explicit
  licence for your own work (e.g. CC BY-NC 4.0) without implying it covers third-party data.
- Make the terms **travel with the data**: include the metadata (RO-Crate) and a README section
  on usage terms in every redistributed package.
- Keep restricted raw files out of public repositories; commit only metadata and checksums.

## 6. Follow up

- Keep a visible note "licence enquiry sent <date>; awaiting reply" in the plan and data-sources
  documentation, with what to update when the reply arrives (placeholder → licence, regenerate
  metadata, revise documentation, possibly commit or publish files).
- Revisit when a source changes provider, portal or terms.

## Checklist

- [ ] Owner, operator, publisher, aggregators and derived products identified
- [ ] Pages checked in order; verbatim quotes with URLs and dates; unreadable pages noted
- [ ] Outcome classified: confirmed / probable / unknown
- [ ] Decision recorded (who, when, conditions); enquiry sent if needed
- [ ] Metadata: licence URL + attribution, or placeholder with evidence and assumptions
- [ ] Terms travel with every redistributed package; restricted raw data not published
- [ ] Follow-up note with what to update on reply
