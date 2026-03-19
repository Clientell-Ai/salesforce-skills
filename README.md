# Salesforce Skills for AI Coding Agents

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Agent Skills](https://img.shields.io/badge/Agent_Skills-compatible-brightgreen)](https://agentskills.io)
[![Install](https://img.shields.io/badge/npx_skills_add-clientell%2Fsalesforce--skills-8A2BE2)](https://skills.sh)
[![Salesforce](https://img.shields.io/badge/Salesforce-API_v62.0-00A1E0?logo=salesforce)](https://developer.salesforce.com)

Production-ready [Agent Skills](https://agentskills.io) for Salesforce development. Generate Apex, Flows, LWC, SOQL, and more — with governor limit awareness, security compliance, and deployment orchestration built in.

Works with **Claude Code, Cursor, Codex, Gemini CLI, VS Code Copilot**, and [50+ AI tools](https://agentskills.io).

## Quick Start

```bash
npx skills add Clientell-Ai/salesforce-skills
```

That's it. All 10 skills are now available in your AI coding agent.

## Install Individual Skills

```bash
npx skills add Clientell-Ai/salesforce-skills@sf-apex       # Apex code generation & review
npx skills add Clientell-Ai/salesforce-skills@sf-test       # Test class generation
npx skills add Clientell-Ai/salesforce-skills@sf-flow       # Flow generation & PB migration
npx skills add Clientell-Ai/salesforce-skills@sf-lwc        # LWC scaffolding
npx skills add Clientell-Ai/salesforce-skills@sf-soql       # SOQL/SOSL query building
npx skills add Clientell-Ai/salesforce-skills@sf-security   # Security & AppExchange audit
npx skills add Clientell-Ai/salesforce-skills@sf-deploy     # Deployment orchestration & CI/CD
npx skills add Clientell-Ai/salesforce-skills@sf-data       # Data migration & bulk operations
npx skills add Clientell-Ai/salesforce-skills@sf-schema     # Schema & permission management
npx skills add Clientell-Ai/salesforce-skills@sf-find       # Skill discovery
```

### Install globally (all projects)

```bash
npx skills add Clientell-Ai/salesforce-skills -g
```

### Manual installation

```bash
git clone https://github.com/Clientell-Ai/salesforce-skills.git
cd salesforce-skills
./install.sh /path/to/your/salesforce-project
```

## What Problems Do These Skills Solve?

| Pain Point | Skill | What It Does |
|------------|-------|-------------|
| Writing test classes is tedious | **sf-test** | Generates comprehensive tests with @TestSetup, 200-record bulk, permission testing, callout mocks, async testing, Stub API |
| Deployment failures (37-60% fail rate) | **sf-deploy** | Resolves dependencies, diagnoses errors, generates CI/CD pipelines, manages scratch orgs and packages |
| AppExchange security review failures | **sf-security** | Audits CRUD/FLS, SOQL injection, sharing violations, PII exposure, XSS — full AppExchange checklist |
| Process Builder migration (support ended Dec 2025) | **sf-flow** | Converts PB to optimized Flows with bypass logic, consolidation, proper XML generation |
| Governor limit violations | **sf-apex** | Generates bulkified Apex with async decision tables, exception handling, integration patterns |
| Complex SOQL/SOSL queries | **sf-soql** | Builds optimized queries with date literals, geolocation, dynamic SOQL, FIELDS(), FOR UPDATE |
| LWC scaffolding complexity | **sf-lwc** | Full bundles with LDS, navigation, LMS, lifecycle hooks, Jest tests, accessibility |
| Data migration headaches | **sf-data** | Bulk API 2.0, relationship ordering, external ID upsert, file migration, sandbox seeding |
| Metadata XML boilerplate | **sf-schema** | All field types, formulas, rollup summaries, Global Value Sets, record types, permission set groups |

## Skills Catalog

| Skill | Description | Invoke |
|-------|-------------|--------|
| **sf-apex** | Generate and review Apex classes, triggers, batch jobs with governor limit awareness, CRUD/FLS compliance, async patterns (future/queueable/batch/schedulable), integration patterns, and invocable methods | `/sf-apex` |
| **sf-test** | Generate comprehensive test classes with @TestSetup, bulk data, permission testing, callout mocks, async testing, Platform Event/CDC testing, Stub API, and REST endpoint testing | `/sf-test` |
| **sf-flow** | Generate Flow metadata XML, migrate Process Builders to Flows with bypass logic, screen flows, orchestrations, scheduled paths, global variables, and flow test coverage | `/sf-flow` |
| **sf-lwc** | Scaffold Lightning Web Components with LDS, lifecycle hooks, navigation, Lightning Message Service, shadow/light DOM, Jest tests, and SLDS compliance | `/sf-lwc` |
| **sf-soql** | Build and optimize SOQL/SOSL queries with date literals, FIELDS(), geolocation, dynamic SOQL, record locking, ALL ROWS, and WITH USER_MODE | `/sf-soql` |
| **sf-security** | Audit codebases for CRUD/FLS violations, SOQL injection, sharing model issues, custom permission checks, Shield encryption awareness, and AppExchange review readiness | `/sf-security` |
| **sf-deploy** | Orchestrate deployments with scratch orgs, unlocked/2GP packages, destructive changes, Code Analyzer, multiple auth methods, and CI/CD pipeline generation | `/sf-deploy` |
| **sf-data** | Data migration with Bulk API 2.0, external ID upserts, relationship ordering, record type mapping, file migration, and sandbox seeding | `/sf-data` |
| **sf-schema** | Scaffold custom objects with formulas, rollup summaries, geolocation, Global Value Sets, record types, Custom Metadata Types, and permission set groups | `/sf-schema` |
| **sf-find** | Discover the right Salesforce skill for your task | `/sf-find` |

## Agents (Claude Code)

Specialized subagents for parallel, focused work:

| Agent | Purpose | Model |
|-------|---------|-------|
| **apex-reviewer** | Read-only code review for governor limits, bulkification, security | Haiku (fast) |
| **test-generator** | Generate comprehensive test classes from existing code | Sonnet |
| **security-auditor** | Scan entire codebases for security vulnerabilities | Haiku (fast) |
| **deploy-orchestrator** | Multi-step deployment management with error diagnosis | Sonnet |

## Compatibility

These skills follow the open [Agent Skills specification](https://agentskills.io/specification) and work with:

**IDEs & Editors:** Claude Code, Cursor, VS Code Copilot, Windsurf, Cline, Continue, Augment, Junie, OpenCode, Roo Code

**Standalone Agents:** OpenHands, Goose, Mux, Amp, Gemini CLI, Codex

**Platforms:** Databricks, GitHub Copilot, Factory AI, Spring AI

And [many more](https://agentskills.io).

## Prerequisites

1. **Salesforce CLI v2+** — [Install](https://developer.salesforce.com/tools/salesforcecli)
   ```bash
   npm install @salesforce/cli -g
   ```

2. **Authenticated Salesforce org**
   ```bash
   sf org login web --alias myOrg
   ```

3. **Any compatible AI coding agent** — [See full list](https://agentskills.io)

## Configuration

### MCP Server (Optional)

Enable the Salesforce DX MCP server for enhanced org interaction. Edit `.claude/.mcp.json`:

```json
{
  "mcpServers": {
    "salesforce-dx": {
      "command": "npx",
      "args": ["-y", "@anthropic/salesforce-dx-mcp-server"],
      "env": { "SF_ORG_ALIAS": "myOrg" },
      "disabled": false
    }
  }
}
```

### Project Context

Update `CLAUDE.md` in your Salesforce project with org-specific conventions:
- Custom object naming patterns
- API version
- Deployment targets
- Team coding standards

## Project Structure

```
salesforce-skills/
├── skills/                  # All skills (canonical location)
│   ├── sf-apex/             # Apex + 3 reference files
│   ├── sf-test/             # Testing + 1 reference file
│   ├── sf-flow/             # Flows + 2 reference files
│   ├── sf-lwc/              # LWC + 1 reference file
│   ├── sf-soql/             # SOQL/SOSL + 1 reference file
│   ├── sf-security/         # Security + 2 reference files
│   ├── sf-deploy/           # Deploy + 1 reference file
│   ├── sf-data/             # Data + 1 reference file
│   ├── sf-schema/           # Schema + 1 reference file
│   └── sf-find/             # Discovery
├── .agents/skills/          # Cross-client symlinks
├── .claude/                 # Claude Code config + agents
├── references/              # Shared reference docs
├── scripts/                 # Helper scripts (--help, --format json)
└── evals/                   # Skill evaluation framework
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add new skills, improve existing ones, or report issues.

## License

Apache-2.0 — see [LICENSE](LICENSE).

Built by [Clientell](https://clientell.io).
