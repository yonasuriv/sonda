# Flags and Dependencies Fixes

## Issues Fixed

### 1. **VLEVEL Unbound Variable in --all**
**Problem:** The `VLEVEL` variable was used in `modules/info/sys` without initialization, causing an error when `--all` flag was used.

**Error:**
```
/usr/share/sonda/modules/info/sys: line 28: VLEVEL: unbound variable
```

**Fix:** Added initialization check for `VLEVEL` in `complete_system_info()` function. The function now checks if `VLEVEL` is set before using it.

**Location:** `modules/info/sys` - line 23-31

### 2. **Missing net-tools Dependency**
**Problem:** `net-tools` package was required but not listed in Debian package dependencies.

**Fix:** Added `net-tools` to the `Depends` section in `build/debian/control`.

**Location:** `build/debian/control` - line 22

### 3. **Inconsistent Flag Documentation**
**Problem:** Help message (`--help`) didn't match all available flags, and some flags were missing.

**Fix:** Updated help message to include:
- `--check-update` flag
- `--pretty | -nc | --no-color` aliases
- `-memory | -memmory` aliases
- `-network | -networks` aliases
- Consistent formatting

**Location:** `lib/includes/man` - complete rewrite

### 4. **Missing Flag Aliases**
**Problem:** `--no-color` and `-nc` flags were not handled in the argument parser.

**Fix:** Added `-nc|--no-color` as aliases for `--pretty` in the argument parser.

**Location:** `bin/sonda` - line 576

### 5. **Pre-processing Flag Handling**
**Problem:** `--pretty`, `-nc`, and `--no-color` were not all handled in the pre-processing section.

**Fix:** Updated pre-processing to handle all three aliases.

**Location:** `bin/sonda` - line 410

## Updated Help Message

The help message now correctly shows:
- All available flags
- All aliases (e.g., `--pretty | -nc | --no-color`)
- Consistent formatting
- No duplicate entries

## Updated Dependencies

Added to `build/debian/control`:
- `net-tools` - Required for network commands like `ifconfig`, `netstat`, etc.

## Rebuild and Reinstall

After these fixes, rebuild and reinstall:

```bash
# Rebuild the package
make clean
./install.sh source -d debian

# Reinstall
./install.sh release -d debian

# Or build and install in one step
./install.sh source -d debian
```

## Testing

After reinstalling, test the fixes:

```bash
# Test --all flag (should not show VLEVEL error)
sonda --all

# Test --pretty aliases
sonda --pretty -cpu
sonda -nc -cpu
sonda --no-color -cpu

# Test help (should show all flags correctly)
sonda --help

# Verify net-tools is available
ifconfig
```

## Files Modified

- `modules/info/sys` - Fixed VLEVEL unbound variable
- `build/debian/control` - Added net-tools dependency
- `lib/includes/man` - Updated help message to match all flags
- `bin/sonda` - Added flag aliases and improved pre-processing

All flags are now consistent and properly documented!
