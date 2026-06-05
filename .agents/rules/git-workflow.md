---
trigger: always_on
---

# Gitflow & Agent Workflow Rules

## Branching Logic
- **main**: Production. Only receives merges from release/hotfix.
- **develop**: Main development branch. All feature branches target this.
- **feature/[id]-name**: From `develop`. For new features/fixes.
- **release/vX.Y.Z**: From `develop`. For version releases.
- **hotfix/**: From `main` or `develop`. For urgent production bugs.

## Commit Message
- Format: `type(scope): description` (feat, fix, docs, refactor, chore, test).

## AI Agent Rules (PR, Auto-Merge & Cleanup)
- **Proactive Committing**: Agent MUST commit changes after completing a logical piece of work. **Do NOT wait for the user to ask for a commit.**
- **Autonomy**: Agent MUST use `gh` CLI for lifecycle management (`gh pr create`, `gh pr merge`).

- **Agent Automation Workflow**:
  1. **Checkout & Sync**: Create and switch to a new `feature/` branch from the latest upstream `develop`.
  2. **Implement & Commit**: Write code, verify it locally, and commit using Conventional Commits.
  3. **Push**: Push the feature branch to the remote repository.
  4. **Create PR**: Open a Pull Request targeting `develop` using:
     ```bash
     gh pr create --base develop --title "type(scope): description" --body "Automated PR by AI Agent."
     ```
  5. **Auto-Merge & Delete**: Immediately merge the PR and delete both the remote and local tracking branch using the CLI (unless manual review is explicitly requested):
     ```bash
     # Squash merge, delete remote branch via GitHub API, and delete local branch
     gh pr merge --squash --delete-branch --admin
     git checkout develop && git pull && git branch -d <feature-branch-name>
     ```

## Definition of Done
A task is NOT considered finished until:
1. The code is implemented, tested, and verified.
2. Changes are committed with proper conventional commit messages.
3. PR is created, successfully merged into `develop`, and the source feature branch is completely deleted (remote & local).