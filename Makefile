#
# author: cem@aktos.io
#
TOOLS_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
# PWD that the main Makefile runs
PROJECT_ROOT := $(THIS_DIR)

ssh:
	$(TOOLS_DIR)/proxy-ssh

mount-root:
	$(TOOLS_DIR)/proxy-mount

backup-root:
	$(TOOLS_DIR)/proxy-backup

umount-root:
	$(TOOLS_DIR)/umount-node-root
