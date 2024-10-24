#!/bin/sh

check_prerequisites() {
    if [ "$(id -u)" = 0 ]; then
        echo "Please do not run this script as root, run it as the user you'll use to play the game"
        exit 1
    elif ! [ "$(command -v xdelta3)" ]; then
        echo "xdelta3 not found. Please install it."
        exit 1
    elif ! [ -f gta-sa.exe ]; then 
        echo "Please unpack and run this script in the same directory as your San Andreas installation"
        exit 1
    elif [ -f gta_sa.exe ]; then
        echo "This game has already been converted, exiting."
        exit 0
    fi
}

patch_files() { # Reads the files from the TXT file and uses xdelta3 to patch them one by one 
    echo "Patching files..."
    while read -r file; do
        mv "$file" "$file.old"
        xdelta3 -d -f -s "$file.old" "files/xdeltafiles/${file}.xdelta" "${file}"
        rm -f "${file}.old"
    done < files/files_to_patch.txt 
}

delete_files() {
    echo "Deleting files that aren't on 1.0"
    sleep 2
    while read -r file; do
        if [ -f "${file}" ]; then
            rm "${file}" 1> /dev/null
        fi
    done < files/files_to_delete.txt
}

copy_exe() {
    echo "Copying the NoCD EXE"
    sleep 2
    cp -r files/gta_sa.exe "$(pwd)"
}

test_files() { # Calculates the MD5 hash and compares them to the table, making sure they've been converted properly
    echo "Testing files..."
    incorrectFiles=0
    while IFS=',' read -r expectedHash filePath; do
        expectedHash=$(echo "$expectedHash" | xargs)
        filePath=$(echo "$filePath" | xargs)

        if [ -e "$filePath" ]; then
            actualHash=$(md5sum "$filePath" | awk '{print $1}')

            if [ "$expectedHash" != "$actualHash" ]; then
                echo "Incorrect file: $filePath"
                incorrectFiles=$((incorrectFiles+1))
            fi
        fi
    done < "files/files_to_check.txt"

    if ! [ $incorrectFiles = 0 ]; then
        echo "Number of incorrect files: $incorrectFiles"
        echo "Please verify the integrity of your game on Steam and try again"
    else
        echo "Conversion successful!"
    fi
}

main() {
    clear
    printf "\nWelcome to the GTA: San Andreas - Steam to 1.0 downgrader - Linux edition"
    printf "\nThis converts everything in such a way that your new copy will be identical to the 1.0 copy (with a No-CD EXE)."
    printf "\nPlease make sure to unpack and run this script in the same directory as your San Andreas installation"
    printf "\nPress enter to continue"

    read -r nothing

    check_prerequisites
    patch_files
    delete_files
    copy_exe
    test_files
}

main

