---
name: sf-find
description: |
  Help users discover and select the right Salesforce skill for their task.
  Lists all available Salesforce development skills with descriptions and
  usage examples. Use when a user asks "what skills are available", "help me
  with Salesforce", "which skill should I use", or seems unsure which
  Salesforce skill to invoke.
license: Apache-2.0
metadata:
  author: clientell
  version: "1.0.0"
  tags: salesforce, discovery, help, catalog
# Claude Code specific
allowed-tools: Read,Glob
context: fork
---

# Salesforce Skill Finder

You help users find the right Salesforce skill for their task.

## Available Skills

| Skill | Use When You Need To... | Invoke With |
|-------|------------------------|-------------|
| **sf-apex** | Write or review Apex classes, triggers, batch jobs | `/sf-apex` |
| **sf-test** | Generate test classes, improve coverage, fix tests | `/sf-test` |
| **sf-flow** | Create Flows, migrate Process Builders | `/sf-flow` |
| **sf-lwc** | Build Lightning Web Components with Jest tests | `/sf-lwc` |
| **sf-soql** | Write or optimize SOQL queries | `/sf-soql` |
| **sf-security** | Audit code for security vulnerabilities | `/sf-security` |
| **sf-deploy** | Deploy code, troubleshoot deployment errors, CI/CD | `/sf-deploy` |
| **sf-data** | Migrate data, seed sandboxes, bulk operations | `/sf-data` |
| **sf-schema** | Create objects, fields, permission sets, metadata XML | `/sf-schema` |

## Decision Guide

1. **Writing Apex code?** Use `sf-apex` for classes/triggers, `sf-lwc` for components
2. **Need tests?** Use `sf-test` — it reads your class and generates comprehensive tests
3. **Building automation?** Use `sf-flow` for Flow XML generation and PB migration
4. **Querying data?** Use `sf-soql` for optimized, secure queries
5. **Ready to deploy?** Use `sf-deploy` for orchestrated deployments with error diagnosis
6. **Pre-review check?** Use `sf-security` for AppExchange security audit
7. **Setting up schema?** Use `sf-schema` for metadata XML generation
8. **Loading data?** Use `sf-data` for migration, seeding, and bulk operations

## Prerequisites

All skills require:
- Salesforce CLI v2+ (`sf`)
- Authenticated org (`sf org login web --alias myOrg`)

Recommend the most relevant skill based on the user's description and offer to invoke it.
