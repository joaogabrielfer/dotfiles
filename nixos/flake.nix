{
  description = "NixOS Config";

  inputs = {
	nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }: {
    nixosConfigurations.nixpc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # Adicionado: necessário para flakes
      modules = [
        ./configuration.nix

        # Importa o módulo do home-manager
        home-manager.nixosModules.home-manager

        # Bloco de configuração do home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.jgfer = import ./home.nix;
        }
      ];
    };
  };
}
