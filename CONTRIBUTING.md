# Contributing to Salesforce Skills

Thanks for contributing! This guide covers how to add new skills, improve existing ones, and submit changes.

## Adding a New Skill

### 1. Create the skill directory

```bash
mkdir -p skills/sf-your-skill
```

### 2. Create SKILL.md with required frontmatter

```yaml
---
name: sf-your-skill
description: |
  What this skill does and when to use it. Be specific about trigger
  conditions — mention file extensions, keywords, and scenarios that
  should activate this skill. Max 1024 characters.
license: Apache-2.0
compatibility: Requires Salesforce CLI (sf) v2+.
metadata:
  author: your-github-username
  version: "1.0.0"
  tags: salesforce, your-tags-here
# Claude Code specific (optional)
allowed-tools: Read,Write,Edit,Bash(sf *),Glob,Grep
context: fork
---

# Your Skill Title

Instructions for the AI agent follow here in markdown.
```

### 3. Frontmatter rules

| Field | Required | Rules |
|-------|----------|-------|
| `name` | Yes | Max 64 chars, lowercase + hyphens only, must match directory name |
| `description` | Yes | Max 1024 chars, describe WHAT it does AND WHEN to use it |
| `license` | Yes | `Apache-2.0` for this repo |
| `compatibility` | Recommended | Document runtime requirements |
| `metadata` | Recommended | Include `author`, `version`, `tags` |
| `allowed-tools` | Optional | Claude Code tool permissions |
| `context` | Optional | `fork` for isolated subagent execution |

### 4. Add supporting files (optional)

```
skills/sf-your-skill/
├── SKILL.md              # Required
├── references/           # Optional: detailed docs loaded on-demand
│   └── detailed-guide.md
├── scripts/              # Optional: executable helpers
│   └── helper.sh
└── assets/               # Optional: templates, data files
```

### 5. Keep it concise

- SKILL.md body should be under 500 lines / 5000 tokens
- Put detailed content in `references/` — it loads on-demand
- Only include what the AI agent wouldn't already know
- Focus on gotchas, edge cases, and Salesforce-specific patterns

### 6. Create symlinks

```bash
ln -s ../../skills/sf-your-skill .claude/skills/sf-your-skill
ln -s ../../skills/sf-your-skill .agents/skills/sf-your-skill
```

### 7. Add an eval file

Create `evals/sf-your-skill.eval.md` with trigger test cases. See [evals/README.md](evals/README.md).

### 8. Update install.sh

Add your skill to the installer if needed.

## Writing Good Descriptions

The `description` field is the primary trigger mechanism — agents use it to decide when to activate your skill.

**Do:**
- Use imperative phrasing: "Use when..."
- Include specific keywords users might say
- Mention file extensions that should trigger activation
- Be "pushy" — agents tend to undertrigger

**Don't:**
- Be vague: "Helps with Salesforce stuff"
- Use first person: "I can help you with..."
- Exceed 1024 characters

## Script Guidelines

Scripts in `scripts/` should follow agentic design:

- Support `--help` flag
- Use `--format json` for structured output
- Write diagnostics to stderr, results to stdout
- Use meaningful exit codes (0=success, 1=issues found, 2=bad args)
- Be idempotent
- No interactive prompts

## Submitting Changes

1. Fork the repository
2. Create a branch: `git checkout -b add-sf-your-skill`
3. Make your changes
4. Verify: `find skills/ -name SKILL.md` lists your skill
5. Submit a pull request

## Code of Conduct

Be respectful, constructive, and collaborative. We're building tools to help developers — let's help each other too.
