{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "nixosV";

    i18n = {
  #   consoleFont = "Lat2-Terminus16";
      consoleKeyMap = "us";
      defaultLocale = "en_US.UTF-8";
    };

    time.timeZone = "Europe/Bratislava";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
    environment.systemPackages = with pkgs; [
      git
      wget
      vim
      screen
      nvi
      mkpasswd
      lftp
      git
      cabal2nix
      nix-prefetch-git
      cabal-install
    ];

    services.openssh.enable = true;
    services.openssh.permitRootLogin = "no";

    networking.firewall.enable = false;

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    users.extraUsers.kriloter = {
      isNormalUser = true;
      createHome = true;
      uid = 1000;
      group = "users";
      extraGroups = [ "wheel" ];
    };

    system.stateVersion = "19.03";

    containers.test1 = {
      privateNetwork = true;
      hostAddress = "172.30.107.51";
      localAddress = "172.30.107.52";
      config = { config, pkgs, ... }: {
        networking.firewall.enable = false;
        services.openssh.enable = true;
        services.openssh.permitRootLogin = "no";
        users.extraUsers.test = {
          isNormalUser = true;
          createHome = true;
          uid = 1005;
          group = "users";
        #  extraGroups = [ "wheel" ];
          hashedPassword = "$6$85dLBsbks1$oESOLhS5t7gowuRvUOj/UmyTVFRNws39ZGChbdbgJW0/FBOfXQUCKeb6kiTDMRaO7oi0TM0evfisNLzb85KbP1";
        };
      };
    };

}
