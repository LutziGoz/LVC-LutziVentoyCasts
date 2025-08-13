#!/bin/bash

ISO_MAY_2025_URL="https://store-eu-par-4.gofile.io/download/web/cdab9278-a09d-40ed-9d3e-d08dcbe4fb21/en-us_windows_11_business_editions_version_24h2_updated_may_2025_x64_dvd_3bdfe428.iso"
ISO_MAY_2025="en-us_windows_11_business_editions_version_24h2_updated_may_2025_x64_dvd_3bdfe428.iso"

ISO_ARCHIVE_URL="https://archive.org/download/en-us_windows_11_business_editions_version_22h2_updated_nov_2022_x64_dvd_7ed4b518/en-us_windows_11_business_editions_version_22h2_updated_nov_2022_x64_dvd_7ed4b518.iso"
ISO_ARCHIVE="en-us_windows_11_business_editions_version_22h2_updated_nov_2022_x64_dvd_7ed4b518.iso"

VENTOY_URL="https://github.com/ventoy/Ventoy/releases/download/v1.0.99/ventoy-1.0.99-linux.tar.gz"
VENTOY_DIR="ventoy-1.0.99"
BASE_DIR=$(pwd)

function select_usb() {
    while true; do
        USB_DEVS=$(lsblk -d -o NAME,TRAN | grep usb | awk '{print $1}')
        if [ -z "$USB_DEVS" ]; then
            echo "No USB drives detected. Connect one and press ENTER."
            read
        else
            echo "Available USB drives:"
            select USB_DEV in $USB_DEVS; do
                if [ -n "$USB_DEV" ]; then
                    echo "Selected: /dev/$USB_DEV"
                    break 2
                else
                    echo "Invalid selection. Try again."
                fi
            done
        fi
    done
}

function check_ventoy() {
    sudo blkid "/dev/${USB_DEV}1" | grep -qi ventoy
    return $?
}

clear
echo "===== Windows USB Creator ====="
echo "1) Download Windows 11 ISO (May 2025 - Recommended)"
echo "2) Manual download (files.rg-adguard.net)"
echo "3) Download Windows 11 ISO (Archive.org Nov 2022)"
read -p "Choose an option [1/2/3]: " iso_choice

case $iso_choice in
1)
    ISO_URL=$ISO_MAY_2025_URL
    ISO_NAME=$ISO_MAY_2025
    ;;
2)
    xdg-open "https://files.rg-adguard.net/category"
    echo "Download your ISO manually and place it here."
    read -p "Press ENTER after placing your ISO..."

    ISO_FILES=($(ls *.iso *.img 2>/dev/null))
    if [ ${#ISO_FILES[@]} -eq 0 ]; then
        echo "No ISO or IMG files found. Exiting."
        exit 1
    fi

    echo "Available ISO files:"
    select ISO_NAME in "${ISO_FILES[@]}"; do
        [ -n "$ISO_NAME" ] && break
        echo "Invalid selection."
    done
    ;;
3)
    ISO_URL=$ISO_ARCHIVE_URL
    ISO_NAME=$ISO_ARCHIVE
    ;;
*)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

if [ "$iso_choice" != "2" ]; then
    if [ -f "$ISO_NAME" ]; then
        echo "ISO '$ISO_NAME' already exists."
        read -p "Download again? (y/n): " redownload
        [ "$redownload" == "y" ] && rm -f "$ISO_NAME"
    fi
    [ ! -f "$ISO_NAME" ] && wget -O "$ISO_NAME" "$ISO_URL"
fi

select_usb

echo "Burn method:"
echo "1) UEFI (Ventoy - GPT)"
echo "2) Legacy (Ventoy - MBR)"
read -p "Choose method [1/2]: " burn_choice

if ! [ -d "$VENTOY_DIR" ]; then
    wget "$VENTOY_URL"
    tar -xzf "$(basename $VENTOY_URL)"
fi

if check_ventoy; then
    read -p "Ventoy found. Copy ISO without formatting? (y/n): " copy_no_format
    if [ "$copy_no_format" == "y" ]; then
        sudo mkdir -p /mnt/ventoy
        sudo mount "/dev/${USB_DEV}1" /mnt/ventoy
        sudo cp "$BASE_DIR/$ISO_NAME" /mnt/ventoy/
        sync && sudo umount /mnt/ventoy
        echo "ISO copied without formatting."
        exit 0
    fi
fi

read -p "Proceed to format and install Ventoy? (y/n): " erase_confirm
[ "$erase_confirm" != "y" ] && { echo "Cancelled."; exit 1; }

sudo umount "/dev/${USB_DEV}"* 2>/dev/null
cd "$VENTOY_DIR"

if [ "$burn_choice" == "1" ]; then
    sudo ./Ventoy2Disk.sh -i -g /dev/$USB_DEV
else
    sudo ./Ventoy2Disk.sh -i /dev/$USB_DEV
fi

cd "$BASE_DIR"
sudo mkdir -p /mnt/ventoy
sudo mount "/dev/${USB_DEV}1" /mnt/ventoy
sudo cp "$BASE_DIR/$ISO_NAME" /mnt/ventoy/
sync && sudo umount /mnt/ventoy

echo "✅ Ventoy installation complete!"

