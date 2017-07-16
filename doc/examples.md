# Examples

This will make appropriate settings on remote source:

    ./backup-over-ssh.sh --source ssh://aea@10.0.8.2:/ --init


This will perform a backup:

    ./backup-over-ssh.sh --source ssh://aea@10.0.8.2:/ --backup ../snapshots/template-rw/
