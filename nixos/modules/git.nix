{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "João Gabriel";
    userEmail = "joaoggabriel07@gmail.com";
    extraConfig = {
      credential = {
        "https://github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
        "https://gist.github.com".helper = "!${pkgs.gh}/bin/gh auth git-credential";
      };
      advice = {
        defaultBranchName = false;
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = false;
      };
    };
  };

  home.packages = [ pkgs.gh ];
}