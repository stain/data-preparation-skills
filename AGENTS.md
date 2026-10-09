# Developing this repository

Guidance for people and coding agents (Claude Code reads it via `CLAUDE.md`; Codex and others
read `AGENTS.md`). Read this before changing anything.

## What this is

Four [Agent Skills](https://agentskills.io/specification) for data preparation, packaged for
Claude Code and OpenAI Codex:

| Skill | Scope |
|---|---|
| `skills/reproducible-data-preparation/` | downloads with provenance, typing and validation, time and geography alignment, just-enough transformation, the data product, workflow-manager overlay |
| `skills/ro-crate-provenance/` | RO-Crate **1.3** metadata (+ Process Run Crate 0.6), previews, validation with rocrate-validator |
| `skills/snakemake-data-pipeline/` | Snakemake as an overlay of existing scripts: per-file download jobs, no re-downloads, side-effect provenance files, testing; general authoring deferred to bioSkills `snakemake-workflows` |
| `skills/data-license-investigation/` | roles, evidence, classification, decision, encoding licence terms in metadata |

Distilled in October 2026 from preparing a teaching dataset (UK road traffic counts + hourly air
quality) in a private course repository; the `examples/` folder holds real outputs from it.

## Layout and what must stay in sync

```text
skills/<name>/SKILL.md              front matter: name, description, license, metadata.author/version
skills/<name>/agents/openai.yaml    Codex UI: display_name, short_description, default_prompt
skills/<name>/references/*.md       detail loaded on demand (one level deep from SKILL.md)
.claude-plugin/plugin.json          Claude Code plugin manifest
.claude-plugin/marketplace.json     Claude Code marketplace (this repo is its own marketplace)
.codex-plugin/plugin.json           Codex plugin manifest ("skills": "./skills/")
.agents/plugins/marketplace.json    Codex marketplace entry
codemeta.json                       CodeMeta 3.1 software metadata
examples/                           real outputs (metadata only), see examples/README.md
tools/check.sh                      all validations
CHANGELOG.md, README.md, LICENSE (MIT)
```

When you change:

- **a skill's name**: rename its folder too (`name` must equal the folder name); update README
  tables, `examples/README.md`, cross-references in the other skills, and `CHANGELOG.md`;
- **a skill's purpose**: update its `description` (≤ 1024 characters, says what it does *and when
  to use it*, with trigger keywords), its `agents/openai.yaml`, and the README table;
- **the version**: bump it in `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`
  (`metadata.version`), `.codex-plugin/plugin.json`, `codemeta.json`, and every
  `SKILL.md` `metadata.version`; add a `CHANGELOG.md` entry;
- **authorship or licence**: `LICENSE`, both plugin manifests, the marketplace `owner`,
  `codemeta.json`, each `SKILL.md` `metadata.author`, and the README licence line.

## Writing skills

- Follow the [Agent Skills specification](https://agentskills.io/specification): `name` lowercase
  letters, digits and single hyphens, ≤ 64 characters; `SKILL.md` under 500 lines (currently
  ~120–175); move detail to `references/`.
- Keep skills **generic**: no course names, no private links, no personal data. Use the worked
  example only as a neutral illustration.
- Keep them **evidence-based**: every rule should come from something that actually happened or
  was checked (a spec page, a validator run, a data surprise). Say which tool versions a finding
  applies to (e.g. roc-validator 0.12.2 in `references/validator-findings.md`).
- **RO-Crate version**: the RO-Crate skill targets RO-Crate 1.3 explicitly. Before moving to a
  newer version, read its changelog and spec pages, check the JSON-LD context for every term the
  skill mentions, and re-run the validator on the examples.
- Each skill ends with a checklist; keep it in step with the body.
- Spelling: British English in prose ("licence" as a noun); the skill name
  `data-license-investigation` uses "license" deliberately (common search term).
- Skills cross-reference each other by name (`ro-crate-provenance`, …), not by path.

## Examples

- `examples/` holds **metadata, manifests and reports only**, never the data files (large or
  third-party terms). The example RO-Crates keep their own licence statements (OGL v3.0;
  CC BY-NC 4.0 with a licence placeholder); MIT covers the skills, not the examples.
- Validate them with `rocrate-validator validate -p ro-crate-1.3 --metadata-only <folder>`.
- They are copies: regenerate them only from a real pipeline run, and update
  `examples/README.md` if files are added or renamed.

## Checks before committing

```bash
tools/check.sh          # skills-ref, JSON syntax, CodeMeta terms, claude plugin validate, RO-Crate examples
```

It needs `python3` with network access (it installs `skills-ref` and `roc-validator` into a
temporary virtual environment) and, optionally, the `claude` CLI. There is no validator for the
Codex manifests; they follow the layout of github.com/openai/plugins and only get a JSON syntax
check.

## Releasing

1. Bump the version everywhere listed above; add a dated `CHANGELOG.md` entry.
2. `tools/check.sh`.
3. Commit, tag `vX.Y.Z`, push with tags.
4. Users update with `/plugin marketplace update data-preparation-skills` (Claude Code).

## Ideas not yet done

- Split the marketplace into one plugin per skill, so each can be installed on its own (as
  `anthropics/skills` groups its skills).
- Run `tools/check.sh` in GitHub Actions.
- Test the Codex plugin and marketplace manifests in Codex.
- Candidate new skills from the same work: defining and evaluating analytical metrics
  (candidate metrics, validity, boundary conditions, assumption checks); packaging data and
  software environments for learners (disk quotas, several access routes, testing snippets
  headlessly); Workflow Run Crate generation for a Snakemake run (see `snakemake-data-pipeline` § 3).
