# author: ceremcem@aktos-elektronik.com
# repo  : bzr branch bzr+ssh://developer@aktos-elektronik.com/cca-dcs.project-tools
#
#

TOOLS_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
# PWD that the main Makefile runs
PROJECT_ROOT := $(THIS_DIR)

SSH_KEY_FILE := /path/to/id_rsa
SERVER_USERNAME := username

MOUNT_DIR := $(shell mktemp -d)
NODE_USERNAME := pi
NODE_LOCAL_IP := 10.0.10.4
NODE_LOCAL_SSHD_PORT := 22

NO_NEED_UPDATE_FLAG := $(TOOLS_DIR)/no-need-to-update-flag
NODE_MOUNT_DIR_LINK_NAME := NODE_ROOT



export


include $(TOOLS_DIR)/config.mk
include $(TOOLS_DIR)/local-backup.mk

PUBLIC_KEY := $(shell ssh-keygen -y -f $(SSH_KEY_FILE))


DIRECT_SESSION := session-type--direct
PROXY_SESSION := session-type--proxy
LOCAL_SESSION := session-type--local

# update if needed...
common-action:
	@make -s check-for-project-root
	@make -s auto-update

clean-session:
	@rm $(DIRECT_SESSION) 2> /dev/null; true
	@rm $(PROXY_SESSION) 2> /dev/null; true
	@rm $(LOCAL_SESSION) 2> /dev/null; true

set-direct-session: clean-session
	@echo "creating direct session..."
	touch $(DIRECT_SESSION)

set-proxy-session: clean-session
	@echo "creating proxy session..."
	touch $(PROXY_SESSION)

set-local-session: clean-session
	@echo "creating local session..."
	touch $(LOCAL_SESSION)

set-default-session:
	@if test ! -e $(DIRECT_SESSION) && test ! -e $(PROXY_SESSION) && test ! -e $(LOCAL_SESSION); then \
		echo "no previous sessions found, setting default session..."; \
		make -s set-direct-session; \
	fi

ssh: set-default-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s ssh-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s ssh-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		echo "ERROR: this option makes no sense in local-session"; \
	fi

mount-root: set-default-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s mount-root-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s mount-root-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		echo "ERROR: this option makes no sense in local-session"; \
	fi

backup-root: set-default-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s backup-remote-root-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s backup-remote-root-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		make -s backup-local-root; \
	fi

init: set-default-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s init-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s init-proxy; \
	elif [[ -f $(LOCAL_SESSION) ]]; then \
		make -s init-local; \
	fi


check-for-project-root:
	@if [[ -e $(PROJECT_ROOT)/snapshots ]]; then \
		echo "project root is correct"; \
	else \
		echo "project root is NOT CORRECT (no snapstohs dir detected)"; \
		echo ; \
		exit 1; \
	fi;

auto-update:
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

init-all:
	@make -s init-proxy

init-proxy:
	@${MAKE} -s init-common
	@${MAKE} ssh-copy-user-id
	@make -s common-action

init-direct:
	@${MAKE} -s init-common
	@${MAKE} ssh-copy-user-id-direct
	@make -s common-action



mount-root-proxy: get-sshd-port
	@make -s common-action
	sshfs -p $(TARGET_SSHD_PORT) $(NODE_USERNAME)@localhost:/ $(MOUNT_DIR)
	rm  $(NODE_MOUNT_DIR_LINK_NAME) 2> /dev/null; true
	ln -sf $(MOUNT_DIR) $(NODE_MOUNT_DIR_LINK_NAME)

mount-root-direct:
	@make -s common-action
	sshfs -p $(NODE_LOCAL_SSHD_PORT) $(NODE_USERNAME)@$(NODE_LOCAL_IP):/ $(MOUNT_DIR)
	rm  $(NODE_MOUNT_DIR_LINK_NAME) 2> /dev/null; true
	ln -sf $(MOUNT_DIR) $(NODE_MOUNT_DIR_LINK_NAME)


umount-root:
	fusermount -u $(shell readlink ./$(NODE_MOUNT_DIR_LINK_NAME))
	rmdir $(shell readlink ./$(NODE_MOUNT_DIR_LINK_NAME))
	rm ./$(NODE_MOUNT_DIR_LINK_NAME)

ssh-copy-user-id: get-sshd-port
	make -s ssh-copy-user-id-template SSH_CONN_ADDR="localhost" SSH_CONN_PORT=$(TARGET_SSHD_PORT)

ssh-copy-user-id-direct:
	make -s ssh-copy-user-id-template SSH_CONN_ADDR=$(NODE_LOCAL_IP) SSH_CONN_PORT=$(NODE_LOCAL_SSHD_PORT)

ssh-copy-user-id-template:
	@echo "copying user id..."
	ssh -o PasswordAuthentication=no root@$(SSH_CONN_ADDR) -p $(SSH_CONN_PORT)  -i $(SSH_KEY_FILE) exit 0 || { echo "ssh key will be registered for root and normal user by normal user..."; ssh -t -p $(SSH_CONN_PORT) $(NODE_USERNAME)@$(SSH_CONN_ADDR) "sudo mkdir /root/.ssh 2> /dev/null; echo $(PUBLIC_KEY) | sudo tee -a /root/.ssh/authorized_keys; sudo chmod 600 /root/.ssh/authorized_keys"; }
	ssh -o PasswordAuthentication=no $(NODE_USERNAME)@$(SSH_CONN_ADDR) -p $(SSH_CONN_PORT)  -i $(SSH_KEY_FILE) exit 0 || { echo "ssh key will be registered for normal user by root..."; ssh -t -p $(SSH_CONN_PORT) root@$(SSH_CONN_ADDR) 'echo naber; sudo -u '$(NODE_USERNAME)' bash -c  \"echo \\\"this is remote and i am `whoami` and node username: /home/$(NODE_USERNAME) \\\"; cd; mkdir -p /home/$(NODE_USERNAME)/.ssh; echo '$(PUBLIC_KEY)' | tee -a /home/$(NODE_USERNAME)/.ssh/authorized_keys | chmod 600 /home/$(NODE_USERNAME)/.ssh/authorized_keys \"'; }
	@echo "checking if keys are installed correctly..."
	ssh -o PasswordAuthentication=no $(NODE_USERNAME)@$(SSH_CONN_ADDR) -p $(SSH_CONN_PORT)  -i $(SSH_KEY_FILE) "exit 0" && \
	ssh -o PasswordAuthentication=no root@$(SSH_CONN_ADDR) -p $(SSH_CONN_PORT)  -i $(SSH_KEY_FILE) "exit 0"
	@if [[ "$$?" == "0" ]]; then \
		echo "ssh id files installed successfully..."; \
	else \
		echo "ssh-copy-user-id-direct FAILED!"; \
	fi; 

get-sshd-port:
	@make -s common-action
	@echo "getting sshd-port"
	ssh $(SERVER_USERNAME)@ceremcem.net -L $(TARGET_SSHD_PORT):localhost:$(TARGET_SSHD_PORT) -N 2> /dev/null &
	sleep 5

ssh-proxy: get-sshd-port
	ssh $(NODE_USERNAME)@localhost -p $(TARGET_SSHD_PORT) $(SSH_ARGS)

ssh-direct:
	ssh $(NODE_USERNAME)@$(NODE_LOCAL_IP) -p $(NODE_LOCAL_SSHD_PORT) $(SSH_ARGS)

backup-remote-root-proxy:
	@make -s common-action
	@echo
	@echo
	@echo "Backup remote root folder here..."

	@${MAKE} -s get-sshd-port
	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE=proxy

backup-remote-root-direct:
	@make -s common-action
	@echo
	@echo
	@echo "Backup remote root folder here..."

	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE=direct
