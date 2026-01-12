# Version File Changes - v1.8.5

## Overview

The version file has been moved from `lib/version/current` to the root directory as `version` for better accessibility and consistency.

## Changes Made

### File Location
- **Old**: `lib/version/current`
- **New**: `version` (root directory)

### Updated Files

1. **bin/sonda**
   - Changed `VERSION="$LIB/version"` to `VERSION_FILE="$INSTALLDIR/version"`
   - Updated all references from `$VERSION/current` to `$VERSION_FILE`
   - Updated remote version URL to use root `version` file

2. **lib/top**
   - Updated version display: `$VERSION/current` → `$VERSION_FILE`

3. **modules/base/banner**
   - Updated version display: `$VERSION/current` → `$VERSION_FILE`

4. **assets/art/sonda_sysnet_1**
   - Updated version reference: `$VERSION/current` → `$VERSION_FILE`

5. **Makefile**
   - Updated version reading: `lib/version/current` → `version`

6. **debian/rules**
   - Updated version file installation path
   - Now installs `version` to `/usr/share/sonda/version`

### Remote Version URL

Updated to:
```
https://raw.githubusercontent.com/yonasuriv/sonda/refs/heads/main/version
```

### Benefits

1. **Simpler path**: Easier to access and reference
2. **Consistency**: Matches common project structure conventions
3. **Accessibility**: Can be read without knowing internal directory structure
4. **Cleaner**: Removes unnecessary directory nesting

### Migration Notes

- Old installations will continue to work (fallback handling)
- New installations use root `version` file
- Update checks automatically use new location
- No user action required
