# author: ceremcem@aktos-elektronik.com
# repo  : bzr branch bzr+ssh://developer@aktos-elektronik.com/cca-dcs.project-tools
#
#

TOOLS_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
# PWD that the main Makefile runs
PROJECT_ROOT := $(THIS_DIR)
LAST_ERR_LOG := last-errors.log

SSH_KEY_FILE := /no/ssh/id/file/specified
SERVER_USERNAME := username

MOUNT_DIR := $(shell mktemp -d)
NODE_USERNAME := pi
NODE_LOCAL_IP := 10.0.10.4
NODE_LOCAL_SSHD_PORT := 22
RENDEZVOUS_HOST := aktos.io
RENDEZVOUS_PORT := 443

NO_NEED_UPDATE_FLAG := $(TOOLS_DIR)/no-need-to-update-flag
NODE_MOUNT_DIR_LINK_NAME := NODE_ROOT


DIRECT_SESSION := session-type--direct
PROXY_SESSION := session-type--proxy
LOCAL_SESSION := session-type--local

# update if needed...
.common-action:
	@make -s check-for-project-root
	@make -s auto-update

ssh:
	$(TOOLS_DIR)/proxy-ssh

mount-root: set-default-session
	@make -s common-action

	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s mount-root-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s mount-root-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		echo "ERROR: this option makes no sense in local-session"; \
	fi

backup-root: set-default-session
	@make -s common-action

	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s backup-remote-root-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s backup-remote-root-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		make -s backup-local-root; \
	fi

.create-disk-from-last-backup:
	cd $(TOOLS_DIR) ;\
	./create-disk-from-backup.sh

.init: set-default-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s init-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s init-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		make -s init-local; \
	fi


.check-for-project-root:
	@if [[ -e $(PROJECT_ROOT)/snapshots ]]; then \
		echo "project root is correct"; \
	else \
		echo "project root is NOT CORRECT (no snapstohs dir detected)"; \
		echo ; \
		exit 1; \
	fi;

.auto-update:
	@if [[ ! -e $(NO_NEED_UPDATE_FLAG) ]]; then \
	  echo "Needs auto-update, please wait..."; \
		OLDPWD=$$PWD; \
		cd $(TOOLS_DIR); \
		git pull || exit 1; \
		touch $(NO_NEED_UPDATE_FLAG); \
		cd $$OLDPWD; \
	fi;

update:
	@echo "setting 'need for auto-update' flag..."
	@rm $(NO_NEED_UPDATE_FLAG) 2> /dev/null; true
	@make -s auto-update

.init-all:
	@make -s init-proxy

.init-proxy:
	@${MAKE} -s init-common
	@${MAKE} ssh-copy-user-id
	@make -s common-action

.init-direct:
	@${MAKE} -s init-common
	@${MAKE} ssh-copy-user-id-direct
	@make -s common-action



.mount-root-proxy: get-sshd-port
	@make -s common-action
	$(SSHFS) -p $(TARGET_SSHD_PORT) $(NODE_USERNAME)@localhost:/ $(MOUNT_DIR)
	rm  $(NODE_MOUNT_DIR_LINK_NAME) 2> /dev/null; true
	ln -sf $(MOUNT_DIR) $(NODE_MOUNT_DIR_LINK_NAME)

.mount-root-direct:
	@make -s common-action
	$(SSHFS) -p $(NODE_LOCAL_SSHD_PORT) $(NODE_USERNAME)@$(NODE_LOCAL_IP):/ $(MOUNT_DIR)
	rm  $(NODE_MOUNT_DIR_LINK_NAME) 2> /dev/null; true
	ln -sf $(MOUNT_DIR) $(NODE_MOUNT_DIR_LINK_NAME)


umount-root:
	fusermount -u $(shell readlink ./$(NODE_MOUNT_DIR_LINK_NAME))
	rmdir $(shell readlink ./$(NODE_MOUNT_DIR_LINK_NAME))
	rm ./$(NODE_MOUNT_DIR_LINK_NAME)


.backup-remote-root-proxy:
	@make -s common-action
	@echo
	@echo
	@echo "Backup remote root folder here..."

	@${MAKE} -s get-sshd-port
	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE=proxy

.backup-remote-root-direct:
	@make -s common-action
	@echo
	@echo
	@echo "Backup remote root folder here..."

	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE=direct
