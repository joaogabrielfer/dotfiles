package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/joaogabriel/dot/config"
	"github.com/joaogabriel/dot/installer"
	"github.com/spf13/cobra"
)

var dotDir string

var rootCmd = &cobra.Command{
	Use:   "dot",
	Short: "Dotfiles manager",
	CompletionOptions: cobra.CompletionOptions{
		DisableDefaultCmd: true,
	},
}

func init() {
	home, _ := os.UserHomeDir()
	dotDir = filepath.Join(home, "dotfiles")

	rootCmd.AddCommand(installCmd)
	rootCmd.AddCommand(targetsCmd)
	rootCmd.AddCommand(updateCmd)
	rootCmd.AddCommand(pushCmd)
	rootCmd.AddCommand(addLinkCmd)
	rootCmd.AddCommand(addPkgCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(targetsCmd)
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func loadConfig() *config.DotfilesConfig {
	cfgPath := filepath.Join(dotDir, "dotfiles.yaml")
	cfg, err := config.LoadConfig(cfgPath)
	if err != nil {
		fmt.Printf("\033[31mERROR:\033[0m loading config: %v\n", err)
		os.Exit(1)
	}
	return cfg
}

var installCmd = &cobra.Command{
	Use:   "install [target]",
	Short: "Install the desired configuration for the target",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		cfg := loadConfig()
		target := args[0]

		current := config.GetCurrentTarget()
		if current != "" && current != target {
			fmt.Printf("\033[33mWARNING:\033[0m Installation detected for %s.\n", current)
		}

		if err := installer.Install(cfg, target, dotDir); err != nil {
			fmt.Printf("\033[31mERROR:\033[0m %v\n", err)
			os.Exit(1)
		}
		fmt.Println("\033[32mDone!\033[0m")
	},
}

var targetsCmd = &cobra.Command{
	Use:   "targets",
	Short: "List all available target configurations",
	Run: func(cmd *cobra.Command, args []string) {
		cfg := loadConfig()
		fmt.Println("Targets:")
		for name := range cfg.Targets {
			fmt.Printf("    \033[34m%s\033[0m\n", name)
		}
	},
}

var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Fetch the latest changes and updates the local environment",
	Run: func(cmd *cobra.Command, args []string) {
		target := config.GetCurrentTarget()
		if target == "" {
			fmt.Println("\033[31mERROR:\033[0m Installation not detected. Please install first.")
			os.Exit(1)
		}

		fmt.Println("\033[32mDownloading latest changes...\033[0m")
		gitCmd := exec.Command("git", "pull", "origin", "main")
		gitCmd.Dir = dotDir
		gitCmd.Stdout = os.Stdout
		gitCmd.Stderr = os.Stderr
		if err := gitCmd.Run(); err != nil {
			fmt.Printf("\033[31mERROR:\033[0m git pull failed: %v\n", err)
			os.Exit(1)
		}

		cfg := loadConfig()
		if err := installer.Install(cfg, target, dotDir); err != nil {
			fmt.Printf("\033[31mERROR:\033[0m %v\n", err)
			os.Exit(1)
		}
		fmt.Println("\033[32mDone!\033[0m")
	},
}

var pushCmd = &cobra.Command{
	Use:   "push",
	Short: "Push the current config into the remote repository",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("\033[32mStaging local changes...\033[0m")
		exec.Command("git", "-C", dotDir, "add", ".").Run()

		statusCmd := exec.Command("git", "-C", dotDir, "status")
		statusCmd.Stdout = os.Stdout
		statusCmd.Run()

		fmt.Print("\nInsert commit message:\n\033[32m>> \033[0m")
		reader := bufio.NewReader(os.Stdin)
		msg, _ := reader.ReadString('\n')
		msg = strings.TrimSpace(msg)

		if msg == "" {
			fmt.Println("\033[31mERROR:\033[0m No commit message provided. Aborting.")
			os.Exit(1)
		}

		exec.Command("git", "-C", dotDir, "commit", "-m", msg).Run()
		exec.Command("git", "-C", dotDir, "push", "origin", "main").Run()
		fmt.Println("\n\033[32mRepository updated successfully!\033[0m")
	},
}

var addLinkCmd = &cobra.Command{
	Use:   "add-link [target] [name] [path]",
	Short: "Add a link to the desired target in the config",
	Args:  cobra.RangeArgs(2, 3),
	Run: func(cmd *cobra.Command, args []string) {
		targetName := args[0]
		name := args[1]
		
		var destPath string
		if len(args) == 3 {
			destPath = filepath.Join(args[2], name)
		} else {
			destPath = filepath.Join("~/.config", name)
		}

		cfgPath := filepath.Join(dotDir, "dotfiles.yaml")
		cfg := loadConfig()

		target, ok := cfg.Targets[targetName]
		if !ok {
			fmt.Printf("\033[31mERROR:\033[0m target %s not found\n", targetName)
			os.Exit(1)
		}

		if target.Links == nil {
			target.Links = make(map[string]string)
		}

		srcPath := filepath.Join(targetName, name)
		if targetName == "shared" {
			srcPath = filepath.Join("shared", name)
		}

		target.Links[srcPath] = destPath
		cfg.Targets[targetName] = target

		if err := config.SaveConfig(cfgPath, cfg); err != nil {
			fmt.Printf("\033[31mERROR:\033[0m failed to save config: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("\033[32mAdded link %s -> %s to %s\033[0m\n", destPath, srcPath, targetName)
	},
}

var addPkgCmd = &cobra.Command{
	Use:   "add-pkg [target] [name]",
	Short: "Add a package to the target installation script",
	Args:  cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		targetName := args[0]
		pkgName := args[1]

		cfgPath := filepath.Join(dotDir, "dotfiles.yaml")
		cfg := loadConfig()

		target, ok := cfg.Targets[targetName]
		if !ok {
			fmt.Printf("\033[31mERROR:\033[0m target %s not found\n", targetName)
			os.Exit(1)
		}

		if target.Packages == nil {
			target.Packages = make(map[string][]string)
		}
		
		target.Packages["paru"] = append(target.Packages["paru"], pkgName)
		cfg.Targets[targetName] = target

		if err := config.SaveConfig(cfgPath, cfg); err != nil {
			fmt.Printf("\033[31mERROR:\033[0m failed to save config: %v\n", err)
			os.Exit(1)
		}
		fmt.Printf("\033[32mAdded %s to %s\033[0m\n", pkgName, targetName)
	},
}

