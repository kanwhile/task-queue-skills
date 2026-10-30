# task-queue-skills

Three [Claude Code](https://claude.com/claude-code) skills that turn a task board into an unattended work queue for one repo, inside [herdr](https://herdr.dev):

| skill | what it does |
|---|---|
| `/setup-task-queue` | writes `.claude/task-queue.md` for the current repo (infers what it can, asks the rest), prepares the board, re-run to check (doctor) |
| `/run-task-queue` | one pass of the queue: cleans merged worktrees, fixes conflicting or changes-requested PRs first, merges one PR that passes every gate when the config has a `merge` section (clean against main, checks green, the agent's latest stamp comment at head with nothing left for the owner to decide, nothing posted after it, no protected paths touched), then opens a new herdr tab running `/pick-task` on the top card · `--dry-run` reports without touching anything · meant for `/loop` |
| `/pick-task` | works one card end to end in its own worktree until a PR is open, or fixes an existing PR (merge conflict, review round) |

Boards supported (`kind:` in the config): a Notion database, a GitHub Project (v2), or plain GitHub Issues with labels. Everything repo-specific (board ids, status names, setup/verify/CI commands, branch pattern, delegation split, post-PR hooks) lives in that repo's `.claude/task-queue.md`; the skills themselves carry only the generic loop. The skills are written in Thai, like the boards they run on.

## Install

```bash
git clone https://github.com/kanwhile/task-queue-skills ~/Documents/GitHub/task-queue-skills
~/Documents/GitHub/task-queue-skills/install.sh
```

`install.sh` symlinks each skill into `~/.agents/skills/` and from there into `~/.claude/skills/` and every `~/.claude-*/skills/` (one symlink per skill, so each Claude config dir sees the same files). `install.sh --uninstall` removes only the links it made.

Then, inside the repo you want to run: `/setup-task-queue`, check `/run-task-queue --dry-run`, and start the loop with `/loop /run-task-queue`. Run that controller session on Sonnet (`claude --model claude-sonnet-5-5`): it only orchestrates, so Opus is wasted on it, while Haiku tends to skip the rarer branches (trust prompt, locked worktrees, blocked agents). The per-card model is chosen by the `โมเดล` rubric in the config.

## Layout

```
skills/_shared/config.md       what each section of .claude/task-queue.md means
skills/_shared/trackers.md     the five board actions per kind, with the exact gh / Notion calls
skills/run-task-queue/
skills/pick-task/              + task-template.md (the per-task handoff file in .tasks/)
skills/setup-task-queue/       + task-queue.template.md
```

Each skill folder holds symlinks `config.md` and `trackers.md` to `_shared/` so a skill installed on its own still finds them.

## Requirements

`herdr`, `gh` (with the `project` scope for GitHub Projects), `budget-check` (the quota gate from this machine's tooling; optional — without it the quota gate and cost log are skipped), and the `delegate-wave` / `herdr` skills for delegation.
