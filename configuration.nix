{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

#    networking.hostName = "nixosV";
    networking = {
      hostName = "nixosV";
      interfaces.eth0.ipv4 = {
        addresses = [{
          address = "172.30.107.53";
          prefixLength = 28;
        }];
      };
      defaultGateway = {
        address = "172.30.107.49";
        interface = "eth0";
      };
      nameservers = [ "172.30.107.49" ];
    };

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
      cabal2nix
      nix-prefetch-git
      cabal-install
      tcp_wrappers
      pam_pgsql
      libgcrypt
      mod_fastcgi
    ];

    services.openssh.enable = true;
    services.openssh.permitRootLogin = "no";

    networking.firewall = {
      enable = false;
#      allowedTCPPorts = [ 80 ];
    };
   
/*
    networking.nat.enable = true;
    networking.nat.internalInterfaces = ["ve-test1" "ve-nginx1"];
    networking.nat.externalInterface = "eth0";
*/

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

    users.extraUsers.vsftpuser = {
      isNormalUser = true;
      createHome = true;
      uid = 1010;
      group = "users";
      shell = pkgs.nologin;
    };

    system.stateVersion = "19.03";

    services.httpd = {
      enable = true;
      adminAddr = "kriloter@kriloter.com";
      documentRoot = "/var/www";
      extraModules = [
        "proxy_fcgi"
      ];
      extraConfig = ''
        <Directory /var/www> 
          Options FollowSymlinks
          DirectoryIndex index.php
          AllowOverride All 
        </Directory>
        <FilesMatch "\.php$">
            SetHandler "proxy:fcgi://127.0.0.1/:8000"
        </FilesMatch>
      '';
    };

    services.phpfpm.poolConfigs.mypool = ''
      listen = 127.0.0.1:8000
      user = wwwrun
      group = wwwrun
      pm = dynamic
      pm.max_children = 5
      pm.start_servers = 2
      pm.min_spare_servers = 1
      pm.max_spare_servers = 3
      pm.max_requests = 500
    '';


/*
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
*/

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql96;
      authentication = pkgs.lib.mkForce ''
        local vsftp dbuser         md5
        local all all              ident
        host  all all 127.0.0.1/32 md5
        host  all all ::1/128      md5
      '';
    };

    security.pam.services.vsftpd = {
      name = "vsftpd";
      logFailures = true;
      text = ''
        auth      required  ${pkgs.pam_pgsql}/lib/security/pam_pgsql.so  config_file=/etc/pam_pgsql_vsftpd.conf
        account	  required  ${pkgs.pam_pgsql}/lib/security/pam_pgsql.so  config_file=/etc/pam_pgsql_vsftpd.conf
#        session   required  pam_mkhomedir.so  umask=0022
      '';
    };
#    security.pam.services.vsftpd.makeHomeDir = true;

    services.vsftpd = {
      enable = true;
      anonymousUser = false;
      anonymousUserNoPassword = false;
      anonymousUploadEnable = false;
      anonymousMkdirEnable = false;
      chrootlocalUser = true;
      userlistEnable = false;
      userlistDeny = false;
      forceLocalLoginsSSL = false;
      forceLocalDataSSL = false;
      portPromiscuous = false;
      localUsers = true;
      writeEnable = true;
      ssl_tlsv1 = true;
      ssl_sslv2 = false;
      ssl_sslv3 = false;
      extraConfig = ''
        pam_service_name=vsftpd
        guest_enable=YES
        guest_username=vsftpuser
        local_root=/home/vsftpuser/$USER
        user_sub_token=$USER
        virtual_use_local_privs=YES
        allow_writeable_chroot=YES
        hide_ids=YES
        connect_from_port_20=YES
      '';
    };




/*
    containers.test1 = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "172.30.107.51";
      localAddress = "192.168.123.51";
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

    containers.mariadb1 = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "172.30.107.51";
      localAddress = "192.168.123.50";
      config = { config, pkgs, ... }: {
        networking.firewall.enable = false;
        services.mysql = {
          enable = true;
          package = pkgs.mariadb;
        };
      };
    };

    containers.nginx1 = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "172.30.107.51";
      localAddress = "192.168.123.52";
      config = { config, pkgs, ... }: {
        networking.firewall.enable = false;
        services.nginx = {
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
        #  appendHttpConfig = "server_names_hash_bucket_size 64;";
          enable = true;
        };
        services.phpfpm.poolConfigs.mypool = ''
        listen = 127.0.0.1:9000
        user = nginx
        group = nginx
        pm = dynamic
        pm.max_children = 5
        pm.start_servers = 2 
        pm.min_spare_servers = 1 
        pm.max_spare_servers = 3
        pm.max_requests = 500
        '';
      };
    };

    containers.apache1 = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "172.30.107.51";
      localAddress = "192.168.123.53";
      config = { config, pkgs, ... }: {
        networking.firewall.enable = false;
        services.httpd = {
          enable = true;
          user = "wwwtest";
          group = "wwwtest";
          adminAddr = "kriloter@kriloter.com";
#          documentRoot = "/var/www";
        };
      };
    };
*/

}
