package main

import (
	"io/ioutil"

	"gopkg.in/yaml.v2"
)

type (
	vpn struct {
		Port      int
		OpenVPN   string
		Sudo      string
		Shell     string
		ShellArgs []string
	}

	server struct {
		Addr string
	}

	config struct {
		Vpn    vpn
		Server server
	}
)

func loadConfig(filename string) (c *config, err error) {
	fileBytes, err := ioutil.ReadFile(filename)

	if err != nil {
		return
	}

	c = &config{}
	err = yaml.Unmarshal(fileBytes, c)

	return
}
