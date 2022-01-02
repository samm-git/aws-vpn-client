package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"

	"github.com/rs/zerolog/log"
)

type (
	openVPNConfig struct {
		Filename  string
		Host      string
		Protocol  string
		Port      int
		Formatted bool
	}
)

func parseAndFormatOpenVPNConfig(inFilename, outDir string, clientConfig *config) (config *openVPNConfig, err error) {
	fileBytes, err := ioutil.ReadFile(inFilename)

	if err != nil {
		return
	}

	config, err = parseOpenVPNConfig(fileBytes)

	if outDir != "" {
		config.Formatted = true
		err = formatAndSaveOpenVPNConfig(fileBytes, outDir, config, clientConfig)
	} else {
		config.Filename = inFilename
	}

	return
}

func parseOpenVPNConfig(fileBytes []byte) (config *openVPNConfig, err error) {
	sliceData := strings.Split(string(fileBytes), "\n")

	if len(sliceData) == 0 {
		return nil, fmt.Errorf("empty file")
	}

	config = &openVPNConfig{}

	for _, line := range sliceData {
		tokens := strings.Split(line, " ")

		if len(tokens) == 0 {
			continue
		}

		if strings.HasPrefix("#", tokens[0]) || strings.HasPrefix(";", tokens[0]) {
			continue
		}

		switch tokens[0] {
		case "remote":
			if len(tokens) != 3 {
				log.Fatal().Msg("Unexpected number of arguments for remote")
			}

			config.Host = tokens[1]

			p, err := strconv.ParseInt(tokens[2], 10, 64)

			if err != nil {
				log.Error().Err(err).Msg("Failed parsing port of remote! Defaulting to 443." + errorSuffix)
				p = 443
			}

			config.Port = int(p)

		case "proto":
			if len(tokens) != 2 {
				log.Fatal().Msg("Unexpected number of arguments for proto")
			}

			config.Protocol = tokens[1]
		}
	}

	return
}

func formatAndSaveOpenVPNConfig(fileBytes []byte, outDir string, config *openVPNConfig, clientConfig *config) (err error) {
	sliceData := strings.Split(string(fileBytes), "\n")

	if len(sliceData) == 0 {
		return fmt.Errorf("empty file")
	}

	f, err := os.CreateTemp(outDir, "*.openvpn")

	config.Filename = f.Name()

	if err != nil {
		return
	}

	defer f.Close()

	for _, line := range sliceData {
		line = strings.TrimSpace(line)

		if strings.HasPrefix(line, "auth-user-pass") ||
			strings.HasPrefix(line, "auth-federate") ||
			strings.HasPrefix(line, "auth-retry interact") ||
			strings.HasPrefix(line, "remote ") ||
			strings.HasPrefix(line, "remote-random-hostname") {
			continue
		}

		_, err = f.WriteString(line + "\n")

		if err != nil {
			return
		}
	}

	return
}

func saveOpenVPNAuthConfig(outDir, password string) (filename string, err error) {
	authFile, err := os.CreateTemp(outDir, "*.auth.openvpn")

	if err != nil {
		return
	}
	defer authFile.Close()

	filename = authFile.Name()
	authFile.WriteString("N/A\n" + password + "\n")

	return
}
