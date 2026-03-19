# Salesforce Skills for AI Coding Agents

Open-source Agent Skills for Salesforce development. Works with Claude Code, Cursor, Codex, and 50+ AI tools.

## Architecture
- **Canonical skills**: `skills/` — 10 skills following the [Agent Skills spec](https://agentskills.io)
- **Cross-client**: `.agents/skills/` — symlinks for non-Claude agents
- **Claude Code**: `.claude/skills/` — symlinks + `.claude/agents/` for subagents
- **Shared references**: `references/` — governor limits (used by multiple skills)
- **Scripts**: `scripts/` — security scan, metadata validation (support `--help` and `--format json`)
- **MCP config**: `.claude/.mcp.json` — Salesforce DX MCP server (disabled by default)

## Salesforce Conventions
- **API Version**: 62.0
- **Naming**: PascalCase for classes, camelCase for methods/variables, UPPER_SNAKE for constants
- **Trigger Pattern**: One trigger per object, handler class pattern
- **Test Coverage**: Minimum 75%, target 85%+
- **Security**: `WITH USER_MODE` in SOQL, `Security.stripInaccessible()` for DML, `with sharing` on classes
- **Bulk Patterns**: All code must handle 200+ records per transaction

## Key Limits
- 100 SOQL queries / 150 DML statements per synchronous transaction
- 6 MB heap / 10s CPU time
- 50,000 query rows / 10,000 DML rows

## CLI Quick Reference
- Deploy: `sf project deploy start -d force-app/`
- Retrieve: `sf project retrieve start -m ApexClass:MyClass`
- Test: `sf apex run test -n MyTestClass --synchronous`
- Query: `sf data query -q "SELECT Id, Name FROM Account LIMIT 10"`

## Development Workflow
1. Retrieve metadata from org
2. Develop locally with skill assistance
3. Deploy to scratch org / sandbox for testing
4. Run tests and security audit (`/sf-security`)
5. Deploy to target org (`/sf-deploy`)
