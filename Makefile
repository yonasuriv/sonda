# Makefile for building Sonda Debian package

.PHONY: clean build install package

VERSION := $(shell cat VERSION 2>/dev/null || echo "1.8.5")
DEB_VERSION := $(VERSION)-1
PACKAGE_NAME := sonda_$(DEB_VERSION)_all.deb
DIST_DIR := dist/sonda_$(DEB_VERSION)

clean:
	@echo ""
	@echo "Cleaning build artifacts..."
	@echo ""
	rm -rf packagng/debian/sonda
	rm -rf packagng/debian/.debhelper
	rm -f packagng/debian/files
	rm -f packagng/debian/substvars
	rm -f packagng/debian/*.debhelper.log
	rm -f packagng/debian/*.substvars
	rm -f packagng/debian/*.debhelper
	rm -f packagng/debian/*.log
	rm -f $(PACKAGE_NAME)
	rm -f sonda_*.deb
	rm -f packagng/../sonda_*.deb
	rm -f packagng/../sonda_*.buildinfo
	rm -f packagng/../sonda_*.changes
	rm -f packagng/../sonda_*.dsc
	rm -f packagng/../sonda_*.tar.*
	@echo ""
	@echo "Done."

collect:
	@echo ""
	@echo "Collecting build artifacts..."
	@mkdir -p $(DIST_DIR)
	@if [ -f $(PACKAGE_NAME) ]; then \
		cp -a $(PACKAGE_NAME) $(DIST_DIR)/; \
	fi
	@if [ -f sonda_$(DEB_VERSION)_*.buildinfo ]; then \
		cp -a sonda_$(DEB_VERSION)_*.buildinfo $(DIST_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f sonda_$(DEB_VERSION)_*.changes ]; then \
		cp -a sonda_$(DEB_VERSION)_*.changes $(DIST_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f sonda_$(DEB_VERSION).dsc ]; then \
		cp -a sonda_$(DEB_VERSION).dsc $(DIST_DIR)/ 2>/dev/null || true; \
	fi
	@if [ -f sonda_$(DEB_VERSION).tar.* ]; then \
		cp -a sonda_$(DEB_VERSION).tar.* $(DIST_DIR)/ 2>/dev/null || true; \
	fi
	@echo "Collected artifacts in $(DIST_DIR)"
	@echo ""

build: clean
	@echo ""
	@echo "Building debian package..."
	@echo ""
	cd packagng && dpkg-buildpackage -us -uc -b
	@if [ -f $(PACKAGE_NAME) ]; then \
		echo "Package built in root directory: $(PACKAGE_NAME)"; \
	fi
	@echo ""
	@echo "Package built successfully."
	@$(MAKE) collect

package: build
	@echo "Package: $(PACKAGE_NAME)"
	@if [ -f $(DIST_DIR)/$(PACKAGE_NAME) ]; then \
		ls -lh $(DIST_DIR)/$(PACKAGE_NAME); \
	elif [ -f $(PACKAGE_NAME) ]; then \
		ls -lh $(PACKAGE_NAME); \
	else \
		echo "Package not found"; \
	fi

install: package
	@echo ""
	@echo "Installing package..."
	@if [ -f $(DIST_DIR)/$(PACKAGE_NAME) ]; then \
		sudo dpkg -i $(DIST_DIR)/$(PACKAGE_NAME); \
	elif [ -f $(PACKAGE_NAME) ]; then \
		sudo dpkg -i $(PACKAGE_NAME); \
	else \
		echo "Error: Package $(PACKAGE_NAME) not found"; \
		exit 1; \
	fi
	@echo "Installation complete!"
	@echo ""

uninstall:
	@echo "Uninstalling package..."
	sudo dpkg -r sonda
	@echo "Uninstallation complete!"

help:
	@echo "Sonda Debian Package Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make build      - Build the Debian package"
	@echo "  make package    - Build and show package info"
	@echo "  make install    - Build and install the package"
	@echo "  make uninstall  - Uninstall the package"
	@echo "  make help       - Show this help message"
	@echo ""
	@echo "Manual installation:"
	@echo "  sudo dpkg -i sonda_*.deb"
	@echo "  sudo apt-get install -f  # Install dependencies if needed"
