#!/bin/sh

# mkdmg.sh - creates a macOS disk image with a folder containing the app
# Original inspiration from Philip Weaver: http://www.informagen.com/JarBundler/DiskImage.html
# Rewritten, extended, and robustified by John Clark in 2025: https://github.com/inindev/adtpro

# cleanup function for errors
cleanup() {
    local disk_id="$1"
    local dmg_temp_file="$2"

    echo "Cleaning up due to error"
    if [ -n "$disk_id" ]; then
        echo "Ejecting disk: $disk_id"
        hdiutil eject "$disk_id" 2>/dev/null || hdiutil eject -force "$disk_id" 2>/dev/null || echo "Failed to eject disk"
    fi
    if [ -f "$dmg_temp_file" ]; then
        echo "Removing temporary DMG: $dmg_temp_file"
        rm "$dmg_temp_file" || echo "Failed to remove temporary DMG"
    fi
}

# setup dmg: create, attach, format, and eject
setup_dmg() {
    local dmg_temp_file="$1"
    local vol_name="$2"
    local dmg_mb="$3"

    echo "Creating temporary DMG: $dmg_temp_file"
    hdiutil create -megabytes "$dmg_mb" "$dmg_temp_file" -layout NONE || {
        echo "Failed to create DMG"
        exit 1
    }

    echo "Attaching DMG to get disk identifier"
    disk_id=$(hdiutil attach -nomount -readwrite -noverify "$dmg_temp_file" | grep '^/dev/' | awk '{print $1}' | head -n 1)
    if [ -z "$disk_id" ]; then
        echo "Error: Failed to get disk identifier"
        exit 1
    fi
    echo "Disk identifier: $disk_id"

    echo "Formatting DMG with HFS+"
    newfs_hfs -v "$vol_name" "$disk_id" || {
        echo "Failed to format DMG"
        exit 1
    }

    echo "Ejecting DMG"
    hdiutil eject "$disk_id" || {
        echo "Failed to eject DMG"
        exit 1
    }
    disk_id=''
}

# populate dmg: mount, create folder, copy resources, set icons, and configure finder
populate_dmg() {
    local dmg_temp_file="$1"
    local vol_name="$2"
    local src_file="$3"
    local src_icon="$4"
    local dmg_icon="$5"
    local dmg_back="$6"

    echo "Mounting DMG"
    disk_id=$(hdid "$dmg_temp_file" | grep '^/dev/' | awk '{print $1}' | head -n 1)
    if [ -z "$disk_id" ]; then
        echo "Error: Failed to get disk identifier for mount"
        exit 1
    fi
    echo "Mounted disk identifier: $disk_id"

    echo "Copying application and resources"
    chflags -R nouchg,noschg "$src_file"
    cp -R "$src_file" "/Volumes/$vol_name" || {
        echo "Failed to copy src file: $src_file"
        exit 1
    }
    local src_file_name="$(basename "$src_file")"
    set_file_icon "/Volumes/$vol_name/$src_file_name" "$src_icon"

    mkdir "/Volumes/$vol_name/.background"

    cp "$dmg_icon" "/Volumes/$vol_name/.VolumeIcon.icns" || {
        echo "Failed to copy dmg icon: $dmg_icon"
        exit 1
    }
    cp "$dmg_back" "/Volumes/$vol_name/.background/background.png" || {
        echo "Failed to copy background image: $dmg_back"
        exit 1
    }

    SetFile -c icns "/Volumes/$vol_name/.VolumeIcon.icns" || {
        echo "Failed to set icon type"
        exit 1
    }
    SetFile -a C "/Volumes/$vol_name" || {
        echo "Failed to set custom icon attribute"
        exit 1
    }

    rm -rf "/Volumes/$vol_name/.Trashes" "/Volumes/$vol_name/.fseventsd"

    echo "Configuring Finder appearance"
    osascript <<-EOF
	tell application "Finder"
	    tell disk "$vol_name"
	        open
	        set current view of container window to icon view
	        set toolbar visible of container window to false
	        set statusbar visible of container window to false
	        set the bounds of container window to {400, 100, 775, 305}
	        set theViewOptions to the icon view options of container window
	        set arrangement of theViewOptions to not arranged
	        set icon size of theViewOptions to 72
	        set background picture of theViewOptions to file ".background:background.png"
	        make new alias file at container window to POSIX file "/Applications" with properties {name:"Applications"}
	        set position of item "$src_file_name" of container window to {83, 101}
	        set position of item "Applications" of container window to {274, 101}
	        update without registering applications
	        close
	        open
	        delay 5
	    end tell
	end tell
	EOF

    if [ $? -ne 0 ]; then
        echo "Failed to configure Finder"
        exit 1
    fi
}

# finalize dmg: eject, convert, rename, and set icon
finalize_dmg() {
    local dmg_temp_file="$1"
    local dmg_file="$2"
    local dmg_icon="$3"

    echo "Ejecting final DMG"
    hdiutil eject "$disk_id" || {
        echo "Failed to eject final DMG"
        exit 1
    }
    disk_id=''

    echo "Converting DMG to final format"
    rm -f "$dmg_file"
    hdiutil convert -format UDCO "$dmg_temp_file" -o "$dmg_file" || {
        echo "Failed to convert DMG"
        exit 1
    }
    rm -f "$dmg_temp_file" || {
        echo "Failed to remove temporary DMG"
        exit 1
    }

    echo "Setting DMG icon"
    set_file_icon "$dmg_file" "$dmg_icon"
}

# set file icon using an .icns file
set_file_icon() {
    local file="$1"
    local icon="$2"

    if [ -z "$file" ] || [ -z "$icon" ]; then
        echo "Error: File and icon file must be specified" >&2
        exit 2
    fi

    if [ ! -e "$file" ] || [ ! -r "$file" ] || [ ! -w "$file" ]; then
        echo "Error: File or folder not found or not accessible: $file" >&2
        exit 1
    fi
    if [ ! -f "$icon" ] || [ ! -r "$icon" ]; then
        echo "Error: Icon file not found or not readable: $icon" >&2
        exit 1
    fi

    osascript <<-EOF >/dev/null
	use framework "Cocoa"
	set sourcePath to "$icon"
	set destPath to "$file"
	set imageData to (current application's NSImage's alloc()'s initWithContentsOfFile:sourcePath)
	(current application's NSWorkspace's sharedWorkspace()'s setIcon:imageData forFile:destPath options:2)
	EOF

    if [ $? -ne 0 ]; then
        echo "Error: Failed to set icon" >&2
        exit 1
    fi

    echo "Custom icon set for $file using $icon"
}

main() {
    local src_file="$1"
    local src_icon="$2"
    local dmg_file="$3"
    local dmg_icon="$4"
    local dmg_back="$5"
    local vol_name="$6"
    local dmg_mb="${7:-64}"

    local dmg_temp_file="${dmg_file%.dmg}_temp.dmg"
    local disk_id=''

    # validate inputs
    if [ $# -lt 6 ]; then
        echo "Usage: $0 <src_file> <src_icon> <dmg_file> <dmg_icon> <dmg_back> <vol_name> [dmg_mb]" >&2
        exit 2
    fi

    # set trap for cleanup
    trap 'if [ $? -ne 0 ]; then cleanup "$disk_id" "$dmg_temp_file"; fi' EXIT

    setup_dmg "$dmg_temp_file" "$vol_name" "$dmg_mb"
    populate_dmg "$dmg_temp_file" "$vol_name" "$src_file" "$src_icon" "$dmg_icon" "$dmg_back"
    finalize_dmg "$dmg_temp_file" "$dmg_file" "$dmg_icon"

    echo "DMG creation completed: $dmg_file"
}

main "$@"
