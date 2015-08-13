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
	fi
		
mount-root: set-default-session
	@if [[ -f $(DIRECT_SESSION) ]]; then \
		make -s mount-root-direct; \
	elif [[ -f $(PROXY_SESSION) ]]; then \
		make -s mount-root-proxy; \
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
	rm $(NO_NEED_UPDATE_FLAG) 2> /dev/null; true
	@make -s auto-update

init-all:
	@make -s init-proxy

init-proxy:
	@${MAKE} -s init
	@${MAKE} ssh-copy-user-id
	@make -s common-action

init-direct:
	@${MAKE} -s init
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
	ssh-copy-id -i $(SSH_KEY_FILE) -p $(TARGET_SSHD_PORT) $(NODE_USERNAME)@localhost
	#ssh-copy-id -i $(SSH_KEY_FILE) -p $(TARGET_SSHD_PORT) root@localhost
	ssh -o PasswordAuthentication=no root@$localhost -p $(TARGET_SSHD_PORT)  -i $(SSH_KEY_FILE) exit 0 || \
	ssh -t -p $(TARGET_SSHD_PORT) root@localhost "echo $(PUBLIC_KEY) | sudo tee -a /root/.ssh/authorized_keys; sudo chmod 600 /root/.ssh/authorized_keys" 



ssh-copy-user-id-direct: 
	ssh -o PasswordAuthentication=no root@$(NODE_LOCAL_IP) -p $(NODE_LOCAL_SSHD_PORT)  -i $(SSH_KEY_FILE) exit 0 || \
	ssh -t -p $(NODE_LOCAL_SSHD_PORT) $(NODE_USERNAME)@$(NODE_LOCAL_IP) "echo $(PUBLIC_KEY) | sudo tee -a /root/.ssh/authorized_keys; sudo chmod 600 /root/.ssh/authorized_keys" 
	ssh-copy-id -i $(SSH_KEY_FILE) -p $(NODE_LOCAL_SSHD_PORT) $(NODE_USERNAME)@$(NODE_LOCAL_IP)
	

get-sshd-port:
	@make -s common-action
	@echo "getting sshd-port"
	ssh $(SERVER_USERNAME)@ceremcem.net -L $(TARGET_SSHD_PORT):localhost:$(TARGET_SSHD_PORT) -N 2> /dev/null &
	sleep 5

ssh-proxy: get-sshd-port
	ssh $(NODE_USERNAME)@localhost -p $(TARGET_SSHD_PORT)

ssh-direct: 
	ssh $(NODE_USERNAME)@$(NODE_LOCAL_IP) -p $(NODE_LOCAL_SSHD_PORT)

backup-remote-root-proxy:
	@make -s common-action
	@echo
	@echo
	@echo "Backup remote root folder here..."

	@${MAKE} -s get-sshd-port
	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE=remote

backup-remote-root-direct:
	@make -s common-action
	@echo
	@echo
	@echo "Backup remote root folder here..."

	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE=direct


