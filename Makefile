
SCRIPT = linode
PYSCRIPT = $(SCRIPT).py
RBSCRIPT = $(SCRIPT).rb

INSTALLED = $(PYSCRIPT) $(RBSCRIPT)
DEST = $(HOME)/bin

all:
	echo "Not implemented."

install: $(PYSCRIPT) $(RBSCRIPT)
	for x in $(INSTALLED); do \
	  cp -v $$x $(DEST); chmod 755 $(DEST)/$$x; done
	echo "Files ($(INSTALLED)) successfully installed."

uninstall:
	for x in $(INSTALLED); do rm -f $(DEST)/$$x; done
	echo "Files ($(INSTALLED)) successfully uninstalled."

