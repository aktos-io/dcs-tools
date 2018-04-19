#
# author: cem@aktos.io
#
TOOLS_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
# PWD that the main Makefile runs
PROJECT_ROOT := $(THIS_DIR)

DIRECT_SESSION := comm-direct
PROXY_SESSION := comm-tunnel

UP_TO_DATE := up-to-date

.check-update-needs:
	@if [[ ! -f $(UP_TO_DATE) ]]; then \
		echo "!!! No $(UP_TO_DATE) flag found"; \
		make -s update; \
	fi

.check-session: .check-update-needs
	@if [[ ! -f $(DIRECT_SESSION) ]] && [[ ! -f $(PROXY_SESSION) ]]; then \
		echo "ERROR: Set connection method first: make conn-..."; \
		exit 0; \
	fi

.clean-session:
	@rm $(DIRECT_SESSION) 2> /dev/null; true
	@rm $(PROXY_SESSION) 2> /dev/null; true

comm-direct: .clean-session
	@echo "creating direct session..."
	touch $(DIRECT_SESSION)

comm-tunnel: .clean-session
	@echo "creating proxy session..."
	touch $(PROXY_SESSION)

ssh: .check-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		$(TOOLS_DIR)/ssh-direct $(ARGS); \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		$(TOOLS_DIR)/ssh-proxy $(ARGS); \
	fi

mount-root: .check-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		$(TOOLS_DIR)/mount-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		$(TOOLS_DIR)/mount-proxy; \
	fi

umount-root:
	@$(TOOLS_DIR)/umount-node-root

sync-root: .check-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		$(TOOLS_DIR)/sync-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		$(TOOLS_DIR)/sync-proxy; \
	fi

update:
	@$(TOOLS_DIR)/update.sh
	touch $(UP_TO_DATE)

configure:
	@nano $(PROJECT_ROOT)/config.sh

backup-sync-root:
	@$(TOOLS_DIR)/toolset-make-backup.sh

method-hardlinks:
	@rm -f $(PROJECT_ROOT)/method-* 2> /dev/null || true
	@touch $(PROJECT_ROOT)/method-hardlinks
	@echo "INFO: make backup-sync-root will use hardlinks method."

method-btrfs:
	@echo "WARNING: ./sync-root/ MUST be a BTRFS subvolume"
	@rm -f $(PROJECT_ROOT)/method-* 2> /dev/null || true
	@touch $(PROJECT_ROOT)/method-btrfs
	@echo "INFO: make backup-sync-root will use btrfs method."
