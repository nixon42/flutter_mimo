---
trigger: always_on
---

## Remote-Server & NFS Environment Rules
- **fvm** : this project use FVM, to execute flutter command add fvm in front (fvm flutter docktor)
- **Environment Context**: Flutter SDK and execution environment reside on the remote server (`nixon@192.168.99.10`). The local project directory is mounted via NFS to that server.
- **Hot Reload / Run Preservation**: A `flutter run` session is currently active.
- **File Changes via NFS**: Since the project is an NFS mount, the agent can write/edit files locally. These changes will sync automatically to the remote server and trigger the active hot refresh.
- **Remote Git & CLI Operations**: 
  - All Git operations (`git commit`, `git push`, `git branch`) and GitHub CLI operations (`gh pr create`, `gh pr merge`) MUST be executed in the environment where the `.git` directory and credentials are valid (typically local, unless the agent is explicitly SSH-ed into `nixon@192.168.99.10`).
  - If Flutter-specific CLI tasks (like `flutter pub get` or code generation) are needed, the agent must proxy them via SSH and fvm:
    ```bash
    ssh nixon@192.168.99.10 "cd /path/to/remote/project && fvm flutter pub get"
    ```