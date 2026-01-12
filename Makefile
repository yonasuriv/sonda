# Makefile for building Sonda Debian package

.PHONY: clean build install package

VERSION := $(shell cat lib/version/current 2>/dev/null || echo "1.8.2")
DEB_VERSION := $(VERSION)-1
PACKAGE_NAME := sonda_$(DEB_VERSION)_all.deb

clean:
	@echo ""
	@echo "Cleaning build artifacts..."
	@echo ""
	rm -rf debian/sonda
	rm -rf debian/.debhelper
	rm -f debian/files
	rm -f debian/substvars
	rm -f debian/*.debhelper.log
	rm -f debian/*.substvars
	rm -f debian/*.debhelper
	rm -f debian/*.log
	rm -f $(PACKAGE_NAME)
	rm -f sonda_*.deb
	@echo ""
	@echo "Done."

build: clean
	@echo ""
	@echo "Building debian package..."
	@echo ""
	dpkg-buildpackage -us -uc -b
	@echo ""
	@echo "Package built successfully."

package: build
	@echo "Package: $(PACKAGE_NAME)"
	@ls -lh ../$(PACKAGE_NAME) 2>/dev/null || ls -lh $(PACKAGE_NAME) 2>/dev/null || echo "Package location may vary"

install: package
	@echo ""
	@echo "Installing package..."
	sudo dpkg -i ../$(PACKAGE_NAME) 2>/dev/null || sudo dpkg -i $(PACKAGE_NAME) 2>/dev/null || echo "Please install manually: sudo dpkg -i $(PACKAGE_NAME)"
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
