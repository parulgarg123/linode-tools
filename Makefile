
SCRIPT = linode
PYSCRIPT = $(SCRIPT).py
RBSCRIPT = $(SCRIPT).rb

CLEANED_FILES = $(SCRIPT).pyc

INSTALLED = $(PYSCRIPT) $(RBSCRIPT)
DEST = $(HOME)/bin

all:
	@echo "Not implemented."

install: $(PYSCRIPT) $(RBSCRIPT)
	for x in $(INSTALLED); do \
	  cp -v $$x $(DEST); chmod 755 $(DEST)/$$x; done
	@echo "\nFiles ($(INSTALLED)) successfully installed."

uninstall:
	for x in $(INSTALLED); do rm -f $(DEST)/$$x; done
	@echo "\nFiles ($(INSTALLED)) successfully uninstalled."

clean:
	rm -f $(CLEANED_FILES)
