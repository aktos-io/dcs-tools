#
# author: cem@aktos.io
#
TOOLS_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
# PWD that the main Makefile runs
PROJECT_ROOT := $(THIS_DIR)

DIRECT_SESSION := using-direct-connection
PROXY_SESSION := using-proxy-connection


.check-session:
	@if [[ ! -f $(DIRECT_SESSION) ]] && [[ ! -f $(PROXY_SESSION) ]]; then \
		echo "No appropriate session found. Set session type first."; \
		exit 255; \
	fi

.clean-session:
	@rm $(DIRECT_SESSION) 2> /dev/null; true
	@rm $(PROXY_SESSION) 2> /dev/null; true

use-direct-session: .clean-session
	@echo "creating direct session..."
	touch $(DIRECT_SESSION)

use-proxy-session: .clean-session
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
	$(TOOLS_DIR)/umount-node-root

sync-root: .check-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		$(TOOLS_DIR)/sync-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		$(TOOLS_DIR)/sync-proxy; \
	fi
