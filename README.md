# Data preparation skills

[Agent Skills](https://agentskills.io/) for preparing external data for analysis in a way others
can trust, reproduce and reuse: scripted downloads with provenance, explicit validation,
deliberate transformations, [RO-Crate](https://www.researchobject.org/ro-crate/) metadata, and
clear licence terms. The skills work with Claude Code, OpenAI Codex and other agents that read
`SKILL.md` files, and are equally readable as checklists for people.

| Skill | Use it when you … |
|---|---|
| [`reproducible-data-preparation`](skills/reproducible-data-preparation/SKILL.md) | download data from public sources (statistics portals, monitoring networks, web forms), integrate sources with different grains, time bases or locations, and hand a database or files to analysts or students |
| [`ro-crate-provenance`](skills/ro-crate-provenance/SKILL.md) | need to describe data files and how they were produced, with checksums, licences and attribution, as an RO-Crate 1.3, and validate it |
| [`data-license-investigation`](skills/data-license-investigation/SKILL.md) | must find out whether and how you may use or redistribute a dataset, especially when no licence is shown or owner, operator and publisher differ |

They were distilled from preparing a teaching dataset (UK road traffic counts joined to hourly
air-quality measurements) and record what had to be checked, corrected and decided along the way.

## How the skills fit together

```text
reproducible-data-preparation
  ├─ download step ──► ro-crate-provenance        describe each download directory, with actions
  │                └─► data-license-investigation  what goes in `license` and `creditText`
  ├─ transform step ─► ro-crate-provenance        derived files `isBasedOn` their inputs
  └─ product step ──► both: the package carries its metadata and its usage terms
```

## RO-Crate in brief

[RO-Crate](https://www.researchobject.org/ro-crate/) is a community specification for packaging
research data with its metadata: a directory with an `ro-crate-metadata.json` file (JSON-LD using
schema.org) that describes each file, who made it, under what licence, and how it was produced,
optionally with a human-readable `ro-crate-preview.html`. Profiles add conventions for particular
uses, such as [Process Run Crate](https://w3id.org/ro/wfrun/process/0.6) for recording the tools
that created the files. The `ro-crate-provenance` skill targets
[RO-Crate 1.3](https://w3id.org/ro/crate/1.3) and validates with
[rocrate-validator](https://github.com/crs4/rocrate-validator).

## Repository layout

```text
skills/<skill-name>/
  SKILL.md               instructions and metadata (Agent Skills format)
  agents/openai.yaml     Codex app metadata (display name, default prompt)
  references/            details loaded on demand (e.g. validator findings)
.claude-plugin/
  plugin.json            Claude Code plugin manifest
  marketplace.json       lets Claude Code add this repository as a plugin marketplace
.codex-plugin/
  plugin.json            OpenAI Codex plugin manifest ("skills": "./skills/")
.agents/plugins/
  marketplace.json       Codex marketplace entry for this repository
examples/                real outputs: RO-Crates, manifests, validation reports, licence record
codemeta.json            software metadata (CodeMeta 3.1)
LICENSE                  MIT
```

See [`examples/README.md`](examples/README.md) for what each example output shows and which skill
produced it.

## Installing

Replace `OWNER/data-preparation-skills` with the repository location.

**Claude Code**, as a plugin:

```text
/plugin marketplace add OWNER/data-preparation-skills
/plugin install data-preparation-skills@data-preparation-skills
```

or copy (or symlink) individual skill folders into `.claude/skills/` in a project, or
`~/.claude/skills/` for all projects.

**OpenAI Codex**: copy (or symlink) skill folders into `.agents/skills/` in a repository, or
`~/.agents/skills/` for all repositories; Codex detects them automatically (restart if one does not
appear). The repository is also laid out as a Codex plugin (`.codex-plugin/plugin.json`), and you
can ask Codex's `$skill-installer` to install skills from this repository.

**Other agents**: any tool that supports the [Agent Skills](https://agentskills.io/) format can
load the folders under `skills/`. Without an agent, read each `SKILL.md` as a checklist.

## Example prompts

Skills are usually picked up automatically from their descriptions; you can also name them
(`/skill-name` in Claude Code, `$skill-name` in Codex).

Data preparation:

> Use the reproducible-data-preparation skill. I need hourly traffic counts for count points
> near `<location>` from `<portal>`. Write a download script that records URL, retrieval time and
> SHA-256 in a manifest, does not re-download files that exist, and fails if the column schema
> changes. Then read the data with explicit types and write a validation report.

> Before we join these two sources, check their time bases. One says "hour ending", the other
> gives hours 7–18 with no time zone. Test it across a daylight-saving change and write down the
> alignment rule.

> Measure our scope options: how many sites, days and rows do we get within 250 m, 500 m and 1 km
> of the monitoring station, counting only days when the station was operating?

> Add a Snakemake workflow as an overlay of the existing scripts, without re-downloading files
> that already exist.

RO-Crate:

> Use the ro-crate-provenance skill to generate an RO-Crate 1.3 for `data/raw/<source>/`: every
> file with media type, PRONOM format, size, SHA-256, source URL, retrieval date, licence and
> attribution, plus a CreateAction per download and extraction (Process Run Crate). Then
> validate it with rocrate-validator and explain any warnings before fixing them.

> The validator says our actionStatus is wrong. Read the validator's SHACL shape and the
> RO-Crate 1.3 spec, and tell me whether it is a real problem.

> Generate an HTML preview for the crate with a pinned version of ro-crate-html-lite.

Licences:

> Use the data-license-investigation skill for the air-quality data we downloaded from
> `<portal>`. Who owns it, who publishes it, and what licence applies? Quote your evidence with
> URLs and dates, and say what is confirmed and what is assumed.

> We have no confirmed licence. Record a licence placeholder in the RO-Crate with what we
> checked, and draft an email to the data owner asking for the terms.

Combined:

> Prepare `<dataset>` for my students: download with provenance, validate, build a DuckDB
> database with table and column comments, describe everything as RO-Crates, and make sure the
> usage terms travel with the data.

## Validating the skills

The [`skills-ref`](https://github.com/agentskills/agentskills/tree/main/skills-ref) tool checks
`SKILL.md` front matter and naming:

```bash
skills-ref validate skills/ro-crate-provenance
```

## Contributing

Improvements are welcome, especially corrections from real use (a validator version that fixes a
false positive, a licence situation not covered). Keep each `SKILL.md` under 500 lines and move
detail to `references/`; keep the `name` equal to the folder name; update the version in both
plugin manifests and the skills' `metadata.version`.

## Licence

MIT, see [LICENSE](LICENSE). © 2026 Stian Soiland-Reyes
([0000-0001-9842-9718](https://orcid.org/0000-0001-9842-9718)), The University of Manchester.
The example outputs in [`examples/`](examples/) keep their own licence statements.
