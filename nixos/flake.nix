{
  description = "NixOS Config com Dotfiles Integrados";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Adicionando seu repositório de dotfiles aqui
    my-dotfiles = {
      url = "github:joaogabrielfer/dotfiles";
      flake = false; # Como é um repositório comum, tratamos como fonte de dados
    };
  };

  outputs = { self, nixpkgs, home-manager, my-dotfiles, ... }@inputs: {
    nixosConfigurations.nixpc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; # Passa os inputs (incluindo dotfiles) para os módulos
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.jgfer = import ./home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
