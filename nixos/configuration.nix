{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Bootloader centralizado
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Entrada manual para o Arch Linux (baseado no seu fstab)
  boot.loader.systemd-boot.extraEntries = {
    "arch.conf" = ''
      title Arch Linux
      linux /vmlinuz-linux
      initrd /intel-ucode.img
      initrd /initramfs-linux.img
      options root=UUID=e6ca3a63-2d0e-44a2-9095-f5327acc7232 rw
    '';
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixpc";
  networking.networkmanager.enable = true; # Recomendado para desktop

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; 
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  users.users.jgfer = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    packages = with pkgs; [ tree ];
  };

  environment.systemPackages = with pkgs; [
    vim neovim wget git git-credential-oauth
    hyprpaper waybar ghostty kitty
    fastfetch rofi-wayland # pacotes que vi nos seus dotfiles
	where-is-my-sddm-theme
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.openssh.enable = true;

  system.stateVersion = "25.05"; # Use a versão estável atual ou 25.05 se for unstable
}
