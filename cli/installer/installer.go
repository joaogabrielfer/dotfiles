package installer

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/joaogabriel/dot/config"
)

func ResolveTarget(cfg *config.DotfilesConfig, targetName string) (*config.Target, error) {
	target, ok := cfg.Targets[targetName]
	if !ok {
		return nil, fmt.Errorf("target %s not found", targetName)
	}

	merged := &config.Target{
		Packages: make(map[string][]string),
		Links:    make(map[string]string),
	}

	for _, inherit := range target.Inherits {
		inheritedTarget, err := ResolveTarget(cfg, inherit)
		if err != nil {
			return nil, err
		}
		mergeTargets(merged, inheritedTarget)
	}

	mergeTargets(merged, &target)
	return merged, nil
}

func mergeTargets(dst, src *config.Target) {
	for mgr, pkgs := range src.Packages {
		dst.Packages[mgr] = append(dst.Packages[mgr], pkgs...)
	}
	for srcPath, dstPath := range src.Links {
		dst.Links[srcPath] = dstPath
	}
}

func Install(cfg *config.DotfilesConfig, targetName string, dotDir string) error {
	fmt.Printf("\033[32mInstalling target: %s\033[0m\n", targetName)
	target, err := ResolveTarget(cfg, targetName)
	if err != nil {
		return err
	}

	if len(target.Packages["paru"]) > 0 {
		fmt.Println("\033[32mInstalling packages...\033[0m")
		args := append([]string{"-S", "--needed", "--noconfirm"}, target.Packages["paru"]...)
		cmd := exec.Command("paru", args...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to install packages: %w", err)
		}
	}

	fmt.Println("\033[32mCreating symlinks...\033[0m")
	for src, dst := range target.Links {
		srcPath := filepath.Join(dotDir, src)
		dstPath := config.ExpandPath(dst)

		os.MkdirAll(filepath.Dir(dstPath), 0755)
		os.RemoveAll(dstPath)

		fmt.Printf("Linking %s -> %s\n", dstPath, srcPath)
		if err := os.Symlink(srcPath, dstPath); err != nil {
			return fmt.Errorf("failed to symlink %s: %w", srcPath, err)
		}
	}

	return config.SetCurrentTarget(targetName)
}
