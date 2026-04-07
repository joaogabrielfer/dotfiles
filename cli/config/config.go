package config

import (
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

type Target struct {
	Inherits []string            `yaml:"inherits,omitempty"`
	Packages map[string][]string `yaml:"packages,omitempty"`
	Links    map[string]string   `yaml:"links,omitempty"`
}

type DotfilesConfig struct {
	Targets map[string]Target `yaml:"targets"`
}

func LoadConfig(path string) (*DotfilesConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var cfg DotfilesConfig
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

func SaveConfig(path string, cfg *DotfilesConfig) error {
	data, err := yaml.Marshal(cfg)
	if err != nil {
		return err
	}
	return os.WriteFile(path, data, 0644)
}

func ExpandPath(p string) string {
	if strings.HasPrefix(p, "~/") {
		home, _ := os.UserHomeDir()
		return filepath.Join(home, p[2:])
	}
	if strings.HasPrefix(p, "$HOME/") {
		home, _ := os.UserHomeDir()
		return filepath.Join(home, p[6:])
	}
	return os.ExpandEnv(p)
}

func GetStateDir() string {
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".local", "state", "dot")
}

func GetStateFile() string {
	return filepath.Join(GetStateDir(), "installed_target")
}

func GetCurrentTarget() string {
	data, err := os.ReadFile(GetStateFile())
	if err != nil {
		return ""
	}
	lines := strings.Split(string(data), "\n")
	for _, line := range lines {
		if strings.HasPrefix(line, "installed_target=") {
			return strings.TrimPrefix(line, "installed_target=")
		}
	}
	return ""
}

func SetCurrentTarget(target string) error {
	os.MkdirAll(GetStateDir(), 0755)
	return os.WriteFile(GetStateFile(), []byte("installed_target="+target+"\n"), 0644)
}
