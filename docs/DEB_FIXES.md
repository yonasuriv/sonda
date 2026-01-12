# Debian Package Fixes

## Issues Fixed

### 1. **`set -euo pipefail` Causing Silent Failures**
**Problem:** The strict error handling (`set -e`) was causing the script to exit silently when any command failed, even for optional system file reads.

**Fix:** Changed to `set -uo pipefail` (removed `-e`) to allow functions to handle their own errors gracefully.

**Location:** `bin/sonda` line 7

### 2. **Unsafe File Reads**
**Problem:** Direct `cat` commands on system files that might not exist or be readable were causing failures.

**Fix:** Replaced all unsafe file reads with the `read_system_file` helper function that handles errors gracefully.

**Files Fixed:**
- `lib/includes/logic`:
  - `/etc/hostname` → `read_system_file`
  - `/proc/sys/kernel/hostname` → `read_system_file`
  - `/proc/version` → `read_system_file`
  - `/proc/sys/kernel/osrelease` → `read_system_file`
  - `/proc/sys/kernel/version` → `read_system_file`
  - `/sys/class/dmi/id/bios_date` → `read_system_file`
  - `/sys/class/dmi/id/bios_vendor` → `read_system_file`
  - `/sys/class/dmi/id/bios_version` → `read_system_file`
  - `/sys/class/dmi/id/bios_release` → `read_system_file`
  - `/sys/class/dmi/id/board_name` → `read_system_file`
  - `/sys/class/dmi/id/board_vendor` → `read_system_file`
  - `/etc/machine-id` → `read_system_file`
  - `/proc/sys/kernel/random/boot_id` → `read_system_file`

### 3. **Date Parsing Errors**
**Problem:** Date parsing could fail if firmware_date was invalid, causing arithmetic errors.

**Fix:** Added validation before date parsing and arithmetic operations.

**Location:** `lib/includes/logic` lines 82-90

## Rebuild and Reinstall

After these fixes, rebuild and reinstall:

```bash
# Rebuild the package
make clean
make build

# Reinstall
sudo dpkg -i ../sonda_*.deb

# Or upgrade if already installed
sudo dpkg -i --force-overwrite ../sonda_*.deb
```

## Testing

After reinstalling, test all arguments:

```bash
sonda --version    # Should work
sonda -h           # Should work
sonda -s           # Should work now
sonda -n           # Should work
sonda -cpu         # Should work
sonda -r           # Should work
# etc.
```

## What Changed

1. **Error Handling:** More graceful - commands can fail without crashing the entire script
2. **File Reads:** All system file reads are now safe and handle missing files
3. **Date Parsing:** Validates input before parsing dates

The package should now work correctly with all arguments!
