package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {

	// Change the working directory to System32
	windir := os.Getenv("windir")
	system32Dir := windir + "\\System32"
	os.Chdir(system32Dir)

	// Set initial state for Render and Capture devices
	renderFound := false
	captureFound := false

	// Enumerate AudioEndpoint devices
	cmd := exec.Command("pnputil", "-enum-devices", "/connected", "/class", "AudioEndpoint")
	output, err := cmd.Output()
	if err != nil {
		fmt.Println("Error executing pnputil:", err)
		fmt.Println("Press any key to exit...")
		fmt.Scanln()
		return
	}

	// Process each line of the output
	lines := strings.Split(string(output), "\n")
	var id, description string

	for _, line := range lines {
		if strings.Contains(line, "Instance ID") {
			id = strings.Split(line, ":")[1]
			id = strings.TrimSpace(id)
			id = strings.TrimPrefix(id, "SWD\\MMDEVAPI\\")
		}
		if strings.Contains(line, "Device Description") {
			description = strings.Split(line, ":")[1]
			description = strings.TrimSpace(description)
		}
		if strings.Contains(line, "Class Name") {
			if description == "Speaker (Sound Blaster Recon3D)" {
				renderFound = true
				addRegistryEntry("Render", id)
			}
			if description == "Microphone (Sound Blaster Recon3D)" {
				captureFound = true
				addRegistryEntry("Capture", id)
			}
			description = ""
			id = ""
		}
	}

	// Check if the devices were found
	if !renderFound {
		fmt.Println("\nRecon3D speaker not detected!")
		fmt.Println("Press any key to exit...")
		fmt.Scanln()
		return
	}

	if !captureFound {
		fmt.Println("\nRecon3D microphone not detected!")
		fmt.Println("Press any key to exit...")
		fmt.Scanln()
		return
	}

	// Success message
	fmt.Println("Recon3D Control Panel Configured Successfully")
	fmt.Println("Press any key to exit...")
	fmt.Scanln()
}

// addRegistryEntry adds the registry entry for the device ID
func addRegistryEntry(key, value string) {
	cmd := exec.Command("reg", "add", "HKCU\\SOFTWARE\\Creative Tech\\Audio Endpoint Selection\\Sound Blaster Recon 3D Control Panel", "/v", key, "/t", "REG_SZ", "/d", value, "/f")
	err := cmd.Run()
	if err != nil {
		fmt.Println("Error adding registry entry:", err)
	}
}