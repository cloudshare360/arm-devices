To resolve the issue where the script reports "no partitions found," the problem is likely that some NVMe devices may not have partitions, or their partitions are not being correctly detected. We can enhance the script to handle NVMe drives with and without partitions more reliably.

Here’s an updated version of the script that checks for both whole NVMe devices and their partitions. If no partitions are found, the script will test the speed directly on the NVMe device itself.

### Updated Script to Handle NVMe Drives and Partitions

```bash
#!/bin/bash

# Function to test NVMe speed using dd
test_nvme_speed() {
    DEVICE_PATH=$1
    MOUNT_POINT=$2

    # Ensure the mount point exists
    sudo mkdir -p $MOUNT_POINT

    # Mount the partition if not mounted
    if ! grep -qs "$MOUNT_POINT" /proc/mounts; then
        sudo mount $DEVICE_PATH $MOUNT_POINT
    fi

    echo "Testing write speed on $DEVICE_PATH with dd..."
    WRITE_SPEED=$(sudo dd if=/dev/zero of=$MOUNT_POINT/testfile bs=1G count=1 oflag=direct 2>&1 | grep copied | awk '{print $(NF-1) " " $NF}')
    
    echo "Testing read speed on $DEVICE_PATH with dd..."
    READ_SPEED=$(sudo dd if=$MOUNT_POINT/testfile of=/dev/null bs=1G count=1 iflag=direct 2>&1 | grep copied | awk '{print $(NF-1) " " $NF}')

    # Cleanup the test file
    sudo rm $MOUNT_POINT/testfile

    # Unmount the device
    sudo umount $MOUNT_POINT

    # Display results in the console
    echo "Results for $DEVICE_PATH:"
    echo "Write Speed: $WRITE_SPEED"
    echo "Read Speed:  $READ_SPEED"

    # Append the results to the report file
    echo "Results for $DEVICE_PATH:" >> nvme_speed_report.txt
    echo "Write Speed: $WRITE_SPEED" >> nvme_speed_report.txt
    echo "Read Speed:  $READ_SPEED" >> nvme_speed_report.txt
    echo "--------------------------------------------" >> nvme_speed_report.txt
}

# Function to dynamically scan NVMe devices and test speeds
scan_and_test_nvme_devices() {
    echo "Scanning for NVMe devices..."
    
    # List NVMe devices and partitions
    NVME_DEVICES=$(lsblk -d -n -o NAME | grep nvme)

    if [[ -z "$NVME_DEVICES" ]]; then
        echo "No NVMe devices found!"
        exit 1
    fi

    echo "Found NVMe devices: $NVME_DEVICES"

    # Initialize report file
    echo "NVMe Speed Test Report" > nvme_speed_report.txt
    echo "======================" >> nvme_speed_report.txt

    # Loop over each NVMe device
    for NVME_DEVICE in $NVME_DEVICES; do
        DEVICE_PATH="/dev/$NVME_DEVICE"
        
        # Check for partitions under the NVMe device
        PARTITIONS=$(lsblk -n -o NAME "/dev/$NVME_DEVICE" | grep -v "$NVME_DEVICE")
        
        if [[ -z "$PARTITIONS" ]]; then
            # No partitions found, test the whole device
            MOUNT_POINT="/mnt/$NVME_DEVICE"
            echo "No partitions found for /dev/$NVME_DEVICE, testing the whole device..."
            test_nvme_speed $DEVICE_PATH $MOUNT_POINT
        else
            # Test each partition found
            for PARTITION in $PARTITIONS; do
                DEVICE_PATH="/dev/$PARTITION"
                MOUNT_POINT="/mnt/$PARTITION"
                echo "------------------------------------------"
                echo "Testing /dev/$PARTITION"
                echo "------------------------------------------"
                test_nvme_speed $DEVICE_PATH $MOUNT_POINT
            done
        fi
    done

    echo "NVMe speed report generated at nvme_speed_report.txt"
}

# Run the NVMe device scan and test
scan_and_test_nvme_devices
```

### Key Improvements:

1. **Whole Device Handling**: 
   - If no partitions are found for an NVMe device, the script now tests the speed of the entire device instead of skipping it.
   - The script will check if there are partitions under each NVMe device. If no partitions are found, it will test the whole device.
   
2. **Partitions Handling**:
   - If partitions are found for an NVMe device, it will test each partition individually.

### Steps to Run the Script:

1. **Create the Script**:
   ```bash
   nano nvme_speed_test.sh
   ```

2. **Paste the Script** into the file and save it by pressing `Ctrl + X`, then `Y`, and `Enter`.

3. **Make the Script Executable**:
   ```bash
   chmod +x nvme_speed_test.sh
   ```

4. **Run the Script**:
   ```bash
   sudo ./nvme_speed_test.sh
   ```

### Example Output:

```
Scanning for NVMe devices...
Found NVMe devices: nvme0n1 nvme1n1
No partitions found for /dev/nvme0n1, testing the whole device...
Testing write speed on /dev/nvme0n1 with dd...
Testing read speed on /dev/nvme0n1 with dd...
Results for /dev/nvme0n1:
Write Speed: 1.2 GB/s
Read Speed: 2.1 GB/s
------------------------------------------
Testing /dev/nvme1n1p1
------------------------------------------
Testing write speed on /dev/nvme1n1p1 with dd...
Testing read speed on /dev/nvme1n1p1 with dd...
Results for /dev/nvme1n1p1:
Write Speed: 1.3 GB/s
Read Speed: 2.2 GB/s
NVMe speed report generated at nvme_speed_report.txt
```

### Generated Report (`nvme_speed_report.txt`):

```
NVMe Speed Test Report
======================
Results for /dev/nvme0n1:
Write Speed: 1.2 GB/s
Read Speed: 2.1 GB/s
--------------------------------------------
Results for /dev/nvme1n1p1:
Write Speed: 1.3 GB/s
Read Speed: 2.2 GB/s
--------------------------------------------
```

### Key Points:

1. **Device and Partition Handling**:
   - The script handles NVMe devices with or without partitions. If no partitions are found, it will test the whole device directly.
   
2. **Dynamic Mount Points**:
   - The script creates dynamic mount points under `/mnt` based on the device or partition name.

3. **Console and File Output**:
   - The results are printed to the console and written to a report file (`nvme_speed_report.txt`).

This version of the script should resolve the issue of "no partitions found" by checking for both partitions and whole devices. Let me know if you encounter any other issues or need further adjustments!