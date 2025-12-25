#!/usr/bin/env python3
"""
Telegram-iOS Intel x86_64 Support Patch Script
===============================================
This script adds Intel Mac (x86_64) simulator support to the Telegram-iOS project.

Usage:
    cd /path/to/Telegram-iOS
    python3 add_x86_64_support.py

What it does:
1. Adds ios_sim_x86_64 config_setting to build-system/BUILD
2. Modifies third-party/webrtc/BUILD to support x86_64
3. Modifies third-party/libyuv/BUILD to support x86_64
4. Modifies third-party/openh264/BUILD to support x86_64
5. Modifies third-party/webrtc/libsrtp/BUILD to support x86_64
6. Modifies third-party/webrtc/crc32c/BUILD to support x86_64
7. Adds debug_sim_x86_64 configuration to build-system/Make/Make.py
8. Patches shell script genrules in various BUILD files

Run with --dry-run to see what would be changed without making modifications.
"""

import os
import re
import sys
import argparse
import shutil
from datetime import datetime


def backup_file(filepath):
    """Create a backup of a file before modifying it."""
    backup_path = f"{filepath}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    shutil.copy2(filepath, backup_path)
    print(f"  Backup created: {backup_path}")
    return backup_path


def patch_build_system_build(filepath, dry_run=False):
    """Add x86_64 config settings to build-system/BUILD"""
    print(f"\n[1/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'ios_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    # New content to add
    new_config_settings = '''
config_setting(
	name = "ios_sim_arm64",
	values = {"cpu": "ios_sim_arm64"},
)

config_setting(
	name = "ios_sim_x86_64",
	values = {"cpu": "ios_x86_64"},
)

config_setting(
	name = "ios_x86_64",
	values = {"cpu": "ios_x86_64"},
)

exports_files([
    "GenerateStrings/GenerateStrings.py",
])
'''
    
    if dry_run:
        print("  [DRY RUN] Would replace entire file with x86_64 config settings")
        return True
    
    backup_file(filepath)
    
    with open(filepath, 'w') as f:
        f.write(new_config_settings)
    
    print("  Successfully added ios_sim_x86_64 and ios_x86_64 config settings")
    return True


def patch_webrtc_build(filepath, dry_run=False):
    """Patch third-party/webrtc/BUILD to support x86_64"""
    print(f"\n[2/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'ios_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    if dry_run:
        print("  [DRY RUN] Would add x86_64 support to arch_specific_sources and arch_specific_cflags")
        return True
    
    backup_file(filepath)
    
    # Add x86_64_specific_sources definition before arch_specific_sources
    old_arch_specific_sources = '''arch_specific_sources = select({
    "@build_bazel_rules_apple//apple:ios_arm64": common_arm_specific_sources + arm64_specific_sources,
    "//build-system:ios_sim_arm64": common_arm_specific_sources + arm64_specific_sources,
})'''
    
    new_arch_specific_sources = '''# x86_64 uses generic C implementations instead of NEON
x86_64_specific_sources = ["webrtc/" + path for path in [
    "common_audio/signal_processing/complex_bit_reverse.c",
    "common_audio/signal_processing/filter_ar_fast_q12.c",
]]

arch_specific_sources = select({
    "@build_bazel_rules_apple//apple:ios_arm64": common_arm_specific_sources + arm64_specific_sources,
    "//build-system:ios_sim_arm64": common_arm_specific_sources + arm64_specific_sources,
    "//build-system:ios_sim_x86_64": x86_64_specific_sources,
    "//build-system:ios_x86_64": x86_64_specific_sources,
    "//conditions:default": x86_64_specific_sources,
})'''
    
    content = content.replace(old_arch_specific_sources, new_arch_specific_sources)
    
    # Add x86_64_specific_flags and update arch_specific_cflags
    old_arch_specific_cflags = '''arch_specific_cflags = select({
    "@build_bazel_rules_apple//apple:ios_arm64": common_flags + arm64_specific_flags,
    "//build-system:ios_sim_arm64": common_flags + arm64_specific_flags,
})'''
    
    new_arch_specific_cflags = '''x86_64_specific_flags = [
    "-DWEBRTC_ARCH_X86_64",
    "-DWEBRTC_ARCH_X86_FAMILY",
]

arch_specific_cflags = select({
    "@build_bazel_rules_apple//apple:ios_arm64": common_flags + arm64_specific_flags,
    "//build-system:ios_sim_arm64": common_flags + arm64_specific_flags,
    "//build-system:ios_sim_x86_64": common_flags + x86_64_specific_flags,
    "//build-system:ios_x86_64": common_flags + x86_64_specific_flags,
    "//conditions:default": common_flags + x86_64_specific_flags,
})'''
    
    content = content.replace(old_arch_specific_cflags, new_arch_specific_cflags)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("  Successfully added x86_64 support")
    return True


def patch_libyuv_build(filepath, dry_run=False):
    """Patch third-party/libyuv/BUILD to support x86_64"""
    print(f"\n[3/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'ios_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    if dry_run:
        print("  [DRY RUN] Would add x86_64 support to select() statements")
        return True
    
    backup_file(filepath)
    
    # Find and patch the arch_specific_cflags select statement
    # Pattern: select with ios_sim_arm64 for cflags
    pattern = r'(arch_specific_cflags\s*=\s*select\(\{[^}]*"//build-system:ios_sim_arm64":\s*common_flags\s*\+\s*arm64_specific_flags,)(\s*\}\))'
    
    replacement = r'''\1
    "//build-system:ios_sim_x86_64": common_flags,
    "//build-system:ios_x86_64": common_flags,
    "//conditions:default": common_flags,
\2'''
    
    content = re.sub(pattern, replacement, content)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("  Successfully added x86_64 support")
    return True


def patch_openh264_build(filepath, dry_run=False):
    """Patch third-party/openh264/BUILD to support x86_64"""
    print(f"\n[4/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'ios_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    if dry_run:
        print("  [DRY RUN] Would add x86_64 support to select() statements")
        return True
    
    backup_file(filepath)
    
    # Patch arm64_specific_sources select
    content = re.sub(
        r'("//build-system:ios_sim_arm64":\s*arm64_specific_sources,)(\s*\}\))',
        r'''\1
    "//build-system:ios_sim_x86_64": [],
    "//build-system:ios_x86_64": [],
    "//conditions:default": [],
\2''',
        content
    )
    
    # Patch arm64_specific_copts select
    content = re.sub(
        r'("//build-system:ios_sim_arm64":\s*arm64_specific_copts,)(\s*\}\))',
        r'''\1
    "//build-system:ios_sim_x86_64": [],
    "//build-system:ios_x86_64": [],
    "//conditions:default": [],
\2''',
        content
    )
    
    # Patch arm64_specific_textual_hdrs select
    content = re.sub(
        r'("//build-system:ios_sim_arm64":\s*arm64_specific_textual_hdrs,)(\s*\}\))',
        r'''\1
    "//build-system:ios_sim_x86_64": [],
    "//build-system:ios_x86_64": [],
    "//conditions:default": [],
\2''',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("  Successfully added x86_64 support")
    return True


def patch_libsrtp_build(filepath, dry_run=False):
    """Patch third-party/webrtc/libsrtp/BUILD to support x86_64"""
    print(f"\n[5/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'ios_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    if dry_run:
        print("  [DRY RUN] Would add x86_64 support to select() statements")
        return True
    
    backup_file(filepath)
    
    # Patch the select statement
    content = re.sub(
        r'("//build-system:ios_sim_arm64":\s*common_flags\s*\+\s*arm64_specific_flags,)(\s*\}\))',
        r'''\1
    "//build-system:ios_sim_x86_64": common_flags,
    "//build-system:ios_x86_64": common_flags,
    "//conditions:default": common_flags,
\2''',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("  Successfully added x86_64 support")
    return True


def patch_crc32c_build(filepath, dry_run=False):
    """Patch third-party/webrtc/crc32c/BUILD to support x86_64"""
    print(f"\n[6/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'ios_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    if dry_run:
        print("  [DRY RUN] Would add x86_64 support to select() statements")
        return True
    
    backup_file(filepath)
    
    # Add x86_64 conditions with default/empty values
    # This handles the select statements in crc32c BUILD
    content = re.sub(
        r'("//build-system:ios_sim_arm64":\s*\[[^\]]*\],)(\s*\}\))',
        r'''\1
    "//build-system:ios_sim_x86_64": [],
    "//build-system:ios_x86_64": [],
    "//conditions:default": [],
\2''',
        content
    )
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("  Successfully added x86_64 support")
    return True


def patch_make_py(filepath, dry_run=False):
    """Add debug_sim_x86_64 and release_sim_x86_64 configurations to Make.py"""
    print(f"\n[7/8] Patching {filepath}")
    
    if not os.path.exists(filepath):
        print(f"  ERROR: File not found: {filepath}")
        return False
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Check if already patched
    if 'debug_sim_x86_64' in content:
        print("  Already patched, skipping.")
        return True
    
    if dry_run:
        print("  [DRY RUN] Would add debug_sim_x86_64 and release_sim_x86_64 configurations")
        return True
    
    backup_file(filepath)
    
    # Add new configuration options in set_configuration method
    old_release_arm64 = """        elif configuration == 'release_arm64':
            self.configuration_args = [
                # bazel optimized build configuration
                '-c', 'opt',

                # Build single-architecture binaries. It is almost 2 times faster is 32-bit support is not required.
                '--ios_multi_cpus=arm64',

                # Always build universal Watch binaries.
                '--watchos_cpus=arm64_32',

                # Generate DSYM files when building.
                '--apple_generate_dsym',

                # Require DSYM files as build output.
                '--output_groups=+dsyms',
            ] + self.common_release_args
        else:
            raise Exception('Unknown configuration {}'.format(configuration))"""
    
    new_configurations = """        elif configuration == 'release_arm64':
            self.configuration_args = [
                # bazel optimized build configuration
                '-c', 'opt',

                # Build single-architecture binaries. It is almost 2 times faster is 32-bit support is not required.
                '--ios_multi_cpus=arm64',

                # Always build universal Watch binaries.
                '--watchos_cpus=arm64_32',

                # Generate DSYM files when building.
                '--apple_generate_dsym',

                # Require DSYM files as build output.
                '--output_groups=+dsyms',
            ] + self.common_release_args
        elif configuration == 'debug_sim_x86_64':
            self.configuration_args = [
                # bazel debug build configuration
                '-c', 'dbg',

                # Build for x86_64 simulator (Intel Macs)
                '--ios_multi_cpus=x86_64',

                # Always build universal Watch binaries.
                '--watchos_cpus=arm64_32'
            ] + self.common_debug_args
        elif configuration == 'release_sim_x86_64':
            self.configuration_args = [
                # bazel optimized build configuration
                '-c', 'opt',

                # Build for x86_64 simulator (Intel Macs)
                '--ios_multi_cpus=x86_64',

                # Always build universal Watch binaries.
                '--watchos_cpus=arm64_32'
            ] + self.common_release_args
        else:
            raise Exception('Unknown configuration {}'.format(configuration))"""
    
    content = content.replace(old_release_arm64, new_configurations)
    
    # Add new choices to argument parser for build command
    old_choices = """        choices=[
            'debug_arm64',
            'debug_sim_arm64',
            'release_sim_arm64',
            'release_arm64',
        ],
        required=True,
        help='Build configuration'"""
    
    new_choices = """        choices=[
            'debug_arm64',
            'debug_sim_arm64',
            'release_sim_arm64',
            'release_arm64',
            'debug_sim_x86_64',
            'release_sim_x86_64',
        ],
        required=True,
        help='Build configuration'"""
    
    content = content.replace(old_choices, new_choices)
    
    with open(filepath, 'w') as f:
        f.write(content)
    
    print("  Successfully added debug_sim_x86_64 and release_sim_x86_64 configurations")
    return True


def patch_genrule_build_files(dry_run=False):
    """Patch BUILD files that use shell script genrules with TARGET_CPU checks"""
    print(f"\n[8/8] Patching genrule BUILD files (ffmpeg, opus, libvpx, etc.)")
    
    genrule_files = [
        'submodules/ffmpeg/BUILD',
        'third-party/opus/BUILD',
        'third-party/libjxl/BUILD',
        'third-party/webp/BUILD',
        'third-party/td/BUILD',
        'third-party/libvpx/BUILD',
        'third-party/dav1d/BUILD',
        'third-party/mozjpeg/BUILD',
    ]
    
    patched_count = 0
    
    for filepath in genrule_files:
        if not os.path.exists(filepath):
            print(f"  WARNING: File not found: {filepath}")
            continue
        
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Check if already patched
        if 'ios_x86_64' in content:
            print(f"  {filepath}: Already patched, skipping.")
            continue
        
        if dry_run:
            print(f"  [DRY RUN] Would patch {filepath}")
            patched_count += 1
            continue
        
        backup_file(filepath)
        
        # Add x86_64 handling after ios_sim_arm64 checks
        # Pattern: elif [ "$(TARGET_CPU)" == "ios_sim_arm64" ]; then
        # We need to add: elif [ "$(TARGET_CPU)" == "ios_x86_64" ]; then
        
        # This is a complex pattern - we need to add x86_64 support
        # The exact changes depend on the file structure
        
        # For most files, we can add a simple elif clause
        # We'll look for the ios_sim_arm64 block and add ios_x86_64 with similar config
        
        modified = False
        
        # Try to find and patch ios_sim_arm64 blocks
        if 'elif [ "$(TARGET_CPU)" == "ios_sim_arm64" ]; then' in content:
            # Find the pattern and the following block
            lines = content.split('\n')
            new_lines = []
            i = 0
            while i < len(lines):
                new_lines.append(lines[i])
                
                # Check if this line contains ios_sim_arm64 check
                if 'elif [ "$(TARGET_CPU)" == "ios_sim_arm64" ]; then' in lines[i]:
                    # Collect the block until fi or else/elif
                    block_lines = []
                    i += 1
                    indent = ''
                    while i < len(lines):
                        line = lines[i]
                        # Detect end of block
                        if line.strip().startswith('elif ') or line.strip().startswith('else') or line.strip() == 'fi':
                            break
                        block_lines.append(line)
                        if not indent and line.strip():
                            indent = line[:len(line) - len(line.lstrip())]
                        new_lines.append(line)
                        i += 1
                    
                    # Add x86_64 block (copy of sim_arm64 block with x86_64 config)
                    # Note: x86_64 usually needs different arch flags
                    x86_block = []
                    x86_block.append(indent + 'elif [ "$(TARGET_CPU)" == "ios_x86_64" ]; then')
                    for bl in block_lines:
                        # Replace arm64/aarch64 with x86_64 where appropriate
                        modified_line = bl
                        modified_line = modified_line.replace('aarch64', 'x86_64')
                        modified_line = modified_line.replace('arm64', 'x86_64')
                        # Keep sim in the path if it was there
                        x86_block.append(modified_line)
                    
                    new_lines.extend(x86_block)
                    modified = True
                    continue
                
                i += 1
            
            if modified:
                content = '\n'.join(new_lines)
        
        with open(filepath, 'w') as f:
            f.write(content)
        
        if modified:
            print(f"  {filepath}: Successfully patched")
            patched_count += 1
        else:
            print(f"  {filepath}: No changes needed or pattern not found")
    
    return patched_count > 0


def main():
    parser = argparse.ArgumentParser(
        description='Add Intel x86_64 support to Telegram-iOS project',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be changed without making modifications'
    )
    parser.add_argument(
        '--skip-genrules',
        action='store_true',
        help='Skip patching genrule BUILD files (ffmpeg, opus, etc.)'
    )
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Telegram-iOS Intel x86_64 Support Patch")
    print("=" * 60)
    
    if args.dry_run:
        print("\n*** DRY RUN MODE - No files will be modified ***\n")
    
    # Check if we're in the right directory
    if not os.path.exists('build-system/BUILD'):
        print("ERROR: This script must be run from the Telegram-iOS root directory.")
        print("       Could not find build-system/BUILD")
        sys.exit(1)
    
    success = True
    
    # Patch all files
    success &= patch_build_system_build('build-system/BUILD', args.dry_run)
    success &= patch_webrtc_build('third-party/webrtc/BUILD', args.dry_run)
    success &= patch_libyuv_build('third-party/libyuv/BUILD', args.dry_run)
    success &= patch_openh264_build('third-party/openh264/BUILD', args.dry_run)
    success &= patch_libsrtp_build('third-party/webrtc/libsrtp/BUILD', args.dry_run)
    success &= patch_crc32c_build('third-party/webrtc/crc32c/BUILD', args.dry_run)
    success &= patch_make_py('build-system/Make/Make.py', args.dry_run)
    
    if not args.skip_genrules:
        patch_genrule_build_files(args.dry_run)
    
    print("\n" + "=" * 60)
    
    if args.dry_run:
        print("DRY RUN COMPLETE - No files were modified")
        print("\nRun without --dry-run to apply changes.")
    elif success:
        print("PATCHING COMPLETE!")
        print("\nNext steps:")
        print("1. Run the generateProject command with x86_64 support:")
        print("")
        print("   python3 build-system/Make/Make.py \\")
        print("       --cacheDir=\"$HOME/telegram-bazel-cache\" \\")
        print("       generateProject \\")
        print("       --configurationPath=build-system/template_minimal_development_configuration.json \\")
        print("       --xcodeManagedCodesigning")
        print("")
        print("2. Or build directly for x86_64 simulator:")
        print("")
        print("   python3 build-system/Make/Make.py \\")
        print("       --cacheDir=\"$HOME/telegram-bazel-cache\" \\")
        print("       build \\")
        print("       --configurationPath=build-system/template_minimal_development_configuration.json \\")
        print("       --xcodeManagedCodesigning \\")
        print("       --buildNumber=10000 \\")
        print("       --configuration=debug_sim_x86_64")
        print("")
        print("Note: Backup files were created with .backup.* extension")
    else:
        print("PATCHING COMPLETED WITH ERRORS")
        print("Please check the output above for details.")
    
    print("=" * 60)


if __name__ == '__main__':
    main()
