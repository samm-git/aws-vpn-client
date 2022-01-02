package main

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path"
	"runtime"
	"strings"
)

func openDefaultBrowser(url string) (err error) {
	switch runtime.GOOS {
	case "linux":
		err = exec.Command("xdg-open", url).Start()
	case "windows":
		err = exec.Command("rundll32", "url.dll,FileProtocolHandler", url).Start()
	case "darwin":
		err = exec.Command("open", url).Start()
	default:
		err = fmt.Errorf("unsupported patform %s", runtime.GOOS)
	}

	return
}

func commandExists(command string) bool {
	cmd := exec.Command("/bin/sh", "-c", "command -v "+command)
	if err := cmd.Run(); err != nil {
		return false
	}
	return true
}

func fileExists(filename string) bool {
	if _, err := os.Stat(filename); err == nil {
		return true
	}

	return false
}

func getHomeDirConfigPath() (foldername string, err error) {
	home, err := os.UserHomeDir()

	if err != nil {
		return
	}

	configFolder := ".config"

	if runtime.GOOS == "windows" {
		configFolder = "AppData\\Local"
	}

	foldername = path.Join(home, configFolder, defaultConfigDirectoryName)

	return
}

func searchConfigFilename() (string, error) {

	wd, wdErr := os.Getwd()

	if wdErr != nil {
		return "", wdErr
	}

	configAtwd := path.Join(wd, defaultConfigFilename)

	home, _ := getHomeDirConfigPath()
	configAtHome := path.Join(home, defaultConfigFilename)

	if fileExists(configAtwd) {
		return configAtwd, nil
	} else if fileExists(configAtHome) {
		return configAtHome, nil
	}

	return "", os.ErrNotExist
}

func lookupIP(hostname string) (ip string, err error) {
	ips, err := net.LookupIP(hostname)

	if err != nil || len(ips) == 0 {
		return
	}

	for _, ipv4 := range ips {
		ip = ipv4.String()
		break
	}

	return
}

func generateRandomToken(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func extractSIDFromOpenVPN(output string) (SID string, err error) {
	tokens := strings.Split(output, ":")

	for _, t := range tokens {
		if strings.HasPrefix(t, "instance-") {
			SID = t
			break
		}
	}

	if SID == "" {
		err = fmt.Errorf("sid not found")
	}

	return
}
