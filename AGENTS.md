# Salesforce Skills — Agent Discovery

This repository provides AI coding agents with specialized Salesforce development skills.

## Available Skills

- **sf-apex** — Generate and review Apex code with governor limit awareness and CRUD/FLS compliance
- **sf-test** — Generate comprehensive test classes with bulk data, permission testing, and callout mocks
- **sf-flow** — Generate Flow metadata XML and migrate Process Builders to optimized Flows
- **sf-lwc** — Scaffold Lightning Web Components with Jest tests
- **sf-soql** — Build and optimize SOQL queries with security enforcement
- **sf-security** — Audit codebases for security vulnerabilities and AppExchange review readiness
- **sf-deploy** — Orchestrate deployments with dependency resolution and error diagnosis
- **sf-data** — Data migration, sandbox seeding, and bulk operations
- **sf-schema** — Scaffold custom objects, fields, permission sets, and validation rules
- **sf-find** — Discover the right Salesforce skill for your task

## Prerequisites

- Salesforce CLI v2+ (`sf`)
- Authenticated Salesforce org (`sf org login web --alias myOrg`)

## Skill Locations

- Cross-client: `.agents/skills/`
- Claude Code: `.claude/skills/`
- Canonical source: `skills/`
