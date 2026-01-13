# Makefile for building Sonda Debian package

.PHONY: clean build install package

VERSION := $(shell cat src/version 2>/dev/null || echo "1.8.5")
DEB_VERSION := $(VERSION)-1
PACKAGE_NAME := sonda_$(DEB_VERSION)_all.deb

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
	@echo ""
	@echo "Done."

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

package: build
	@echo "Package: $(PACKAGE_NAME)"
	@if [ -f $(PACKAGE_NAME) ]; then \
		ls -lh $(PACKAGE_NAME); \
	else \
		echo "Package not found in root directory"; \
	fi

install: package
	@echo ""
	@echo "Installing package..."
	@if [ -f $(PACKAGE_NAME) ]; then \
		sudo dpkg -i $(PACKAGE_NAME); \
	else \
		echo "Error: Package $(PACKAGE_NAME) not found in root directory"; \
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
