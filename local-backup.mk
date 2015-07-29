# PROJECT_ROOT will be set from main Makefile


HARDLINKS_TMP_FOLDER := backup.cp-hardlinks
SYNC_TMP_FOLDER := backup.rsync-incomplete
SYNC_COMPLETE_FOLDER := backup.rsync-completed
LAST_COMPLETE_SYNC_FOLDER := backup.last-0
PREV_VER_1 := backup.last-1
PREV_VER_2 := backup.last-2
PREV_VER_3 := backup.last-3
PREV_VER_4 := backup.last-4


test:
	@if [[ $(shell id -u) > 0 ]]; then \
		echo "This script must be run as root. "; \
		echo "exiting..."; \
		exit 1; \
	fi;


init:
	mkdir -p $(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER)
	mkdir -p $(PROJECT_ROOT)/snapshots/tmp
	@make -s common-action

clear-tmp:
	echo "clearing tmp directory..."
	rm -r $(PROJECT_ROOT)/snapshots/tmp/* 2> /dev/null; true


sync-template:
	@if [[ "$(SYNC_TEMPLATE_VARIABLE)" == "remote" ]]; then \
		make sync-remote ; \
	elif  [[ "$(SYNC_TEMPLATE_VARIABLE)" == "local" ]]; then \
		make sync-local ; \
	elif  [[ "$(SYNC_TEMPLATE_VARIABLE)" == "direct" ]]; then \
		make sync-direct ; \
	fi;

sync-remote:
		if [[ ! -e $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER) ]]; then \
			if [[ ! -e $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) ]]; then \
				if [[ -e $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) ]]; then \
					echo "mark to remove HARDLINKS_TMP_FOLDER: " $(HARDLINKS_TMP_FOLDER); \
					mv $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/tmp/$(shell date +%s) || { exit 1; }; \
				fi; \
				make -s clear-tmp & \
				sleep 2; \
				echo "copying hardlinks..." ; \
				time cp -al $(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER) \
							$(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) || { exit 1; }; \
				mv $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER); \
				fi; \
				make -s clear-tmp & \
				echo "SYNC_TMP_FOLDER ready, starting sync..."; \
			time rsync -aHAXvPh \
				--delete \
				--delete-excluded \
				--exclude-from $(TOOLS_DIR)/'exclude-list.txt' \
				--rsh='ssh -p $(TARGET_SSHD_PORT) -i $(SSH_KEY_FILE)' root@localhost:/  $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) || { exit 1; } ;\
			mv $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER);  \
		fi;



sync-direct:
		if [[ ! -e $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER) ]]; then \
			if [[ ! -e $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) ]]; then \
				if [[ -e $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) ]]; then \
					echo "mark to remove HARDLINKS_TMP_FOLDER: " $(HARDLINKS_TMP_FOLDER); \
					mv $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/tmp/$(shell date +%s) || { exit 1; }; \
				fi; \
				make -s clear-tmp & \
				sleep 2; \
				echo "copying hardlinks..." ; \
				time cp -al $(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER) \
							$(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) || { exit 1; }; \
				mv $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER); \
				fi; \
				make -s clear-tmp & \
				echo "SYNC_TMP_FOLDER ready, starting sync..."; \
			time rsync -aHAXvPh \
				--delete \
				--delete-excluded \
				--exclude-from $(TOOLS_DIR)/'exclude-list.txt' \
				--rsh='ssh -p $(NODE_LOCAL_SSHD_PORT) -i $(SSH_KEY_FILE)' root@$(NODE_LOCAL_IP):/  $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) || { exit 1; } ;\
			mv $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER);  \
		fi;


sync-local:
		if [[ ! -e $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER) ]]; then \
			if [[ ! -e $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) ]]; then \
				if [[ -e $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) ]]; then \
					echo "mark to remove HARDLINKS_TMP_FOLDER: " $(HARDLINKS_TMP_FOLDER); \
					mv $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/tmp/$(shell date +%s) || { exit 1; }; \
				fi; \
				make -s clear-tmp & \
				sleep 2; \
				echo "copying hardlinks..." ; \
				time cp -al $(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER) \
							$(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) || { exit 1; }; \
				mv $(PROJECT_ROOT)/snapshots/$(HARDLINKS_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER); \
				fi; \
				make -s clear-tmp & \
				echo "SYNC_TMP_FOLDER ready, starting sync...";  \
			time rsync -aHAXvPh \
				--delete \
				--delete-excluded \
				--exclude-from $(TOOLS_DIR)/'exclude-list.txt' \
				--whole-file / $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER)/ || { exit 1; } ;\
			mv $(PROJECT_ROOT)/snapshots/$(SYNC_TMP_FOLDER) $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER);  \
		fi;


backup-local-root:
	sudo ${MAKE} backup-root-template SYNC_TEMPLATE_VARIABLE="local"
	@echo "sync..."
	sync



backup-root-template:
	@date
	@echo
	@echo
	@${MAKE} -s test
	@${MAKE} -s rotate-backups
	${MAKE}  sync-template  SYNC_TEMPLATE_VARIABLE=$(SYNC_TEMPLATE_VARIABLE)
	@${MAKE} -s rotate-backups
	@#${MAKE} -s clear-tmp
	@echo
	@echo "Synchronization has been completed successfully... "
	@date
	@echo

rotate-backups:
	@echo "Rotating backups... (if needed)"

	@if [[ -e $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER) ]]; then \
		echo "* create a gap for rotation..."; \
		FROM=$(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER); \
		mv $$FROM $$FROM-1 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_1); \
		mv $$FROM $$FROM-1 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_2); \
		mv $$FROM $$FROM-1 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_3); \
		mv $$FROM $$FROM-1 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_4); \
		mv $$FROM $$FROM-1 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER); \
		mv $$FROM $$FROM-1 2> /dev/null; true; \
	fi;

	@if [[ -e $(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER)-1 ]]; then \
		echo "* do the actual rotation"; \
		FROM=$(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER)-1; \
		TO=$(PROJECT_ROOT)/snapshots/$(PREV_VER_1); \
		mv $$FROM $$TO 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_1)-1; \
		TO=$(PROJECT_ROOT)/snapshots/$(PREV_VER_2); \
		mv $$FROM $$TO 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_2)-1; \
		TO=$(PROJECT_ROOT)/snapshots/$(PREV_VER_3); \
		mv $$FROM $$TO 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_3)-1; \
		TO=$(PROJECT_ROOT)/snapshots/$(PREV_VER_4); \
		mv $$FROM $$TO 2> /dev/null; true; \
		echo "* marking the oldest backup as 'to be deleted'"; \
		FROM=$(PROJECT_ROOT)/snapshots/$(PREV_VER_4)-1; \
		TO=$(PROJECT_ROOT)/snapshots/tmp; \
		mv $$FROM $$TO 2> /dev/null; true; \
		FROM=$(PROJECT_ROOT)/snapshots/$(SYNC_COMPLETE_FOLDER)-1; \
		TO=$(PROJECT_ROOT)/snapshots/$(LAST_COMPLETE_SYNC_FOLDER); \
		mv $$FROM $$TO; \
	fi;
