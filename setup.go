package main

import (
	"fmt"
	"os/exec"
	"runtime"

	"github.com/rs/zerolog/log"
	"github.com/urfave/cli/v2"
)

// setupAction Compiles and builds patched version of openvpn and verify we have everything we need before doing so.
// TODO: Download and patch and compile via Golang?
func setupAction(c *cli.Context) error {

	// TODO: Remove me when Windows has been fully supported and tested.
	if runtime.GOOS == "windows" {
		log.Fatal().Msg("Detected windows environment! This operation is not properly developed to execute for Windows. Please manually build openvpn using the provided ruby script." + errorSuffix)
	}

	// Make sure all required commands are installed on the system.
	// TODO: Add more commands to check?
	var quit bool
	if !commandExists("git") {
		log.Error().Msg("git not found! Please install git to continue." + errorSuffix)
		quit = true
	}

	if !commandExists("ruby") {
		log.Error().Msg("Ruby not found! Please install Ruby to continue." + errorSuffix)
		quit = true
	}

	if !commandExists("make") {
		log.Error().Msg("Make not found! Please install build-essentials or development tools to continue." + errorSuffix)
		quit = true
	}

	if quit {
		return fmt.Errorf("one or more commands not found")
	}

	log.Debug().Str("script", c.String("script")).Msg("executing ruby")

	out, err := exec.Command("ruby", c.String("script")).CombinedOutput()

	log.Info().Bytes("output", out).Err(err).Msg("ruby ran")

	if err == nil {
		log.Info().Msg("Successfully compiled openvpn! Please mv the compiled executable to a perfered location and make sure AWS_OPENVPN is set with the location!")
		return nil
	}

	return fmt.Errorf("failed executing ruby script %s. Pleae read logs for further information. "+errorSuffix, c.String("script"))
}
