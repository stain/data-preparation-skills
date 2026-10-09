@AGENTS.md

## Claude Code notes

- Validate the Claude manifests with `claude plugin validate .` (marketplace) and
  `claude plugin validate .claude-plugin/plugin.json` (plugin); `tools/check.sh` runs both if the
  `claude` CLI is installed.
  Its warning that "CLAUDE.md at the plugin root is not loaded as project context" is expected:
  this file guides development of the repository, not users of the plugin.
- To try local changes as an installed plugin:
  `/plugin marketplace add ./` from the repository root, then
  `/plugin install data-preparation-skills@data-preparation-skills`, and start a new session.
  Remove it afterwards with `/plugin marketplace remove data-preparation-skills`.
- Plugin skills are invoked as `/data-preparation-skills:<skill-name>`; skills copied into
  `~/.claude/skills/` are invoked as `/<skill-name>`.
- Commit in small steps with descriptive messages; do not push without being asked.
