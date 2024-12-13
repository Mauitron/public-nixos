{ config, lib, pkgs, ... }:
#0[System-Variables]
let
  username = "username"; # Set your username here
  git_username = "git username"; # Set your username here
  userEmail = "youremail@example.com";  # Set your email here
  timezone = "Region/City";  # Set your timezone here

zjstatus-plugin = pkgs.stdenv.mkDerivation {
    name = "zjstatus";
    version = "0.19.1";  
    
    src = pkgs.fetchurl {
     url = "https://github.com/dj95/zjstatus/releases/download/v0.19.1/zjstatus.wasm";
      sha256 = "sha256-6Hv9mGqoTIsMOcaHu/VjSBDX3ygy1T0ydptbeWGnXsw=";  
    };

    zjframes = pkgs.fetchurl {
      url = "https://github.com/dj95/zjstatus/releases/download/v0.19.1/zjframes.wasm";
      sha256 = "sha256-SBFAvvHukP/NkjMNAKvuHs7ltehOvWBYQp1GHbEUWtU=";  
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/share/zellij/plugins
      cp $src $out/share/zellij/plugins/zjstatus.wasm
      cp $zjframes $out/share/zellij/plugins/zjframes.wasm
      chmod 644 $out/share/zellij/plugins/*.wasm
    '';

    meta = with pkgs.lib; {
      description = "A configurable status bar plugin for Zellij";
      homepage = "https://github.com/dj95/zjstatus";
      license = licenses.mit;
      platforms = platforms.all;
    };
};

breezex-cursor = pkgs.stdenv.mkDerivation {
    name = "breezex-cursor";
    version = "2.0.0";
    
    src = pkgs.fetchurl {
      url = "https://github.com/ful1e5/BreezeX_Cursor/releases/download/v2.0.0/BreezeX-Black.tar.gz";
      sha256 = "sha256-v3eROieWwuNugO+o4xN52xnJFjEjQuVaZkrGlhwoZW4=";
    };

    unpackPhase = ''
      tar xf $src
    '';

    installPhase = ''
      mkdir -p $out/share/icons
      cp -r BreezeX-Black $out/share/icons/
    '';
};
  

  rose-pine-hyprcursor = pkgs.stdenv.mkDerivation {
    name = "rose-pine-hyprcursor";
    version = "1.0.0";
    
    src = pkgs.fetchFromGitHub {
      owner = "ndom91";
      repo = "rose-pine-hyprcursor";
      rev = "89dc9e347ce8da26766ad421b0899536f9f87639";  
      sha256 = "sha256-FdO+2X7TeIAW73hiyFKZbCjlAskb4xMmYYPX97mo9RE=";
    };

    installPhase = ''
      mkdir -p $out/share/icons/rose-pine-hyprcursor
      cp -r * $out/share/icons/rose-pine-hyprcursor/
    '';
  };
#0>[Hardware-Variables]
 hasNvidia = builtins.pathExists "/sys/module/nvidia";
  hasAmd = builtins.pathExists "/sys/class/drm/amdgpu";
  hasIntel = builtins.pathExists "/sys/class/drm/i915";
 isLaptop = builtins.pathExists "/sys/class/power_supply/BAT0" || 
            builtins.pathExists "/sys/class/power_supply/BAT1";  
  activeGpu = 
    if hasNvidia then "nvidia"
    else if hasAmd then "amd"
    else if hasIntel then "intel"
    else "generic";


 cpuInfo = builtins.readFile "/proc/cpuinfo";
  isMobileProcessor = builtins.match ".*model name.*[HU]K.*" cpuInfo != null;

#1[Software-Variables]
#1>[Cache-Config]
  cacheDir = "/var/lib/minimize-state";
  tempCacheDir = "/tmp";
  cacheFile = "${cacheDir}/windows.json";
  tempCacheFile = "${tempCacheDir}/minimized_windows.json";
  previewDir = "${tempCacheDir}/window-previews";

#1>[Preview-Settings]
  padded_width = "10";
  previewWidth = "200";
  previewHeight = "150";
  previewPadding = "5";
  previewBgColor = "#2e3440";

 
#1>[Command-Paths]
  hyprctlCmd = "${pkgs.hyprland}/bin/hyprctl";
  convertCmd = "${pkgs.imagemagick}/bin/convert";
  grimCmd = "${pkgs.grim}/bin/grim";
  jqCmd = "${pkgs.jq}/bin/jq";
  

in
{
#2[Core-Configuration]
  imports = [ ./hardware-configuration.nix ];
   
  ###########################################
  #  Boot Configuration
  ###########################################
#2>[Kernel-Paramenters]
 boot = {
  kernelParams = [

  # Base parameters for all systems
    "initcall_blacklist=simpledrm_platform_driver_init"
    "numlock=1"
    "mitigations=off"
    "preempt=voluntary"
    "clocksource=tsc"
    "tsc=reliable"
    "boot.shell_on_fail"
    
    # Memory management for all systems
    "hugepagesz=2M"
    "hugepages=4"
    "page_alloc.shuffle=1"
    
    # Scheduler optimizations
    "scheduler=bore"
    "bore.snapshot_time=24000000"
    "bore.latency_nice=3"

 ] ++ (if isLaptop && hasIntel then [
    # Laptop-specific Intel parameters
    "intel_pstate=active"
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
    "i915.fastboot=1"
    "i915.enable_dc=2"           # Display power saving
    "intel_idle.max_cstate=4"    # CPU power states
    "pcie_aspm=force"            # PCIe power management
    "pcie_port_pm=force"         # PCIe port power management
    "ahci.mobile_lpm_policy=1"   # SATA power management
    # Only add NVIDIA blacklist if specifically wanting to disable it
    "modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset"
  ] else if hasIntel then [
   # Intel-specific parameters
    "intel_pstate=active"
    "intel_iommu=on"
  "rcupdate.rcu_normal_after_boot=1"
  "skew_tick=1"
    
    "i915.enable_fbc=1"
    "i915.enable_psr=2"
    "i915.fastboot=1"
] else if hasAmd then [
    # AMD-specific parameters
    "amd_pstate=active"
    "amd_prefetch=1"
    "amd_iommu=on"
    "iommu=pt"
    "amdgpu.ppfeaturemask=0xffffffff"
    "amdgpu.asyncdma=1"
    "amdgpu.gpu_recovery=1"
    "radeon.si_support=0"
    "radeon.cik_support=0"
    "amdgpu.si_support=1"
    "amdgpu.cik_support=1"
] else []) ++ lib.optionals hasNvidia [
    # NVIDIA-specific parameters
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_UsePageAttributeTable=1"
    "nvidia.NVreg_EnablePCIeGen3=1"
    "nvidia.NVreg_DynamicPowerManagement=0x02"
  
  #   # Optimizations for all GPUs
  #   "mitigations=off"
  #   "scheduler=bore"
  #   "bore.snapshot_time=24000000"
  #   "bore.latency_nice=3"
  #   "clocksource=tsc"
  #   "tsc=reliable"
  #   "boot.shell_on_fail"
    
  #   # CPU Specific
  #   "amd_pstate=active"
  #   "amd_prefetch=1"
  #   "amd_iommu=on"
  #   "iommu=pt"
    
  #   # Memory management
  #   "hugepagesz=2M"
  #   "hugepages=4"
  #   "page_alloc.shuffle=1"
  #   "numlock=1"
  # ] ++ (if hasNvidia then [
  #   "nvidia-drm.modeset=1"
  #   "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  # ] else if hasAmd then [
  #   "amdgpu.ppfeaturemask=0xffffffff"
  #   "amdgpu.asyncdma=1"
  #   "amdgpu.gpu_recovery=1"
  #   "radeon.si_support=0"
  #   "radeon.cik_support=0"
  #   "amdgpu.si_support=1"
  #   "amdgpu.cik_support=1"
  # ] else if hasIntel then [
  #   "i915.enable_fbc=1"
  #   "i915.enable_psr=2"
  #   "i915.fastboot=1"
  #   "intel_pstate=active"
  #   "intel_iommu=on"
  # ] else []);

 ];
        kernel.sysctl = {
   "kernel.perf_event_paranoid" = -1;
   "kernel.panic" = 10;
   "kernel.panic_on_oops" = 1;
  "kernel.sched_min_granularity_ns" = 10000000;  # 10ms
  "kernel.sched_wakeup_granularity_ns" = 15000000;  # 15ms
  "kernel.sched_migration_cost_ns" = 5000000;    # 5ms
  
  "vm.dirty_background_ratio" = 45;
  "vm.dirty_ratio" = 80;
  "vm.dirty_expire_centisecs" = 18000;
  "vm.dirty_writeback_centisecs" = 12000;
 "kernel.nmi_watchdog" = 0;           # Disable NMI watchdog
    "vm.laptop_mode" = 5;        
  "vm.vfs_cache_pressure" = 50;
    # CPU optimization 
    "kernel.sched_autogroup_enabled" = 1;
    "kernel.sched_cfs_bandwidth_slice_us" = 500;
    "kernel.sched_child_runs_first" = 0;            
      
    # System hardening
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    "kernel.kexec_load_disabled" = 1;
    "kernel.sysrq" = 0;
      
    #    "kernel.nmi_watchdog" = 0;
    #    "vm.swappiness" = 1;                           
    #    "vm.dirty_background_ratio" = 20;              
    #    "vm.dirty_ratio" = 30;                         
    #    "vm.dirty_writeback_centisecs" = 3000;         
    #     "vm.page-cluster" = 0;                         
    #    "vm.vfs_cache_pressure" = 50;                  
    #    "vm.min_free_kbytes" = 1048576;               

    #    # shared memory limit
    #    "kernel.shmmax" = 34359738368;                
    #    "kernel.shmall" = 8388608;       
    #    "vm.compact_unevictable_allowed" = 0;
    #    "vm.stat_interval" = 10;
      
    #   # File system optimization
    #   "fs.file-max" = 2097152;
    #   "fs.inotify.max_user_watches" = 524288;
    #   "vm.max_map_count" = 2147483642;
    #   "fs.aio-max-nr" = 1048576;
      
      # Network optimization 
      "net.core.rmem_max" = 4194304;                
      "net.core.wmem_max" = 4194304;                
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_low_latency" = 1;
      "net.core.netdev_max_backlog" = 32768;
      "net.ipv4.tcp_window_scaling" = 1;
    };
    
       
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 25;
        editor = true;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
      timeout = 1;                                  
     };
  };    
    boot.tmp = {
  useTmpfs = true;
  tmpfsSize = "55%";
  cleanOnBoot = false;
};
#2>[Power Settings]
  powerManagement.cpuFreqGovernor = "powersave";
  services.thermald.enable = true;
services.udev.extraRules = ''
  ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
  
  ACTION=="add", SUBSYSTEM=="i2c", ATTR{power/control}="auto"
  
  ACTION=="add", SUBSYSTEM=="scsi_host", ATTR{link_power_management_policy}="med_power_with_dipm"
  
  ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
  
  ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="auto"
  
  ACTION=="add", SUBSYSTEM=="nvme", ATTR{power/control}="auto"
  
  ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="auto"
'';

services.tlp = {
  enable = true;
  settings = {
    RUNTIME_PM_ON_AC = "auto";
    RUNTIME_PM_ON_BAT = "auto";
    
    PCIE_ASPM_ON_AC = "performance";
    PCIE_ASPM_ON_BAT = "powersupersave";
    
    AHCI_RUNTIME_PM_ON_AC = "auto";
    AHCI_RUNTIME_PM_ON_BAT = "auto";
    
    INTEL_GPU_MAX_FREQ_ON_AC = "100";
    INTEL_GPU_MAX_FREQ_ON_BAT = "75";
    INTEL_GPU_MIN_FREQ_ON_AC = "25";
    INTEL_GPU_MIN_FREQ_ON_BAT = "25";
    
    USB_AUTOSUSPEND = 1;
    USB_BLACKLIST_BTUSB = 1;  # Don't suspend Bluetooth
    
    WIFI_PWR_ON_AC = "off";
    WIFI_PWR_ON_BAT = "on";
  };
};
#2>[File Systems]
  fileSystems = {
    "/home/${username}/.librewolf" = {
      device = "/nix/persist/home/${username}/.librewolf";
      options = [ "bind" ];
    };
    "/home/${username}/.config/libreoffice" = {
    device = "/nix/persist/home/${username}/.config/libreoffice";
    options = [ "bind" ];
    };
    "/" = {
      options = [ "noatime" "nodiratime" "commit=120" "lazytime" ];
    };
  };
fileSystems."/tmp" = {
  device = "tmpfs";
  fsType = "tmpfs";
  options = [ "size=8G" "mode=1777" "noatime" ];  
};

  ###########################################
  #  Networking
  ###########################################
# SSH Configuration
services.openssh = {
  enable = true;
  settings = {
    PasswordAuthentication = false;
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
  };

  extraConfig = ''
    PubkeyAuthentication yes
    AuthorizedKeysFile .ssh/authorized_keys
    
    # Security settings
    Protocol 2
    UsePrivilegeSeparation sandbox
    
    # Hardening
    HostKey /etc/ssh/ssh_host_ed25519_key
    HostKey /etc/ssh/ssh_host_rsa_key
    
    # Key exchange algorithms
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
    
    # Ciphers
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    
    # MAC algorithms
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
  '';
};
  programs.git = {
  enable = true;
  config = {
    user = {
      name = "${git_username}";  
      email = "${userEmail}"; 
    };
    init.defaultBranch = "main";
    url = {
      "ssh://git@github.com/".insteadOf = "https://github.com/";
    };
  };
};


  users.users.${username} = {
  createHome = true;
  home = "/home/${username}";
  group = "users";
   isNormalUser = true;
    description = "${username}";
    extraGroups = [ "networkmanager" "wheel" "video" "input" "storage" "plugdev" ];
    packages = with pkgs; [ kdePackages.kate ];

# for git integration add your SSH public keys here, remember to remove them if you are sharing the config.
openssh.authorizedKeys.keys = [];
    
  };

#3[Networking]
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    
    firewall = {
      enable = true;
      allowedTCPPorts = [ 80 443 22 ];
      allowedUDPPorts = [ 53 ];
      allowPing = true;
      logReversePathDrops = true;
      extraCommands = ''
        # Allow established connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        # Drop invalid packets
        iptables -A INPUT -m conntrack --ctstate INVALID -j DROP
        # Allow loopback
        iptables -A INPUT -i lo -j ACCEPT
        # Rate limit connections
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
        iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      '';
      extraStopCommands = ''
        iptables -D INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        iptables -D INPUT -m conntrack --ctstate INVALID -j DROP
        iptables -D INPUT -i lo -j ACCEPT
        iptables -D INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --set
        iptables -D INPUT -p tcp --dport 22 -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 4 -j DROP
      '';
    };
  };
  
  ###########################################
  #  Time and Localization
  ###########################################
#4[Time and Localization]

# if need be, you can automatically set your local timezone with:
# sudo timedatectl set-timezone "$(curl -s https://ipapi.co/timezone)"
services.automatic-timezoned = {
  enable = true;  
};
services.timesyncd = {
  enable = true;  
};
services.localtimed.enable = true;
services.geoclue2 = {
  enable = true;
  appConfig = {
    "org.freedesktop.Geoclue2.Agent" = {
      isAllowed = true;
      isSystem = true;
    };
    "org.freedesktop.timedate1" = {
      isAllowed = true;
      isSystem = true;
    };
    wlsunset = {
      isAllowed = true;
      isSystem = true;
    };
  };
};

i18n = {
  defaultLocale = "en_US.UTF-8";
  supportedLocales = [
    "en_US.UTF-8/UTF-8"  # English
    "es_ES.UTF-8/UTF-8"  # Spanish
    "ja_JP.UTF-8/UTF-8"  # Japanese
    "sv_SE.UTF-8/UTF-8"  # Swedish
    "de_DE.UTF-8/UTF-8"  # German
    "fr_FR.UTF-8/UTF-8"  # French
    "it_IT.UTF-8/UTF-8"  # Italian
    "ko_KR.UTF-8/UTF-8"  # Korean
    "zh_CN.UTF-8/UTF-8"  # Simplified Chinese
    "zh_TW.UTF-8/UTF-8"  # Traditional Chinese
  ];
};



  ###########################################
  # Display & Desktop Environments
  ###########################################
#5[Display & Desktop]
services = {
    xserver = {
      enable = true;
      dpi = 96;
      # videoDrivers = ["nvidia"];
      videoDrivers = if hasNvidia then ["nvidia"]
                    else if hasAmd then ["amdgpu"]
                    else if hasIntel then ["modesetting" "intel"]
                    else ["modesetting"];
      xkb = {
        layout = "us";
        variant = "";
      };
      
      deviceSection = if hasNvidia then ''
        Option "TripleBuffer" "1"
        Option "AllowIndirectGLXProtocol" "true"
        Option "NVreg_PreserveVideoMemoryAllocations" "1"
      '' else if hasAmd then ''
        Option "TearFree" "true"
        Option "DRI" "3"
        Option "AccelMethod" "glamor"
      '' else if hasIntel then ''
        Option "TearFree" "true"
        Option "DRI" "3"
        Option "AccelMethod" "glamor"
      '' else "";
      
#5>[Display-Manager]
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
    };
};

  console.useXkbConfig = true;
  programs.hyprland = {
    enable = true;
     xwayland = {
    enable = true;
  };
  };

  ###########################################
  #  Environment Variables
  ###########################################
#6[Environment Configuration]
  environment.variables = {
  COLORTERM = "truecolor";
  TERM = "xterm-256color";
 # Compilation & Development 
  MAKEFLAGS = "-j16";
  CFLAGS = "-march=znver4 -O3 -pipe";
  CXXFLAGS = "-march=znver4 -O3 -pipe";
  RUSTFLAGS = "-C target-cpu=native -C opt-level=3";
  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

       
  # System Paths 
  HELIX_RUNTIME = "${pkgs.helix}/share/helix/runtime";
  HELIX_CONFIG_DIR = "/etc/helix";
  ALACRITTY_CONFIG_PATH = "/etc/alacritty/alacritty.toml";
  TERMINAL = "alacritty";
  # Graphics 
    } // (if hasNvidia then {
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
   DISABLE_LAYER_AMD_SWITCHABLE_GRAPHICS_1 = "1";
    __GL_SHADER_DISK_CACHE_MAX_SIZE = "8589934592";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_BUFFER_SIZE = "262144";
    __GLX_GSYNC_ALLOWED = "0";
    __GL_RT_SHADER_MAX_RECURSION = "3";
  } else if hasAmd then {
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
    AMD_VULKAN_ICD = "RADV";
    AMD_DEBUG = "nodma";
    RADV_PERFTEST = "gpl,sam";
    AMDVLK_ENABLE_DEVELOPING_EXT = "all";
  } else if hasIntel then {
    LIBVA_DRIVER_NAME = "iHD";
    VDPAU_DRIVER = "va_gl";
    MESA_VK_DEVICE_SELECT = "Intel";
    INTEL_DEBUG = "perf";
    MESA_GL_VERSION_OVERRIDE = "4.5";
    MESA_GLSL_VERSION_OVERRIDE = "450";
  } else {});
     

  # };     
  environment.sessionVariables = {
  
  QT_QPA_PLATFORMTHEME = "qt5ct";
  QT_QPA_PLATFORM = "wayland;xcb";
  QT_STYLE_OVERRIDE = "kvantum";

       GDM_SESSION = "Hyprland";
       GDM_LANG = "en_US.UTF-8";
       NIXOS_OZONE_WL = "1";

       
 # XDG specifications
 XDG_DATA_DIRS = [ 
    "/etc/xdg"
    "/usr/share"
    "/usr/local/share"
    "/usr/share/gdm"
    "/usr/share/gnome"
    
  ];
 XCURSOR_THEME = "Breeze-X-Black";
 XCURSOR_SIZE = "24";
 HYPRCURSOR_THEME = "rose-pine-hyprcursor";
 HYPRCURSOR_SIZE = "24";
  XDG_TEMPLATES_DIR = "$HOME/Templates";
  XDG_DOCUMENTS_DIR = "$HOME/Documents";
  XDG_DOWNLOAD_DIR = "$HOME/Downloads";
  XDG_MUSIC_DIR = "$HOME/Music";
  XDG_PICTURES_DIR = "$HOME/Pictures";
  XDG_VIDEOS_DIR = "$HOME/Videos";
  XDG_RUNTIME_DIR = "/run/user/1000"; 
  XDG_CONFIG_HOME = "$HOME/.config";
  XDG_STATE_HOME = "$HOME/.local/state";
  XDG_CURRENT_DESKTOP = "Hyprland";
  XDG_SESSION_DESKTOP = "Hyprland";
  XDG_SESSION_TYPE = "wayland";
  CLUTTER_BACKEND = "wayland";

  HYPRLAND_CONFIG_FILE = "/etc/hypr/hyprland.conf";
  _JAVA_AWT_WM_NONREPARENTING = "1";
       
};
  ###########################################
  #  Activation Scripts For Configs
  ###########################################
#7[Activation Scripts For Configs]
#7>[Activation-Hyprland]
 system.activationScripts = {
 setup-hyprland-config = {
    text = ''
      # Create required directories
      mkdir -p /home/${username}/.config/hypr
      
      # Create the hyprland.conf file
      cat > /home/${username}/.config/hypr/hyprland.conf << 'EOL'

      ###################
      ### ENVIRONMENT ###
      ###################
      # Change this in hyprland.conf section:
      # env = STEAM_USE_WAYLAND,1
      # env = GDK_BACKEND,wayland
      # env = SDL_VIDEODRIVER,wayland
      # env = MOZ_ENABLE_WAYLAND,1
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Breeze-X-Black
env = HYPRCURSOR_THEME,rose-pine-hyprcursor
env = HYPRCURSOR_SIZE,24
      # These are render/display related, might help with font rendering, which is the current problem
      # env = GDK_SCALE,1
      # env = QT_AUTO_SCREEN_SCALE_FACTOR,1
      # env = QT_SCALE_FACTOR,1

      ################
      ### MONITORS ###
      ################
# First, disable all monitors
# monitor=,disable

# Set primary monitor

 monitor=HDMI-A-1,1920x1080@60,0x0,1
 monitor=eDP-1,1920x1080@60,0x0,1


# Mirror all others to HDMI-A-1 with same resolution
# monitor=HDMI-A-1,1920x1080@60,auto,1,mirror,eDP-1
monitor=eDP-1,1920x1080@60,auto,1,mirror,HDMI-A-1
monitor=DP-1,1920x1080@60,auto,1,mirror,HDMI-A-1
monitor=DP-2,1920x1080@60,auto,1,mirror,HDMI-A-1
monitor=DP-3,1920x1080@60,auto,1,mirror,HDMI-A-1
monitor=DP-4,1920x1080@60,auto,1,mirror,HDMI-A-1
monitor=DP-5,1920x1080@60,auto,1,mirror,HDMI-A-1
monitor=DP-6,1920x1080@60,auto,1,mirror,HDMI-A-1


   workspace=1,monitor:all
workspace=2,monitor:all
workspace=3,monitor:all
workspace=4,monitor:all
workspace=5,monitor:all
workspace=6,monitor:all
workspace=7,monitor:all
workspace=8,monitor:all
workspace=9,monitor:all
workspace=10,monitor:all

      #################
      ### VARIABLES ###
      #################
      $mainMod = SUPER
      $alt = ALT
      $term = alacritty
      $menu = wofi
      $browser = firefox
      $fileManager = pcmanfm
      $colorPicker = hyprpicker

      $screenshot = grim  # Add this
      $slurp = slurp     # Add this
      $clip = wl-copy    # Add this
      $notify = notify-send # Add this

      ##################
      ### INPUT CONF ###
      ##################
      input {
          kb_layout = us
          # kb_variant = dvorak
          repeat_rate = 65
          repeat_delay = 450
          follow_mouse = 0
          numlock_by_default = true
          touchpad {
              natural_scroll = true
              disable_while_typing = true
              scroll_factor = 1.0
              tap-to-click = true
          }
          sensitivity = 0
          accel_profile = flat
      }

      cursor {
        # no_break_fs_vrr = true
        enable_hyprcursor = true
        no_hardware_cursors = true
        hide_on_key_press = true
        inactive_timeout = 5
        # min_refresh_rate = 120
      }

      ######################
      ### GENERAL CONFIG ###
      ######################
      general {

          allow_tearing = false
    no_focus_fallback = true
          gaps_in = 2
          gaps_out = 5
          border_size = 2
          col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
          col.inactive_border = rgba(595959aa)
          layout = dwindle
          resize_on_border = true
          hover_icon_on_border = true
      }
      misc {
          animate_mouse_windowdragging = true
          animate_manual_resizes = true
          disable_hyprland_logo = true
          disable_splash_rendering = true
          mouse_move_enables_dpms = true
          key_press_enables_dpms = true
          enable_swallow = true
          swallow_regex = ^(alacritty)$
          focus_on_activate = true
          vfr = false
          vrr = true
          font_family = Fira Code Mono
      }

      #########################
      ### DECORATION CONFIG ###
      #########################
      decoration {
          rounding = 10
          active_opacity = 1.0
          inactive_opacity = 0.95

          shadow {
          range = 12
          offset = 3 3
          render_power = 4
          color = rgba(1a1a1aee)
          }

          blur {
              enabled = true
              size = 6
              passes = 3
              new_optimizations = true
              xray = true
              ignore_opacity = true
          }
      }

      ########################
      ### ANIMATION CONFIG ###
      ########################
      animations {
          enabled = true
          bezier = myBezier, 0.05, 0.9, 0.2, 1.00
          bezier = linear, 0.0, 0.0, 1.0, 1.0

          animation = windows, 1, 7, myBezier
          animation = windowsOut, 1, 7, default, popin 80%
          animation = border, 1, 10, default
          animation = fade, 1, 7, default
          animation = workspaces, 1, 6, default
          animation = specialWorkspace, 1, 6, myBezier, slidevert
      }

      ######################
      ### LAYOUT CONFIG ###
      ######################
      dwindle {
          pseudotile = true
          preserve_split = true
          force_split = 2
          smart_split = false
          smart_resizing = true
          permanent_direction_override = false
      }

      ################
      ### GESTURES ###
      ################
      gestures {
          workspace_swipe = true
          workspace_swipe_fingers = 3
          workspace_swipe_distance = 300
          workspace_swipe_invert = true
          workspace_swipe_min_speed_to_force = 30
          workspace_swipe_cancel_ratio = 0.5
      }

      ####################
      ### KEY BINDINGS ###
      ####################
      
      bind = $alt $mainMod, T, exec, $term
      bind = $alt CTRL, DEL, exit
      bind = $mainMod $alt, c, killactive
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod, P, pseudo
      bind = $mainMod, S, togglesplit
      bind = $mainMod, F, exec, $browser

      bind = $mainMod SHIFT, Q, exec, wlogout
      bind = $mainMod ALT, SPACE, togglefloating
      bind = $mainMod, P, pseudo

      # window nav (Vim-style)
      bind = $mainMod, H, workspace, r-1
      bind = $mainMod, L, workspace, r+1
            
      # Focus controls (Vim-style)
      bind = $mainMod $alt, H, movefocus, l
      bind = $mainMod $alt, L, movefocus, r
      bind = $mainMod $alt, K, movefocus, u
      bind = $mainMod $alt, J, movefocus, d

      # Move windows (Vim-style)
      bind = $mainMod SHIFT, H, movewindow, l
      bind = $mainMod SHIFT, L, movewindow, r
      bind = $mainMod SHIFT, K, movewindow, u
      bind = $mainMod SHIFT, J, movewindow, d

      # Resize windows (Vim-style)
      binde = $mainMod CTRL, H, resizeactive, -20 0
      binde = $mainMod CTRL, L, resizeactive, 20 0
      binde = $mainMod CTRL, K, resizeactive, 0 -20
      binde = $mainMod CTRL, J, resizeactive, 0 20

      # Move active window to workspace
      bind = $mainMod, 1, movetoworkspace, 1
      bind = $mainMod, 2, movetoworkspace, 2
      bind = $mainMod, 3, movetoworkspace, 3
      bind = $mainMod, 4, movetoworkspace, 4
      bind = $mainMod, 5, movetoworkspace, 5
      bind = $mainMod, 6, movetoworkspace, 6
      bind = $mainMod, 7, movetoworkspace, 7
      bind = $mainMod, 8, movetoworkspace, 8
      bind = $mainMod, 9, movetoworkspace, 9
      bind = $mainMod, 0, movetoworkspace, 10

      # Silent workspace switching
      bind = $mainMod ALT, 1, movetoworkspacesilent, 1
      bind = $mainMod ALT, 2, movetoworkspacesilent, 2
      bind = $mainMod ALT, 3, movetoworkspacesilent, 3
      bind = $mainMod ALT, 4, movetoworkspacesilent, 4
      bind = $mainMod ALT, 5, movetoworkspacesilent, 5

      # Mouse bindings
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1
      bindm = $mainMod, mouse:273, resizewindow
      bindm = $mainMod, mouse:272, movewindow

      # Media controls
      bind = , XF86AudioPlay, exec, playerctl play-pause
      bind = , XF86AudioNext, exec, playerctl next
      bind = , XF86AudioPrev, exec, playerctl previous
      bind = , XF86AudioStop, exec, playerctl stop

      # Volume
      binde = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
      binde = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

      # Screenshots
      bind = , Print, exec, $screenshot -g "$(slurp)" - | wl-copy
      bind = SHIFT, Print, exec, $screenshot -g "$(slurp)" ~/Pictures/screenshots/$(date +'%Y-%m-%d-%H%M%S_grim.png')
      bind = $mainMod, Print, exec, $screenshot -g "$(slurp)" - | swappy -f -

      bind = SUPER SHIFT, R, exec, /etc/record-gif.sh              # Start recording gif
      bind = SUPER SHIFT, S, exec, pkill -SIGINT wf-recorder       # Stop recording gif

      # Color picker
      bind = $mainMod SHIFT, C, exec, $colorPicker -a

      # Miscellaneous
      bind = $mainMod, SPACE, exec, /etc/wofi-toggle.sh drun
      bind = $mainMod, I, exec, /etc/wofi-toggle.sh minimize
      bind = $mainMod, M, exec, /etc/minimize-manager.sh minimize
      bind = , mouse:274, exec, /etc/right_click_menu.sh
      bind = ALT, RETURN, fullscreen, 0

      # Minimize manager workspaces
      workspace = special:minimize1
      workspace = special:minimize2
      workspace = special:minimize

      #################
      ### AUTOSTART ###
      #################
exec-once = dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita'"
exec-once = dconf write /org/gnome/desktop/interface/icon-theme "'Flat-Remix-Red-Dark'"
exec-once = dconf write /org/gnome/desktop/interface/document-font-name "'Noto Sans Medium 11'"
exec-once = dconf write /org/gnome/desktop/interface/font-name "'Noto Sans Medium 11'"
exec-once = dconf write /org/gnome/desktop/interface/monospace-font-name "'Noto Sans Mono Medium 11'"
      exec-once = waybar &
      exec-once = ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      exec-once = hyprpaper
      exec-once = nm-applet --indicator
      exec-once = blueman-applet
      exec-once = wlsunset -T 6500 -t 6500
      exec-once = /usr/lib/polkit-kde-authentication-agent-1
      exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = /home/${username}/.config/hypr/night-mode-toggle.sh
      exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
      exec-once = systemctl --user start ydotool
      exec-once = hyprctl setcursor rose-pine-hyprcursor 24
      exec-once = gsettings set org.gnome.desktop.interface cursor-theme 'rose-pine-hyprcursor'

      ####################
      ### WINDOW RULES ###
      ####################
windowrulev2 = monitor all,class:.*
# Notification rules
windowrulev2 = float, class:^(rofi)$,title:^(notification)$
windowrulev2 = noborder, class:^(rofi)$,title:^(notification)$
windowrulev2 = noshadow, class:^(rofi)$,title:^(notification)$
windowrulev2 = noinitialfocus, class:^(rofi)$,title:^(notification)$


      # Start menu
      windowrulev2 = stayfocused, class:^(rofi)$,title:^(start-menu)$
      windowrulev2 = float, class:^(rofi)$,title:^(start-menu)$
      windowrulev2 = animation slideup,class:^(rofi)$,title:^(start-menu)$
      windowrulev2 = move 10 830,class:^(rofi)$,title:^(start-menu)$
      windowrulev2 = noborder,class:^(rofi)$,title:^(start-menu)$
               
      # Steam
      windowrulev2 = size 800 600,class:^(Steam)$
      windowrulev2 = float,class:^(Steam)$,title:^(Friends List|Steam Settings|Steam Setup)$
      windowrulev2 = float,class:^(Steam)$,title:^(Steam - News)$
      windowrulev2 = float,class:^(steam)$,title:^(Steam Settings)$
      
      # Wofi
      windowrulev2 = float, class:^(wofi)$
      windowrulev2 = center, class:^(wofi)$,title:^(Applications)$
      windowrulev2 = animation slidedown,class:^(wofi)$
      windowrulev2 = noborder,class:^(wofi)$
      windowrulev2 = move cursor pointer,class:^(wofi)$,title:^(right-click-menu)$
      windowrulev2 = stayfocused,class:^(wofi)$,title:^(right-click-menu)$
      windowrulev2 = noborder,class:^(wofi)$,title:^(right-click-menu)$
   
      # PavuControl-Qt window rules
      windowrulev2 = size 800 600,class:^(pavucontrol-qt)$
      windowrulev2 = center,class:^(pavucontrol-qt)$
      windowrulev2 = float,class:^(pavucontrol-qt)$
      windowrulev2 = opacity 0.95,class:^(pavucontrol-qt)$
      windowrulev2 = animation slidedown,class:^(pavucontrol-qt)$
      
      windowrulev2 = stayfocused, class:^(xdg-desktop-portal-gtk)$
      windowrulev2 = stayfocused, class:^(xdg-desktop-portal-kde)$
      windowrulev2 = stayfocused, class:^(firefox)$,title:^(Opening)$

      # Firefox/LibreWolf Picture-in-Picture
      windowrulev2 = float,class:^(firefox|librewolf)$,title:^(Picture-in-Picture)$
      windowrulev2 = pin,class:^(firefox|librewolf)$,title:^(Picture-in-Picture)$

      # Discord
      # windowrulev2 = workspace 2 silent,class:^(discord)$
      # windowrulev2 = float,class:^(discord)$,title:^(Discord Updater)$
      # windowrulev2 = stayfocused,class:^(discord)$
      windowrulev2 = size 1200 700,class:^(discord)$
      windowrulev2 = float,class:^(discord)$
      windowrulev2 = center,class:^(discord)$
      # Steam
      windowrulev2 = stayfocused,title:^()$,class:^(steam)$
      windowrulev2 = minsize 1 1,title:^()$,class:^(steam)$

      # Spotify
      windowrulev2 = tile,class:^(Spotify)$
      windowrulev2 = workspace 10 silent,class:^(Spotify)$

      # File picker
      windowrulev2 = float,class:^(file_picker)$
      windowrulev2 = center,class:^(file_picker)$

      # Floating windows
      windowrulev2 = float,class:^(blueman-manager)$
      windowrulev2 = float,class:^(nm-connection-editor)$

      # Opacity rules
      windowrulev2 = opacity 0.95 0.95,class:^(Alacritty)$
      windowrulev2 = opacity 0.98 0.98,class:^(firefox|librewolf)$
      windowrulev2 = opacity 0.95 0.95,class:^(code)$

      # Position rules
      windowrulev2 = center,class:^(blueman-manager)$

      # No blur for certain windows
      windowrulev2 = noblur,class:^(firefox|librewolf)$

      ##################
      ### ANIMATIONS ###
      ##################
      layerrule = blur,^(waybar)$
      layerrule = blur,^(notifications)$
      layerrule = ignorezero,^(notifications)$


      
EOL

      # Set permissions
      chown -R ${username}:users /home/${username}/.config/hypr
      chmod -R u+w /home/${username}/.config/hypr
    '';
    deps = [];
  };
cursor-theme = {
    text = ''
      # Create required directories
      mkdir -p /home/${username}/.icons
      mkdir -p /home/${username}/.local/share/icons
      
      # Create symlink to the cursor themes
      ln -sf ${rose-pine-hyprcursor}/share/icons/rose-pine-hyprcursor /home/${username}/.local/share/icons/
      ln -sf ${rose-pine-hyprcursor}/share/icons/rose-pine-hyprcursor /home/${username}/.icons/
      ln -sf ${breezex-cursor}/share/icons/BreezeX-Black /home/${username}/.local/share/icons/
      ln -sf ${breezex-cursor}/share/icons/BreezeX-Black /home/${username}/.icons/
      
      # Set permissions
      chown -R ${username}:users /home/${username}/.icons
      chown -R ${username}:users /home/${username}/.local/share/icons
      chmod -R 755 /home/${username}/.icons
      chmod -R 755 /home/${username}/.local/share/icons

      # Create GTK cursor config
      mkdir -p /home/${username}/.config/gtk-3.0
      cat > /home/${username}/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-cursor-theme-name=BreezeX-Black
gtk-cursor-theme-size=24
EOF
      chown -R ${username}:users /home/${username}/.config/gtk-3.0
      chmod -R 755 /home/${username}/.config/gtk-3.0

      # Create default cursor theme configuration
      mkdir -p /home/${username}/.icons/default
      cat > /home/${username}/.icons/default/index.theme << EOF
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=BreezeX-Black
EOF
    '';
    deps = [];
  };
# cursor-theme = {
#     text = ''
#       mkdir -p /home/${username}/.icons/default
#       cat > /home/${username}/.icons/default/index.theme << EOF
# [Icon Theme]
# Inherits=rose-pine-hyprcursor
# EOF
#       mkdir -p /home/${username}/.icons
#       mkdir -p /home/${username}/.local/share/icons
      
#       # Create symlink to the cursor theme
#       ln -sf ${rose-pine-hyprcursor}/share/icons/rose-pine-hyprcursor /home/${username}/.local/share/icons/
      
#       # Set permissions
#       chown -R ${username}:users /home/${username}/.icons
#       chown -R ${username}:users /home/${username}/.local/share/icons
#     '';
#     deps = [];
#   };
  home-permissions = {
    text = ''
      # Ensure base directories exist with correct permissions
      mkdir -p /home/${username}/.cache
      mkdir -p /home/${username}/.local/share
      mkdir -p /home/${username}/.config
      
      # Set ownership for all critical directories
      chown ${username}:users /home/${username}
      chown -R ${username}:users /home/${username}/.cache
      chown -R ${username}:users /home/${username}/.local
      chown -R ${username}:users /home/${username}/.config
      
      # Set permissions
      chmod 755 /home/${username}/.cache
      chmod 755 /home/${username}/.local
      chmod 755 /home/${username}/.config
      
      # Ensure specific cache directories exist and are writable
      mkdir -p /home/${username}/.cache/starship
      mkdir -p /home/${username}/.cache/fish
      chown ${username}:users /home/${username}/.cache/starship
      chown ${username}:users /home/${username}/.cache/fish
      chmod 755 /home/${username}/.cache/starship
      chmod 755 /home/${username}/.cache/fish
    '';
    deps = [];
  };  
setup-user-dirs = ''
mkdir -p /home/${username}/Templates
  mkdir -p /home/${username}/Documents
  mkdir -p /home/${username}/Downloads
  mkdir -p /home/${username}/Music
  mkdir -p /home/${username}/Pictures
  mkdir -p /home/${username}/Videos
  mkdir -p /home/${username}/.local/share
  
  # Set ownership
  chown -R ${username}:users /home/${username}/Templates
  chown -R ${username}:users /home/${username}/Documents
  chown -R ${username}:users /home/${username}/Downloads
  chown -R ${username}:users /home/${username}/Music
  chown -R ${username}:users /home/${username}/Pictures
  chown -R ${username}:users /home/${username}/Videos
  chown -R ${username}:users /home/${username}/.local

  # Set permissions (755 for directories)
  chmod 755 /home/${username}/Templates
  chmod 755 /home/${username}/Documents
  chmod 755 /home/${username}/Downloads
  chmod 755 /home/${username}/Music
  chmod 755 /home/${username}/Pictures
  chmod 755 /home/${username}/Videos
  chmod 755 /home/${username}/.local
  chmod 755 /home/${username}/.local/share

'';
#7>[Activation-Hypr-Binds]
setup-hypr-binds = {
  text = ''
    # Ensure base directories exist with correct permissions
    mkdir -p /usr/local/bin
    chmod 755 /usr/local/bin

    # Create and set up wofi configuration directories
    mkdir -p /etc/xdg/rofi/themes
    chmod 755 /etc/xdg/rofi/themes

    # Set up user configuration directory chain
    mkdir -p /home/${username}/.config
    chown ${username}:users /home/${username}/.config
    chmod 755 /home/${username}/.config

    mkdir -p /home/${username}/.config/rofi
    chown ${username}:users /home/${username}/.config/rofi
    chmod 755 /home/${username}/.config/rofi

    # Check for and set up the main script
    if [ ! -f "/etc/hypr-binds.sh" ]; then
      echo "Warning: /etc/hypr-binds.sh does not exist. Please ensure it is properly configured in environment.etc"
      exit 1
    fi

    # Set up script permissions and symlink
    chmod 755 /etc/hypr-binds.sh
    chown root:root /etc/hypr-binds.sh
    ln -sf /etc/hypr-binds.sh /usr/local/bin/hypr-binds || {
      echo "Failed to create hypr-binds symlink"
      exit 1
    }

    # Set up style file symlink
    if [ -f "/etc/xdg/rofi/themes/keybindings.rasi" ]; then
      ln -sf /etc/xdg/rofi/themes/keybindings.rasi /home/${username}/.config/rofi/themes/keybindings.rasi
      chown -h ${username}:users /home/${username}/.config/rofi/themes/keybindings.rasi
    else
      echo "Warning: keybindings.rasi not found in /etc/xdg/rofi/"
      exit 1
    fi
  '';
  deps = [];
};
 rofi-setup = {
    text = ''
      # Create system XDG directory
      mkdir -p /etc/xdg/rofi/themes
      chmod 755 /etc/xdg/rofi/themes

      # Create user config directory
      mkdir -p /home/${username}/.config/rofi/themes
      
      # Create symlink from user directory to system directory
      ln -sf /etc/xdg/rofi/themes/start-menu.rasi /home/${username}/.config/rofi/themes/start-menu.rasi
      
      # Set correct ownership
      chown -R ${username}:users /home/${username}/.config/rofi
      chmod -R 755 /home/${username}/.config/rofi
    '';
    deps = [];
  };
#7>[Activation-Rust]
 rust-setup = {
    text = ''
      # Create .rustup and .cargo directories with correct ownership
      mkdir -p /home/${username}/.rustup /home/${username}/.cargo
      chown -R ${username}:users /home/${username}/.rustup /home/${username}/.cargo
      chmod 755 /home/${username}/.rustup /home/${username}/.cargo
    '';
    deps = [];
  };
# Waybar configuration
#7>[Activation-Waybar]
   setup-waybar-config = ''
      mkdir -p /etc/xdg/waybar
      chmod 755 /etc/xdg/waybar
      mkdir -p /home/${username}/.config/waybar
      ln -sf /etc/xdg/waybar/config /home/${username}/.config/waybar/config
      ln -sf /etc/xdg/waybar/style.css /home/${username}/.config/waybar/style.css
      chown -R ${username}:users /home/${username}/.config/waybar
    '';

 brightness-control = {
    text = ''
      # Ensure the script is executable
      chmod 755 /etc/brightness-control.sh
      
      # Create the directory for status files if it doesn't exist
      mkdir -p /run/user/1000/night-mode
      chmod 755 /run/user/1000/night-mode
    '';
    deps = [];
  };
#7>[Activation-Notification]
 notification-setup = {
    text = ''
      # Create notification queue directory
      mkdir -p /tmp/notifications
      chmod 777 /tmp/notifications
      
      # Create user-specific notification directories
      mkdir -p /run/user/1000/notifications
      chown ${username}:users /run/user/1000/notifications
      chmod 700 /run/user/1000/notifications
    '';
    deps = [];
  };

    
#7>[Activation-Start-Menu]
setup-start-menu = {
  text = ''
    if [ -f "/etc/start-menu.sh" ]; then
      chmod 755 /etc/start-menu.sh
    else
      echo "Warning: /etc/start-menu.sh does not exist. Please ensure it is properly configured in environment.etc"
      exit 1
    fi
    mkdir -p /home/${username}/.config/start-menu
    chown -R ${username}:users /home/${username}/.config/start-menu
  '';
  deps = [];
};
# wlogout configuration
#7>[Activation-Wlogout]
    setup-wlogout-config = ''
      mkdir -p /etc/xdg/wlogout
      chmod 755 /etc/xdg/wlogout
      mkdir -p /home/${username}/.config/wlogout
      ln -sf /etc/xdg/wlogout/layout /home/${username}/.config/wlogout/layout
      ln -sf /etc/xdg/wlogout/style.css /home/${username}/.config/wlogout/style.css
      chown -R ${username}:users /home/${username}/.config/wlogout
    '';

    
  screenshot-setup = {
   text = ''
    mkdir -p /home/${username}/Pictures/screenshots
    chown ${username}:users /home/${username}/Pictures/screenshots
    chmod 755 /home/${username}/Pictures/screenshots
  '';
  deps = [];
};
#Night Mode
#7>[Activation-Night-Mode]
    setup-night-mode = {
      text = ''
      mkdir -p /var/lib/night-mode
      chmod 777 /var/lib/night-mode
    '';
    deps = [];
  };
    
    userLocalShare = ''
      mkdir -p /home/${username}/.local/share
      chmod 755 /home/${username}/.local/share
      chown -R ${username}:users /home/${username}/.local/share
    '';


pcmanfm-config = {
    text = ''
      mkdir -p /home/${username}/.config/pcmanfm/default
      mkdir -p /home/${username}/.config/libfm
      
      cat > /home/${username}/.config/pcmanfm/default/pcmanfm.conf << 'EOL'
      [ui]
      always_show_tabs=0
      show_hidden=1
      
      [volume]
      mount_on_startup=1
      mount_removable=1
      
      [autorun]
      x-content/bootable-media=pcmanfm
      EOL
      
      cat > /home/${username}/.config/libfm/libfm.conf << 'EOL'
      [config]
      show_hidden=1
      show_internal_volumes=1
      EOL
      
      chown -R ${username}:users /home/${username}/.config/pcmanfm
      chown -R ${username}:users /home/${username}/.config/libfm
      chmod -R 755 /home/${username}/.config/pcmanfm
      chmod -R 755 /home/${username}/.config/libfm
    '';
    deps = [];
  };

setup-vlc-config = {
    text = ''
      mkdir -p /home/${username}/.config/vlc
      
      cat > /home/${username}/.config/vlc/vlcrc << 'EOL'
      [qt]
      # Disable metadata and network features
      metadata-network-access=0
      qt-privacy-ask=0
      
      [core]
      # Disable all metadata collection and network access
      metadata-network-access=0
      album-art-filename=0
      auto-metadata-network-access=0
      metadata-network-albumart=0
      metadata-network-thumbnails=0
      
      # Additional privacy settings
      stats-network-access=0
      ml-network-access=0
      show-privacy-notice=0
      
      # Disable update checks
      qt-updates-notif=0
      qt-updates-days=0
      one-instance-when-started-from-file=0
      EOL
      
      chown -R ${username}:users /home/${username}/.config/vlc
      chmod -R 755 /home/${username}/.config/vlc
    '';
    deps = [];
  };    
# Alacritty configuration
#7>[Activation-Alacritty]
    setup-alacritty-config = ''
      mkdir -p /etc/alacritty
      chmod 755 /etc/alacritty
      mkdir -p /home/${username}/.config/alacritty
      ln -sf /etc/alacritty/alacritty.toml /home/${username}/.config/alacritty/alacritty.toml
      chown -R ${username}:users /home/${username}/.config/alacritty
    '';

# Fish shell configuration
#7>[Activation-Fish]
    # setup-fish-config = ''
    #   mkdir -p /etc/fish/functions
    #   chmod 755 /etc/fish
    #   chmod 755 /etc/fish/functions
    #   mkdir -p /home/${username}/.config/fish/completions
    #   ln -sf /etc/fish/config.fish /home/${username}/.config/fish/config.fish
    #   ln -sf /etc/fish/fish_user_key_bindings.fish /home/${username}/.config/fish/fish_user_key_bindings.fish
    #   ln -sf /etc/fish/functions/custom_tab_complete.fish /home/${username}/.config/fish/functions/custom_tab_complete.fish
    #   chown -R ${username}:users /home/${username}/.config/fish
    # '';
    fish-setup = {
      text = ''
        # Create system directories
        mkdir -p /etc/fish/functions
        mkdir -p /etc/fish/conf.d
        mkdir -p /etc/fish/completions
        chmod 755 /etc/fish
        chmod 755 /etc/fish/functions
        
        # Create user directories
        mkdir -p /home/${username}/.config/fish/conf.d
        mkdir -p /home/${username}/.config/fish/functions
        mkdir -p /home/${username}/.config/fish/completions
        mkdir -p /home/${username}/.local/share/fish
        mkdir -p /home/${username}/.local/share/fish/generated_completions

        # Create symbolic links for configuration files
        ln -sf /etc/fish/config.fish /home/${username}/.config/fish/config.fish || true
        ln -sf /etc/fish/fish_user_key_bindings.fish /home/${username}/.config/fish/fish_user_key_bindings.fish || true
        ln -sf /etc/fish/functions/custom_tab_complete.fish /home/${username}/.config/fish/functions/custom_tab_complete.fish || true

        # Handle fish history
        if [ ! -f "/home/${username}/.local/share/fish/fish_history" ]; then
          touch "/home/${username}/.local/share/fish/fish_history"
        fi

        # Set ownership and permissions
        chown -Rf ${username}:users /home/${username}/.config/fish || true
        chown -Rf ${username}:users /home/${username}/.local/share/fish || true
        chmod -R 755 /home/${username}/.config/fish || true
        chmod -R 755 /home/${username}/.local/share/fish || true
        
        # Ensure fish_history has proper permissions
        if [ -f "/home/${username}/.local/share/fish/fish_history" ]; then
          chown ${username}:users "/home/${username}/.local/share/fish/fish_history"
          chmod 644 "/home/${username}/.local/share/fish/fish_history"
        fi
      '';
      deps = [];
    };
    # Update your existing zellij setup script
#7>[Activation-Zellij]
setup-zellij-config = {
      text = ''
        # Create system directories
        mkdir -p /etc/zellij/layouts
        chmod -R 755 /etc/zellij
        
        # Create user directories
        mkdir -p /home/${username}/.config/zellij/{layouts,plugins}
        mkdir -p /home/${username}/.local/share/zellij
        
        # Create symbolic links with error handling
        ln -sf /etc/zellij/config.kdl /home/${username}/.config/zellij/config.kdl || true
        ln -sf /etc/zellij/layouts/solarized.kdl /home/${username}/.config/zellij/layouts/solarized.kdl || true
        
        # Set ownership and permissions
        chown -R ${username}:users /home/${username}/.config/zellij || true
        chown -R ${username}:users /home/${username}/.local/share/zellij || true
        chmod -R 755 /home/${username}/.config/zellij || true
        chmod -R 755 /home/${username}/.local/share/zellij || true
      '';
      deps = [];
    };
    sshUserDir = {
         text = ''
    mkdir -p /home/${username}/.ssh
    chmod 700 /home/${username}/.ssh
    chown ${username}:users /home/${username}/.ssh
   '';
  };
# Helix Editor configuration
#7>[Activation-Helix]
helix-config-dir = ''
  mkdir -p /etc/helix/themes
  chmod 755 /etc/helix
  chmod 755 /etc/helix/themes
  
  # Setup for user
  mkdir -p /home/${username}/.config/helix
  ln -sf /etc/helix/config.toml /home/${username}/.config/helix/config.toml
  ln -sf /etc/helix/themes /home/${username}/.config/helix/themes
  chown -R ${username}:users /home/${username}/.config/helix
  
  # Setup for root
  mkdir -p /root/.config/helix
  ln -sf /etc/helix/config.toml /root/.config/helix/config.toml
  ln -sf /etc/helix/themes /root/.config/helix/themes

  ln -sf /etc/nixian-jump.sh /usr/local/bin/hx-jump
'';

# LibreWolf configuration
#7>[Activation-LibreWolf]
  librewolf-persistence = ''
    # Create persistence directory
    mkdir -p /nix/persist/home/${username}/.librewolf
    chown ${username}:users /nix/persist/home/${username}/.librewolf
    chmod 755 /nix/persist/home/${username}/.librewolf

    # Create LibreWolf directory
    mkdir -p /home/${username}/.librewolf
    chown ${username}:users /home/${username}/.librewolf
    chmod 755 /home/${username}/.librewolf
  '';
#7>[Activation-LibreOffice]
# Libreoffice configuration
  libreoffice-setup = {
    text = ''
      mkdir -p /nix/persist/home/${username}/.config/libreoffice
      chown -R ${username}:users /nix/persist/home/${username}/.config/libreoffice
      chmod -R 755 /nix/persist/home/${username}/.config/libreoffice
      
      # Also create cache directory
      mkdir -p /home/${username}/.cache/libreoffice
      chown ${username}:users /home/${username}/.cache/libreoffice
      chmod 755 /home/${username}/.cache/libreoffice
    '';
    deps = [];
  };
# Window minimize configuration
#7>[Activation-Minimize Window]
  create-minimize-state = {
    text = ''
      mkdir -p /var/lib/minimize-state
      chmod 777 /var/lib/minimize-state
    '';
    deps = [];
  };
};
  ###########################################
  #  Hardware Configuration
  ###########################################
#8[Hardware Configuration]
  ###########################################
hardware = {
  # CPU Configuration
  # Graphics Configuration  
 nvidiaOptimus.disable = if isLaptop then true else false;
  graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; 
      if hasNvidia then [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau
      ] else if hasAmd then [
        rocm-opencl-icd
        rocm-opencl-runtime
        amdvlk
        vulkan-validation-layers
        mesa.drivers
      ] else if hasIntel then [
        intel-media-driver
        intel-vaapi-driver
        intel-compute-runtime
        vulkan-validation-layers
        mesa.drivers
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ] else [];
      
    extraPackages32 = with pkgs.pkgsi686Linux;
      if hasNvidia then [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau
      ] else [];
  };

  nvidia = if hasNvidia then {
    open = true; 
    modesetting.enable = true;
    powerManagement = {
      enable = false;
      finegrained = false;
    };
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.production;
    forceFullCompositionPipeline = true;
    nvidiaPersistenced = true;
  } else {};

  amdgpu = if hasAmd then {
    enable = true;
    loadInInitrd = true;
    amdvlk = true;
    opencl = true;
    firmware = true;
  } else {};

  cpu = if hasIntel then {
    intel.updateMicrocode = true;
    enableKVM = true;
    }
    else if hasAmd then {
    amd.updateMicrocode = true;
    enableKVM = true;
  } else {};

#8>[Bluetooth]
bluetooth = {
  enable = true;
  powerOnBoot = true;
  package = pkgs.bluez;
  settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
    #Seemingly does nothing at the moment
    "Device:MX Ergo" = {
      ReconnectAttempts = 0;
      ReconnectIntervals = "0";
      AutoConnect = true;
    };
  };
  };
};
  
  ###########################################
  #  Audio Configuration
  ###########################################
#9[Audio]
#9>[PipeWire]
services.pipewire = {
  enable = true;
  alsa.enable = true;
  alsa.support32Bit = true;
  pulse.enable = true;
  jack.enable = true;
  wireplumber.enable = true;

  # Enhanced audio config with focus on voice reproduction
  extraConfig.pipewire = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [ 44100 48000 88200 96000 192000 ];
      # Increased quantum for better bass processing
      "default.clock.quantum" = 2048;        # Larger window for bass frequencies
      "default.clock.min-quantum" = 1024;    # Increased minimum for consistent bass
      "default.clock.max-quantum" = 4096;    # Allow larger processing windows when needed
      "core.daemon" = true;
      "link.max-buffers" = 32;               # More buffering for smoother bass
    };
    # Add specific module for bass enhancement
    "context.modules" = [
      {
        "name" = "libpipewire-module-filter-chain";
        "args" = {
          "node.description" = "Bass Enhancer";
          "filter.graph" = {
            "nodes" = [
              {
                "type" = "ladspa";
                "name" = "bass_enhancer";
                "plugin" = "bs2b";
                "label" = "bass_enhance";
                "control" = {
                  "frequency" = 100;     # Bass frequency cutoff
                  "intensity" = 50;      # Bass enhancement level
                };
              }
            ];
          };
        };
      }
    ];
  };

  extraConfig."pipewire-pulse" = {
    "context.properties" = {
      "pulse.defaults" = {
        "sink.name" = "alsa-sink";
        "sink.description" = "SPDIF Output";
        "resample.quality" = 7;
        "channelmix.normalize" = true;
        "channelmix.mix-lfe" = true;
        "channelmix.lfe-cutoff" = 150;      # Specific frequency cutoff for LFE
        "resample.disable" = false;
        # Bass-specific settings
        "channelmix.subwoofer-cutoff" = 250;  # Upper limit for bass frequencies
        "stream.props" = {
          "media.format" = "S32LE";          # Higher bit depth for better bass detail
          "audio.channels" = 2;              # Ensure stereo processing
        };
      };
    };
    "stream.properties" = {
      "resample.quality" = 7;
      "channelmix.normalize" = true;
      "channelmix.mix-lfe" = true;
      "channelmix.lfe-cutoff" = 150;
      "resample.disable" = false;
    };
  };
};
  ###########################################
  #  Printing
  ###########################################
#10[Printing]
  services.printing.enable = true;
  
  ###########################################
  #  Nix Configuration
  ###########################################
#16[Nix Configuration]
    nix = {
      settings = {
        experimental-features = [ "nix-command"];
      # Utilize all CPU cores for building
      max-jobs = "auto";
      # Each job can use up to 16 threads on my setup (adjust based on your specific workload requirements)
      cores = 16;
      
      # Enable parallel builds in the future maybe?
      use-xdg-base-directories = true;
      
      auto-optimise-store = true;
      
      trusted-users = ["${username}" ];
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      
      keep-outputs = true;
      keep-derivations = true;
    };
    
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
  
  ###########################################
  #  Security Configuration
  ###########################################
#12[Security Configuration]
    security = {
      audit.enable = true;
      auditd.enable = true;
     rtkit.enable = true;
      polkit.enable = true;
polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.udisks2.filesystem-mount" ||
        action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
        action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
        action.id == "org.freedesktop.udisks2.eject-media" ||
        action.id == "org.freedesktop.udisks2.power-off-drive") {
      return polkit.Result.YES;
    }
  });
'';
     wrappers.ydotool = {
  owner = "root";
  group = "wheel";
  capabilities = "cap_dac_override,cap_sys_admin+ep";
  source = "${pkgs.ydotool}/bin/ydotool";
};
      apparmor = {
        enable = true;
        packages = with pkgs; [ apparmor-profiles ];
      };

      pam = {
        loginLimits = [
          { domain = "*"; type = "soft"; item = "nofile"; value = "1048576"; }
        ];
        services.greetd.enableGnomeKeyring = true;
      };
      sudo.extraRules = [{
    groups = [ "wheel" ];
     commands = [
     {
        command = "/etc/nixian-jump.sh";
        options = [ "NOPASSWD" "SETENV" ];
      }
      {
        command = "${pkgs.ydotool}/bin/ydotool"; 
        options = [ "NOPASSWD" "SETENV" ];
      }
      {
        command = "${pkgs.ydotool}/bin/ydotoold";
        options = [ "NOPASSWD" "SETENV" ];
      }
      {
        command = "${pkgs.systemd}/bin/systemctl poweroff";
        options = [ "NOPASSWD" ];
      }
      {
        command = "${pkgs.systemd}/bin/systemctl reboot";
        options = [ "NOPASSWD" ];
      }
      {
        command = "${pkgs.systemd}/bin/systemctl suspend";
        options = [ "NOPASSWD" ];
      }
      {
        command = "${pkgs.systemd}/bin/systemctl hibernate";
        options = [ "NOPASSWD" ];
      }
    ];
  }];
  };
  
  ###########################################
  #  User Configuration
  ###########################################

#13[User Configuration]
services.dbus = {
  enable = true;
  packages = [ pkgs.gcr pkgs.blueman ];
};

#13>[XDG-Portal]
xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
  ];
  config = {
    common = {
      default = ["hyprland" "gtk"];
    };
    hyprland = {
      default = ["hyprland" "gtk"];
    };
  };
};
qt = {
  enable = true;
  platformTheme = "qt5ct";
  style = "kvantum";
};


users.users.pulse = {
  isSystemUser = true;
  group = "pulse";
};
users.groups.pulse = {};


users.users.nm-openconnect = {
  isSystemUser = true;
  group = "nm-openconnect";
};
users.groups.nm-openconnect = {};
  hardware.brillo.enable = true;

  ###########################################
  #  Shell Configuration
  ###########################################
#14[Shell Configuration]
#14>[Fish Shell]
  programs.fish.enable = true;
  programs.fish.interactiveShellInit = ''
    set -gx HELIX_RUNTIME "${pkgs.helix}/share/helix/runtime"
    set -gx HELIX_CONFIG_DIR "/etc/helix"
  '';
  programs.fish = {
   shellAliases = {
    clone = "git clone git@github.com:$argv";
    update = "sudo nixos-rebuild switch";
    upgrade = "sudo nix-channel --update && sudo nixos-rebuild switch";
    clean = "sudo nix-collect-garbage -d";
    config = "sudo hx /etc/nixos/configuration.nix";
    keybinds = "/etc/hypr-binds.sh";

  };
 };
#14>[Starship]
  programs.starship.enable = true;
  programs.bash.interactiveShellInit = ''
    if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
    then
      shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
      exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
    fi
  '';

  ###########################################
  #  Package Configuration
  ###########################################
#15[Package Configuration]
#15>[DConf]
# Add to your existing dconf settings
programs.dconf = {
  enable = true;
  profiles = {
    gdm.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          cursor-theme = "BreezeX-Black";
          cursor-size = lib.gvariant.mkInt32 24;
          text-scaling-factor = lib.gvariant.mkDouble 1.5;
          enable-large-text = true;
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
        "org/gnome/desktop/a11y/interface" = {
          high-contrast = true;
        };
      };
    }];
    user.databases = [{
      settings = {
        "org/gnome/desktop/interface" = {
          cursor-theme = "BreezeX-Black";
          cursor-size = lib.gvariant.mkInt32 24;
          text-scaling-factor = lib.gvariant.mkDouble 1.5;
          enable-large-text = true;
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
        "org/gnome/desktop/a11y/interface" = {
          high-contrast = false;  # Disable high contrast for regular session
        };
      };
    }];
  };
};


  nixpkgs.config.allowUnfree = true;
#15>[Firefox]

programs.firefox = {
  enable = true;
  preferences = {

    "ui.useOverlayScrollbars" = 1;
    "widget.use-xdg-desktop-portal" = true;
    "widget.gtk.overlay-scrollbars.enabled" = true;
    "mousewheel.default.override_page_zoom" = true;

 "dom.ipc.processCount" = 4;  
    "browser.preferences.defaultPerformanceSettings.enabled" = false;
    "gfx.webrender.all" = true;  
    "layers.acceleration.force-enabled" = true;
    "browser.cache.disk.enable" = false;  # Prevent disk writes
    "browser.cache.memory.enable" = true;
    "browser.cache.memory.capacity" = 524288;  # 512MB memory cache  
    "browser.eme.ui.enabled" = true;              
    "media.eme.enabled" = true;                       
    "media.ffmpeg.vaapi.enabled" = true;              
    "media.hardware-video-decoding.enabled" = true;   
    "media.hardware-video-decoding.force-enabled" = true;
    # HTML5 media settings
    "media.format-reader.webm" = true;
    "media.mediasource.webm.audio.enabled" = true;
    "media.mediasource.webm.enabled" = true;
    "media.benchmark.vp9.fps" = 60;
    "media.benchmark.frames" = 300;
    "media.webspeech.synth.enabled" = true;
    # Experimental
    "media.webspeech.synth.force_global_queue" = false;
    "media.throttle-factor" = 2;
    "media.throttle-factor.inactive-tab" = 2;
    # Audio processing
    "media.getusermedia.aec_enabled" = false;
    "media.getusermedia.noise_enabled" = false;
    "media.getusermedia.agc_enabled" = false;
  };
};
  
programs.java = {
  enable = true;
  package = pkgs.jre;  
};
#15>[Steam]
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  package = pkgs.steam.override {
    extraEnv = {
       # SDL_VIDEO 22DRIVER = "x11";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      __NV_PRIME_RENDER_OFFLOAD = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      STEAM_RUNTIME_PREFER_HOST_LIBRARIES = "0";
      STEAM_RUNTIME = "1";
      # Add Vulkan paths
    };
  };
};

  ###########################################
  #  System Packages
  ###########################################

nixpkgs.config = {
  packageOverrides = pkgs: {
    unstable = import (fetchTarball "https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz") {
      config = config.nixpkgs.config;
    };
  };
};
  
  environment.systemPackages = with pkgs; [
  (writeScriptBin "discord" ''
    #!${stdenv.shell}
    env DISCORD_SKIP_SANDBOX=1 ELECTRON_NO_SANDBOX=1 ${discord}/bin/discord --no-sandbox --disable-gpu-sandbox "$@"
  '')
#16[System Packages]
      # Scripts
       (writeShellScriptBin "window-preview" ''
    exec /etc/preview-script.sh "$@"
  '')
  (writeShellScriptBin "minimize-manager" ''
    exec /etc/minimize-manager.sh "$@"
  '')
  (writeShellScriptBin "toggle-night-mode" ''
    exec /etc/toggle-night-mode.sh "$@"
  '')
  (writeShellScriptBin "hx-jump" ''
    exec /etc/nixian-jump.sh "$@"
  '')
  (writeScriptBin "notify" ''
    #!${stdenv.shell}
    exec /etc/notification.sh "$@"
  '')
        
#16>[Wayland Tools]
      wayland
      xwayland
      waybar
      rofi-wayland
      wofi
      wl-clipboard
      grim
      slurp
      ffmpeg
      imv
      wf-recorder
      wireplumber
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      qt6.qtwayland
      freetype
            
#16>[Hyprland]
      unstable.hyprland
      hyprpaper
      rose-pine-hyprcursor
      hyprlang
      hyprland-protocols
      xdg-desktop-portal-hyprland
      xdg-utils
            
#16>[Audio]
      pamixer
      lxqt.pavucontrol-qt
      playerctl
      
#16>[System Utils]
      udiskie
      ntfs3g
      udisks2
      polkit_gnome
      libnotify
      pcmanfm
      geany
      yad
      wmctrl
      libpng
      libjpeg
      libwebp
      shared-mime-info
      networkmanager
      blueberry
      socat
      brightnessctl
      wlsunset 
      geoclue2
      imagemagick
      gdm
      gnome-session
      vulkan-tools
      gifsicle
      jre
      networkmanagerapplet
      
#16>[Terminal]
      alacritty
      fish
      starship
      zellij
      zjstatus-plugin
      
#16>[Development]
      python39
      nil
      nixpkgs-fmt
      helix
      jq
      gcc
      gitFull
      rustup
      rustfmt
      rust-analyzer
      cargo
      clippy
      
#16>[Applications]
      libreoffice-qt6-fresh
      librewolf
      steam
      vlc
      discord
      brave

#16>[System-Monitoring]
      btop
      neofetch
      kcalc
      powertop
      
#16>[Security]
      unzip
      zip
      clamav
      clamtk
#16>[Theming]
      nwg-menu
      libsForQt5.qt5ct      
      libsForQt5.qtstyleplugin-kvantum        
      lxappearance
      nix-bundle
      ydotool
      gtk3 
      glib 
      gsettings-desktop-schemas
      adwaita-icon-theme
  ];

  ###########################################
  #  Fonts & Theme Configuration
  ###########################################
#17[Fonts & Theme Configuration]
#17>[Font Packages]
fonts = {
  packages = with pkgs; [
    (nerdfonts.override { fonts = [
      "FiraCode"
      "JetBrainsMono"
      "Iosevka"
    ];})
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    dejavu_fonts
    ubuntu_font_family
    source-sans-pro
    roboto
  ];

#17>[Font-Configurations]
  fontconfig = {
    enable = true;
    antialias = true;
    hinting = {
      enable = true;
      style = "slight";
    };
    subpixel = {
      rgba = "rgb";
      lcdfilter = "light";
    };
    defaultFonts = {
      serif = [ "DejaVu Serif" "Noto Serif" ];
      sansSerif = [ "Ubuntu" "DejaVu Sans" "Noto Sans" ];  
      monospace = [ "FiraCode Nerd Font" "DejaVu Sans Mono" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
};

  ###########################################
  #  System Services
  ###########################################

#19[System Services]
services.udisks2.enable = true;  # Enables drive mounting
services.gvfs.enable = true;     # Enables trash, mounting, and other functionalities
services.devmon.enable = true;   # Automounting service

   systemd = {
      services = {
      xdg-desktop-portal-hyprland = {
    description = "Portal for Hyprland";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "xdg-desktop-portal.service" ];
    after = [ "xdg-desktop-portal.service" ];
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.impl.portal.desktop.hyprland";
      ExecStart = "${pkgs.xdg-desktop-portal-hyprland}/libexec/xdg-desktop-portal-hyprland";
      Restart = "on-failure";
    };
  };

systemd-tmpfiles-clean = {
  serviceConfig = {
    ExecStart = [
      ""  # Clear the default
      "${pkgs.systemd}/bin/systemd-tmpfiles --clean --exclude-prefix=/tmp/screenshot"
    ];
  };
};
        minimize-manager = {
          description = "Window Minimize Manager Service";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          
          serviceConfig = {
            # Restart configuration
            Restart = "on-failure";
            RestartSec = "5s";
            StartLimitIntervalSec = "300";
            StartLimitBurst = "3";
            
            # Service shutdown
            TimeoutStopSec = "10s";
            KillMode = "mixed";
            
            # Security hardening
            NoNewPrivileges = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectControlGroups = true;
            RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" ];
            
            # Resource limits
            MemoryHigh = "100M";
            MemoryMax = "200M";
            CPUQuota = "30%";
            IOWeight = 100;
            IODeviceWeight = [
              "/dev/sda 100"
            ];
            
            # Directories
            RuntimeDirectory = "minimize-manager";
            RuntimeDirectoryMode = "0755";
            StateDirectory = "minimize-manager";
            StateDirectoryMode = "0700";
            CacheDirectory = "minimize-manager";
            CacheDirectoryMode = "0750";
            
            # Paths
            ReadOnlyPaths = [ "/etc" ];
            ReadWritePaths = [ "/var/lib/minimize-state" "/run/user" ];
          };
        };
        ydotool = {
          description = "ydotool daemon";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.ydotool}/bin/ydotoold";
            Restart = "always";
          };
           environment = {
        XDG_RUNTIME_DIR = "%t";  
       WAYLAND_DISPLAY = "wayland-1";
    };
        };

        reload-btusb = {
          description = "Reload Bluetooth USB Module After Sleep";
          wantedBy = [ "suspend.target" ];
          after = [ "suspend.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.systemd}/bin/systemctl stop bluetooth.service";
            ExecStartPost = [
              "${pkgs.systemd}/bin/modprobe -r btusb"
              "${pkgs.systemd}/bin/modprobe btusb"
              "${pkgs.systemd}/bin/systemctl start bluetooth.service"
            ];
          };
        };

        clamscan = {
          description = "Scheduled ClamAV scan";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.clamav}/bin/clamscan -r --quiet --exclude-dir='^/sys|^/dev|^/proc|^/run|^/tmp' --max-filesize=25M --max-scansize=100M --move=/var/quarantine /home";
            Nice = 19;
            IOSchedulingClass = "idle";
            IOSchedulingPriority = 7;
            CPUSchedulingPolicy = "idle";
            CPUQuota = "30%";
          };
        };

      };

      user.services = {
#14>[Minimize-Cleanup]
        minimize-cleanup = {
          description = "Clean up stale minimized windows";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScript "minimize-cleanup" ''
              /etc/minimize-manager.sh cleanup
            ''}";
          };
        };
        waybar = {
          description = "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          documentation = [ "https://github.com/Alexays/Waybar/wiki" ];
          wantedBy = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.waybar}/bin/waybar";
            ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
            Restart = "on-failure";
            KillMode = "mixed";
          };
          environment = {
    XDG_CONFIG_HOME = "/etc/xdg";
  };
        };

        wlsunset = {
          description = "Wlsunset Night Light";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.wlsunset}/bin/wlsunset -g -t 3000 -T 6500";
            Restart = "always";
            RestartSec = "3";
            CPUQuota = "20%";
            EnvironmentFile = "-/etc/default/wlsunset";
          };
        };

      };

      timers = {
        clamscan = {
          wantedBy = [ "timers.target" ];
          partOf = [ "clamscan.service" ];
          timerConfig = {
            OnCalendar = "weekly";
            RandomizedDelaySec = "33h";
            Persistent = true;
          };
        };

#14>[Minimize-Cleanup-Timer]
        minimize-cleanup = {
          wantedBy = [ "timers.target" ];
          partOf = [ "minimize-cleanup.service" ];
          timerConfig = {
            OnBootSec = "5m";
            OnUnitActiveSec = "1h";
          };
        };
      };

      
#19>[Systemd-Tmp]
      tmpfiles.rules = [
        "d /run/clamav/tmp 0755 clamav clamav -"
      ];
      user.tmpfiles.rules = [
        "d /home/${username}/.config/waybar 0755 ${username} users - -"
      ];
    };    
#19>[fstrim]
    services = {

      # SSD optimization
      fstrim = {
        enable = true;
        interval = "weekly";
      };

#19>[Keyd]
      keyd = {
        enable = true;
        keyboards = {
          default = {
            ids = [ "*" ];
            settings = {
              main = {
                capslock = "overload(meta, esc)";
              };
            };
          };
        };
      };
    };

#19>[XDG Configuration]
    xdg.mime = {
      enable = true;
      defaultApplications = {
        "image/jpeg" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/gif" = "imv.desktop";
      };
    };
# gnome.gnome-bluetooth.enable = true;
  ###########################################
  #  Firewall & AV Security Settings
  ###########################################
#20>[ClamAV]
services.clamav = {
     daemon = {
      enable = true;
      settings = {
        MaxThreads = 4;  
        MaxDirectoryRecursion = 15;
        MaxScanSize = "100M";
        MaxFileSize = "25M";
        StreamMaxLength = "50M";
        
        OnAccessMountPath = "/home";
        DisableCertCheck = true;
        
        TemporaryDirectory = "/run/clamav/tmp";  
        MaxEmbeddedPE = "10M";
        MaxHTMLNormalize = "10M";
        MaxHTMLNoTags = "2M";
        MaxScriptNormalize = "5M";
        MaxZipTypeRcg = "1M";
      };
    };
    updater = {
      enable = true;
      interval = "daily"; 
      frequency = 1;  
    };
  };


  ###########################################
  #  Program Configuration Files
  ###########################################
#21[Program Configuration Files]
  environment.etc = {
"xdg/applications/discord.desktop" = {
  text = ''
    [Desktop Entry]
    Name=Discord
    StartupWMClass=discord
    Comment=All-in-one voice and text chat for gamers
    GenericName=Internet Messenger
    Exec=env DISCORD_SKIP_SANDBOX=1 ELECTRON_NO_SANDBOX=1 discord --no-sandbox --disable-gpu-sandbox %U
    Icon=discord
    Type=Application
    Categories=Network;InstantMessaging;
    Path=/usr/bin
    Keywords=discord;gaming;chat;voice;
    StartupNotify=true
  '';
  mode = "0644";
};
"xdg/qt5ct/qt5ct.conf".text = ''
    [Appearance]
    custom_palette=true
    icon_theme=Papirus-Dark
    style=kvantum

    [Interface]
    dialogue_buttons_have_icons=0
    gui_effects=@Invalid()
    menus_have_icons=true
    stylesheets=@Invalid()
    toolbutton_style=4

    [PaletteEditor]
    geometry=@ByteArray()

    [SettingsWindow]
    geometry=@ByteArray()
  '';

  "xdg/Kvantum/kvantum.kvconfig".text = ''
    [General]
    theme=Nordic-Darker

    [pavucontrol-qt]
    inherits=Nordic-Darker
    background.normal=#2e3440
    background.alternate=#3b4252
    foreground.normal=#d8dee9
    foreground.inactive=#4c566a
  '';
"xdg/gtk-3.0/settings.ini".text = ''
  [Settings]
  gtk-application-prefer-dark-theme=1
  gtk-cursor-theme-name=rose-pine-hyprcursor
  gtk-cursor-theme-size=24
  gtk-font-name=DejaVu Sans 11
  gtk-xft-antialias=1
  gtk-xft-hinting=1
  gtk-xft-hintstyle=hintslight
  gtk-xft-rgba=rgb
'';

  "xdg/pcmanfm/default/pcmanfm.conf" = {
    text = ''
      [ui]
      always_show_tabs=0
      show_hidden=1
    '';
    mode = "0644";
  };

  # LibFM configuration (which PCManFM uses)
  "xdg/libfm/libfm.conf" = {
    text = ''
      [config]
      show_hidden=1
    '';
    mode = "0644";
  };

  # VLC configuration
  "xdg/vlc/vlcrc" = {
    text = ''
      [qt]
      # Disable metadata and network features
      metadata-network-access=0
      qt-privacy-ask=0
      
      [core]
      # Disable all metadata collection and network access
      metadata-network-access=0
      album-art-filename=0
      auto-metadata-network-access=0
      metadata-network-albumart=0
      metadata-network-thumbnails=0
      
      # Additional privacy settings
      stats-network-access=0
      ml-network-access=0
      show-privacy-notice=0
      
      # Disable update checks
      qt-updates-notif=0
      qt-updates-days=0
      one-instance-when-started-from-file=0
    '';
    mode = "0644";
  };

#21>[Script-Hypr-Binds]
"hypr-binds.sh" = {
    text = ''
#!/run/current-system/sw/bin/bash

# If running as root, re-run as user with proper environment
if [ "$(id -u)" = "0" ]; then
    REAL_USER="${username}"
    REAL_USER_ID=$(id -u $REAL_USER)
    exec sudo -H -u $REAL_USER \
        DISPLAY=:0 \
        WAYLAND_DISPLAY="wayland-1" \
        XDG_RUNTIME_DIR="/run/user/$REAL_USER_ID" \
        "$0" "$@"
fi

CONFIG_FILE="$HOME/.config/hypr/hyprland.conf"
TEMP_FILE="/tmp/hypr-bindings-$(id -u).txt"

translate_special_key() {
    local key="$1"
    case "$key" in
        "XF86AudioNext") echo "Media Next" ;;
        "XF86AudioPrev") echo "Media Previous" ;;
        "XF86AudioPlay") echo "Media Play/Pause" ;;
        "XF86AudioStop") echo "Media Stop" ;;
        "XF86AudioRaiseVolume") echo "Volume Up" ;;
        "XF86AudioLowerVolume") echo "Volume Down" ;;
        "XF86AudioMute") echo "Volume Mute" ;;
        "Print") echo "PrtSc" ;;
        *) echo "$key" ;;
    esac
}

format_key() {
    local key_def="$1"
    local modifiers key
    
    modifiers=$(echo "$key_def" | sed -e 's/bind[me]* *= *//' -e 's/, *[^,]*$//')
    key=$(echo "$key_def" | sed -n 's/.*[, ]\([^,]*\)$/\1/p')
    
    modifiers=$(echo "$modifiers" | sed \
        -e 's/\$mainMod/Super/g' \
        -e 's/\$alt/Alt/g' \
        -e 's/SUPER/Super/g' \
        -e 's/ALT/Alt/g' \
        -e 's/CTRL/Ctrl/g' \
        -e 's/SHIFT/Shift/g' \
        -e 's/  */ /g')
    
    key=$(translate_special_key "$key")
    
    if [ -n "$key" ]; then
        if [ -n "$modifiers" ]; then
            echo "$modifiers + $key"
        else
            echo "$key"
        fi
    else
        echo "$modifiers"
    fi
}

get_description() {
    local action="$1"
    local key="$2"
    
    case "$key" in
        *"XF86AudioPlay"*|*"playerctl play"*)
            echo "🎵 Play/Pause media" ;;
        *"XF86AudioNext"*|*"playerctl next"*)
            echo "⏭️  Next track" ;;
        *"XF86AudioPrev"*|*"playerctl previous"*)
            echo "⏮️  Previous track" ;;
        *"XF86AudioStop"*|*"playerctl stop"*)
            echo "⏹️  Stop playback" ;;
        *"XF86AudioRaiseVolume"*|*"wpctl set-volume"*"+"*)
            echo "🔊 Increase volume" ;;
        *"XF86AudioLowerVolume"*|*"wpctl set-volume"*"-"*)
            echo "🔉 Decrease volume" ;;
        *"XF86AudioMute"*|*"wpctl set-mute"*)
            echo "🔇 Toggle mute" ;;
        *)
            case "$action" in
                *"grim -g"*"slurp"*)
                    echo "📷 Screenshot selected area" ;;
                *"grim"*)
                    if [[ $key == *"Shift"* ]]; then
                        echo "📷 Save screenshot to Pictures"
                    elif [[ $key == *"Super"* ]]; then
                        echo "📷 Screenshot to editor"
                    else
                        echo "📷 Screenshot to clipboard"
                    fi
                    ;;
                *"killactive"*)
                    echo "⊗ Close active window" ;;
                *"togglefloating"*)
                    echo "🪟 Toggle floating mode" ;;
                *"pseudo"*)
                    echo "⬚ Toggle pseudo-tiling" ;;
                *"togglesplit"*)
                    echo "⮀ Toggle split orientation" ;;
                *"fullscreen"*)
                    echo "⛶ Toggle fullscreen" ;;
                *"exec, $term"*)
                    echo "󰆍 Open terminal" ;;
                *"exec, $browser"*)
                    echo "󰈹 Launch web browser" ;;
                *"exec, $fileManager"*)
                    echo "󰉋 Open file manager" ;;
                *"movewindow"*)
                    direction=$(echo "$action" | grep -o '[lrud]' | head -1)
                    case "$direction" in
                        l) echo "󰁍 Move window left" ;;
                        r) echo "󰁔 Move window right" ;;
                        u) echo "󰁝 Move window up" ;;
                        d) echo "󰁅 Move window down" ;;
                        *) echo "󰁌 Move window" ;;
                    esac ;;
                *"movetoworkspace"*)
                    num=$(echo "$action" | grep -o '[0-9]\+' | head -1)
                    echo "Move window to workspace $num" ;;
                *"workspace"*)
                    num=$(echo "$action" | grep -o '[0-9]\+' | head -1)
                    echo "Switch to workspace $num" ;;
                *"movefocus"*)
                    direction=$(echo "$action" | grep -o '[lrud]' | head -1)
                    case "$direction" in
                        l) echo "Focus window to the left" ;;
                        r) echo "Focus window to the right" ;;
                        u) echo "Focus window above" ;;
                        d) echo "Focus window below" ;;
                    esac ;;
                *"resizeactive"*)
                    echo "Resize active window" ;;
                *"colorpicker"*)
                    echo "Pick color from screen" ;;
                *) echo "$action" ;;
            esac
    esac
}

{
    echo "HYPRLAND KEYBINDINGS"
    echo "Super = Windows/Fn/CMD Key"
    echo ""
} > "$TEMP_FILE"

add_section() {
    local title="$1"
    local pattern="$2"
    
    echo "$title" >> "$TEMP_FILE"
    echo "----------------------------------------" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    
    grep -E "^[[:space:]]*bind[me]? *= *.*$pattern" "$CONFIG_FILE" 2>/dev/null | \
    while IFS= read -r line; do
        key_part=$(echo "$line" | awk -F, '{print $1","$2}')
        action_part=$(echo "$line" | cut -d',' -f3-)
        
        if [ -n "$key_part" ]; then
            formatted_key=$(format_key "$key_part")
            description=$(get_description "$action_part" "$key_part")
            printf "%-40s %s\n" \
                "$formatted_key" \
                "$description" >> "$TEMP_FILE"
        fi
    done
    echo "" >> "$TEMP_FILE"
}

add_section "BASIC CONTROLS" "exec.*\$term|\$browser|\$fileManager|killactive|exit"
add_section "WINDOW MANAGEMENT" "togglefloating|pseudo|togglesplit|fullscreen"
add_section "WORKSPACE CONTROLS" "workspace,|movetoworkspace"
add_section "FOCUS NAVIGATION" "movefocus"
add_section "WINDOW MOVEMENT" "movewindow"
add_section "WINDOW RESIZING" "resizeactive"
add_section "MEDIA CONTROLS" "playerctl|volume|wpctl"
add_section "SCREENSHOTS" "grim|screenshot"
add_section "SYSTEM CONTROLS" "exit|wlogout|suspend|hibernate|poweroff|reboot"

cat "$TEMP_FILE" | rofi \
    -dmenu \
    -theme "/etc/xdg/rofi/themes/keybindings.rasi" \
    -width 800 \
    -height 600 \
    -theme-str 'listview { columns: 1; }' \
    -theme-str 'window { location: center; }' \
    -no-show-icons \
    -mesg "Hyprland Keybindings (press Esc to close)" \
    -no-custom \
    -hover-select \
    -me-select-entry "" \
    -me-accept-entry "MousePrimary"

rm -f "$TEMP_FILE"
'';

    mode = "0755";
};    
#21>[Script-Start-Menu]
"start-menu.sh" = {
text = ''
#!/usr/bin/env bash

if pgrep -x rofi > /dev/null; then
    pkill rofi
    exit 0
fi

# Variables
dir="/etc/xdg/rofi"
theme="start-menu"

# Get system information
host=$(hostname)
uptime=$(uptime | sed 's/.*up \([^,]*\),.*/\1/')
cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
memory_info=$(free -m | awk 'NR==2{printf "%.1f/%.1fGB", $3/1024, $2/1024}')
disk_usage=$(df -h / | awk 'NR==2{print $5}')
kernel_ver=$(uname -r)
os_ver=$(nixos-version)

# Rofi CMD


rofi_cmd() {
    rofi -dmenu \
        -theme "''${dir}/themes/''${theme}.rasi" \
        -p "󱄅 Welcome, ${username}" \
        -mesg "CPU: ''${cpu_usage}% | RAM: ''${memory_info} | DISK: ''${disk_usage}"
}

# Menu Options
gen_list() {
    echo -e "󰣆      All Applications"
    echo -e "󰆍      Terminal"
    echo -e "󰈹      Web Browser"
    echo -e "󱂵      Home"
    echo -e "󰈙      Documents"
    echo -e "󰉍      Downloads"
    echo -e "󰋩      Pictures"
    echo -e "󰒓      Settings"
    echo -e "󰌌      Keybindings"
    echo -e "󱑥      System Monitor"
    echo -e "󰍃      Log Out"
    echo -e "󰤄      Suspend"
    echo -e "󰜉      Restart"
    echo -e "󰐥      Shutdown"
}

# Execute Command

run_cmd() {
  selected="$(gen_list | rofi_cmd)"
  if [ -n "$selected" ]; then
        case "''${selected}" in
        *"All Applications"*) /etc/wofi-toggle.sh drun ;;
        *"Terminal"*) alacritty ;;
        *"Web Browser"*) firefox ;;
        *"Home"*) pcmanfm ~ ;;
        *"Documents"*) pcmanfm ~/Documents ;;
        *"Downloads"*) pcmanfm ~/Downloads ;;
        *"Pictures"*) pcmanfm ~/Pictures ;;
        *"Settings"*) pcmanfm ~/.config ;;
        *"Keybindings"*) /etc/hypr-binds.sh ;;
        *"System Monitor"*) alacritty -e btop ;;
        *"Log Out"*) loginctl terminate-user ${username} ;;
        *"Suspend"*) systemctl suspend ;;
        *"Restart"*) systemctl reboot ;;
        *"Shutdown"*) systemctl poweroff ;;
    esac
  fi
}

run_cmd


'';
mode = "0755";
};

#21>[Script-Notification]
"notification.sh" = {
    text = ''

#!/bin/sh
if [ "$1" = "watch-blueman" ]; then
  while true; do
    # Look for any blueman notification window
    window_info=$(${pkgs.wmctrl}/bin/wmctrl -l | grep -i "blueman")
    if [ -n "$window_info" ]; then
      window_id=$(echo "$window_info" | awk '{print $1}')
      window_title=$(echo "$window_info" | cut -d' ' -f5-)
      ${pkgs.wmctrl}/bin/wmctrl -i -c "$window_id"
      /etc/notification.sh "Bluetooth" "$window_title"
    fi
    sleep 1
  done
  exit 0
fi
LOCK_FILE="/tmp/notification.lock"
QUEUE_DIR="/tmp/notifications"
NOTIFICATION_TIMEOUT=5000  # Default timeout in milliseconds

# Parse notify-send compatible arguments
while [ $# -gt 0 ]; do
    case "$1" in
        -t|--expire-time)
            NOTIFICATION_TIMEOUT="$2"
            shift 2
            ;;
        -u|--urgency)
            # Store urgency but don't use it yet
            URGENCY="$2"
            shift 2
            ;;
        -i|--icon)
            # Store icon but don't use it yet
            ICON="$2"
            shift 2
            ;;
        -a|--app-name)
            APP_NAME="$2"
            shift 2
            ;;
        *)
            if [ -z "$SUMMARY" ]; then
                SUMMARY="$1"
            else
                BODY="$1"
            fi
            shift
            ;;
    esac
done

# Construct the message
if [ -n "$BODY" ]; then
    MESSAGE="$SUMMARY\n$BODY"
else
    MESSAGE="$SUMMARY"
fi

# Add app name if present
if [ -n "$APP_NAME" ]; then
    MESSAGE="$APP_NAME: $MESSAGE"
fi

show_notification() {
    local message="$1"
    local timeout="$2"
    
    touch "$LOCK_FILE"
    
    SCREEN_INFO=$(hyprctl monitors -j | jq '.[0]')
    SCREEN_WIDTH=$(echo "$SCREEN_INFO" | jq '.width')
    SCREEN_HEIGHT=$(echo "$SCREEN_INFO" | jq '.height')
    
    NOTIFICATION_WIDTH=300
    NOTIFICATION_HEIGHT=100
    
    X=$((SCREEN_WIDTH - NOTIFICATION_WIDTH - 20))
    Y=$((SCREEN_HEIGHT - NOTIFICATION_HEIGHT - 20))
    
    (
        echo "$message" | rofi \
            -normal-window \
            -dmenu \
            -theme "/etc/xdg/rofi/themes/notification.rasi" \
            -theme-str "window { width: $NOTIFICATION_WIDTH; height: $NOTIFICATION_HEIGHT; }" \
            -no-fixed-num-lines \
            -window-title "notification" \
            &
        
        NOTIFICATION_PID=$!
        
        (
            sleep $((timeout/1000))
            kill $NOTIFICATION_PID 2>/dev/null
            rm -f "$LOCK_FILE"
            
            # Process next notification in queue
            NEXT_FILE=$(ls "$QUEUE_DIR" 2>/dev/null | head -n 1)
            if [ -n "$NEXT_FILE" ]; then
                NEXT_CONTENT=$(cat "$QUEUE_DIR/$NEXT_FILE")
                rm -f "$QUEUE_DIR/$NEXT_FILE"
                show_notification "$NEXT_CONTENT" "$NOTIFICATION_TIMEOUT"
            fi
        ) &
    ) &
}

# Queue or show notification
if [ -f "$LOCK_FILE" ]; then
    # Generate unique filename for queued notification
    QUEUE_FILE="$QUEUE_DIR/notification_$(date +%s%N)"
    echo "$MESSAGE" > "$QUEUE_FILE"
else
    show_notification "$MESSAGE" "$NOTIFICATION_TIMEOUT"
fi

    
    '';
    mode = "0755";
}; 

#21>[Script-Right-Click-Menu]
"right_click_menu.sh" = {
    text = ''
#!/bin/sh

LOCK_FILE="/tmp/window-menu.lock"

cleanup() {
    rm -f "$LOCK_FILE"
    pkill -f "wofi.*dmenu"
}

if [ -f "$LOCK_FILE" ]; then
    cleanup
    exit 0
fi

CURSOR_POS=$(hyprctl cursorpos)
X=$(echo $CURSOR_POS | cut -d',' -f1)
Y=$(echo $CURSOR_POS | cut -d',' -f2)

WINDOW_INFO=$(hyprctl clients -j | jq -r ".[] | select(.at[0] <= $X and .at[1] <= $Y and 
    .at[0] + .size[0] >= $X and .at[1] + .size[1] >= $Y)")

if [ -n "$WINDOW_INFO" ]; then
    WINDOW_ADDR=$(echo "$WINDOW_INFO" | jq -r '.address')
    IS_FULLSCREEN=$(echo "$WINDOW_INFO" | jq -r '.fullscreen')
    
    touch "$LOCK_FILE"
    
    if [ "$IS_FULLSCREEN" = "true" ]; then
        MENU_ITEMS="Close\nMinimize\nDe-focus"
    else
        MENU_ITEMS="Close\nMinimize\nFocus"
    fi

    SCREEN_INFO=$(hyprctl monitors -j | jq '.[0]')
    SCREEN_WIDTH=$(echo "$SCREEN_INFO" | jq '.width')
    SCREEN_HEIGHT=$(echo "$SCREEN_INFO" | jq '.height')

    MENU_WIDTH=150
    MENU_HEIGHT=100

    if [ $((X + MENU_WIDTH)) -gt "$SCREEN_WIDTH" ]; then
        X=$((SCREEN_WIDTH - MENU_WIDTH - 20))
    fi
    if [ $((Y + MENU_HEIGHT)) -gt "$SCREEN_HEIGHT" ]; then
        Y=$((SCREEN_HEIGHT - MENU_HEIGHT - 20))
    fi

    selected=$(printf "$MENU_ITEMS" | wofi \
        --dmenu \
        --cache-file /dev/null \
        --width 150 \
        --height 100 \
        --hide-scroll \
        --no-actions \
        --style /etc/xdg/wofi/right-click-style.css \
        --normal-window \
        --lines 4 \
        --hide-search \
        --prompt="" \
        --layer top \
        --geometry "$X,$Y" \
        --define window_title="right-click-menu" \
        --define search_triggered=false \
        --define early_exit=true \
        --define immediate_activation=true \
        --define single_click=true)

    case "$selected" in
        "Close")
            hyprctl dispatch killactive address:$WINDOW_ADDR
            ;;
        "Minimize")
            /etc/minimize-manager.sh minimize "address:$WINDOW_ADDR"
            ;;
        "Focus")
            hyprctl dispatch fullscreen 1 address:$WINDOW_ADDR
            ;;
        "De-focus")
            hyprctl dispatch fullscreen 0 address:$WINDOW_ADDR
            ;;
    esac
fi

cleanup
    
'';
    mode = "0755";
};

#21>[Script-Wofi-Toggle]
"wofi-toggle.sh" = {
    text = ''
      #!/bin/sh
      
      cleanup_wofi() {
        pkill -f "wofi --show drun"
        pkill -f "wofi --show dmenu"
        rm -f "/run/user/$(id -u)/wofi-*.lock" 2>/dev/null
      }
      
      trap cleanup_wofi EXIT
      
      case "$1" in
          "minimize")
              CACHE_DIR="/run/user/$(id -u)"
              CACHE_FILE="''${CACHE_DIR}/minimized_windows.json"
              MENU_FILE="''${CACHE_DIR}/wofi_menu.txt"
              LOCK_FILE="''${CACHE_DIR}/wofi-minimize.lock"
              
              if [ -f "$LOCK_FILE" ]; then
                cleanup_wofi
                exit 0
              fi
              
              touch "$LOCK_FILE"
              
              mkdir -p "''${CACHE_DIR}"
              
              {
                  if [ -f "''${CACHE_FILE}" ] && [ -s "''${CACHE_FILE}" ]; then
                      ${pkgs.jq}/bin/jq -r '.[].display_title' "''${CACHE_FILE}"
                      echo "Restore All Windows"
                  fi
              } > "''${MENU_FILE}"
              
              selected=$(wofi \
                   --show dmenu \
                   --width 800 \
                   --height 600 \
                   --prompt "Minimized Windows" \
                   --cache-file /dev/null \
                   --insensitive \
                   --allow-images \
                   --style /etc/xdg/wofi/minimize-style.css \
                   --hide-scroll \
                   --define search_triggered=false \
                   --define early_exit=true \
                   --define immediate_activation=true \
                   --define single_click=true \
                   < "''${MENU_FILE}")
              
              if [ -n "''${selected}" ]; then
                  if [ "''${selected}" = "Restore All Windows" ]; then
                      ${pkgs.jq}/bin/jq -r '.[].address' "''${CACHE_FILE}" | while read -r addr; do
                          /etc/minimize-manager.sh restore "''${addr}"
                      done
                  else
                      window_id=$(${pkgs.jq}/bin/jq -r --arg title "''${selected}" '.[] | select(.display_title == $title) | .address' "''${CACHE_FILE}")
                      if [ -n "''${window_id}" ]; then
                          /etc/minimize-manager.sh restore "''${window_id}"
                      fi
                  fi
              fi
              
              rm -f "''${MENU_FILE}" "''${LOCK_FILE}"
              ;;
              
          "drun")
              LOCK_FILE="/run/user/$(id -u)/wofi-drun.lock"
              
              if [ -f "$LOCK_FILE" ]; then
                cleanup_wofi
                exit 0
              fi
              
              touch "$LOCK_FILE"
              
              wofi --show drun \
                   --width 500 \
                   --height 400 \
                   --prompt "Applications" \
                   --normal-window \
                   --allow-images \
                   --insensitive \
                   --cache-file /dev/null \
                   --hide-scroll \
                   --no-actions \
                   --matching contains
              
              rm -f "$LOCK_FILE"
              ;;
      esac
    '';
    mode = "0755";
  };
#21>[Script-Minimize-Manager]
  "minimize-manager.sh" = {
    text = ''
      #!/bin/sh
      
      # Enhanced cache structure in RAM
      CACHE_DIR="/run/user/$(id -u)"
      CACHE_FILE="$CACHE_DIR/minimized_windows.json"
      PREVIEW_DIR="$CACHE_DIR/window_previews"
      HISTORY_FILE="$CACHE_DIR/window_history.json"
      GROUP_FILE="$CACHE_DIR/window_groups.json"

      mkdir -p "$CACHE_DIR" "$PREVIEW_DIR"

      for file in "$CACHE_FILE" "$HISTORY_FILE" "$GROUP_FILE"; do
        if [ ! -f "$file" ] || ! jq empty "$file" 2>/dev/null; then
          echo '[]' > "$file"
        fi
      done

      capture_preview() {
        local window_id="$1"
        local preview_file="$PREVIEW_DIR/$window_id.png"
        
        local geometry=$(hyprctl clients -j | jq -r ".[] | select(.address == \"$window_id\") | \"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])\"")
        
        if [ -n "$geometry" ]; then
          # Capture window screenshot
          grim -g "$geometry" "$preview_file"
          # Create thumbnail
          convert "$preview_file" -resize 200x150^ -gravity center -extent 200x150 "$PREVIEW_DIR/$window_id.thumb.png"
          rm "$preview_file"
        fi
      }

      add_to_history() {
        local window_info="$1"
        local timestamp=$(date +%s)
        
        window_info=$(echo "$window_info" | jq --arg ts "$timestamp" '. + {timestamp: $ts}')
        
        jq --argjson win "$window_info" '. + [$win] | .[-50:]' "$HISTORY_FILE" > "$HISTORY_FILE.tmp"
        mv "$HISTORY_FILE.tmp" "$HISTORY_FILE"
      }

      manage_group() {
        local action="$1"
        local class="$2"
        local window_id="$3"
        
        case "$action" in
          "add")
            jq --arg class "$class" --arg win "$window_id" '
              if .[] | select(.[0] == $class) then
                map(if .[0] == $class then .[1] += [$win] else . end)
              else
                . + [[$class, [$win]]]
              end
            ' "$GROUP_FILE" > "$GROUP_FILE.tmp"
            mv "$GROUP_FILE.tmp" "$GROUP_FILE"
            ;;
          "remove")
            jq --arg class "$class" --arg win "$window_id" '
              map(if .[0] == $class then [.[0], (.[1] - [$win])] else . end) |
              map(select(.[1] != []))
            ' "$GROUP_FILE" > "$GROUP_FILE.tmp"
            mv "$GROUP_FILE.tmp" "$GROUP_FILE"
            ;;
        esac
      }

      case "$1" in
        "minimize")
          window_info=$(hyprctl activewindow -j)
          if [ $? -eq 0 ] && [ -n "$window_info" ] && [ "$(echo "$window_info" | jq -r '.class')" != "null" ]; then
            class_name=$(echo "$window_info" | jq -r '.class')
            
            if [ "$class_name" = "wofi" ]; then
              exit 1
            fi
            
            app_icon=$(get_app_icon "$class_name")
            window_title=$(echo "$window_info" | jq -r '.title')
            window_addr=$(echo "$window_info" | jq -r '.address')
            short_addr=$(echo "$window_addr" | tail -c 5)
            display_title="$app_icon $class_name - $window_title [$short_addr]"
            
            window_info=$(echo "$window_info" | jq --arg title "$display_title" --arg icon "$app_icon" \
              '{address: .address, display_title: $title, class: .class, icon: $icon, original_title: .title}')
            
            capture_preview "$window_addr"
            
            manage_group "add" "$class_name" "$window_addr"
            
            add_to_history "$window_info"
           
            if hyprctl dispatch movetoworkspacesilent special:minimum,address:$window_addr; then
              if [ -s "$CACHE_FILE" ]; then
                echo "$window_info" | jq -s ". + $(cat "$CACHE_FILE")" > "$CACHE_FILE.tmp"
              else
                echo "$window_info" | jq -s > "$CACHE_FILE.tmp"
              fi
              mv "$CACHE_FILE.tmp" "$CACHE_FILE"
              
              hyprctl dispatch animation window:minimize,$window_addr
              
              pkill -RTMIN+8 waybar
            fi
          fi
          ;;

        "show")
          if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
            minimized=$(cat "$CACHE_FILE")
            count=$(echo "$minimized" | jq 'length')
            groups=$(cat "$GROUP_FILE")
            
            if [ "$count" -eq 0 ]; then
              echo "{\"text\":\"󰘸\",\"class\":\"empty\",\"tooltip\":\"No minimized windows\"}"
            else
              tooltip=$(jq -r '
                reduce .[] as $group (
                  "";
                  . + "\n" + ($group[0] + ":\n" + ($group[1] | map("  • " + .) | join("\n")))
                )' "$GROUP_FILE")
              
              echo "{\"text\":\"󰘸 $count\",\"class\":\"has-windows\",\"tooltip\":\"$tooltip\"}"
            fi
          else
            echo "{\"text\":\"󰘸\",\"class\":\"empty\",\"tooltip\":\"No minimized windows\"}"
          fi
          ;;

"restore")
          window_id="$2"
          if [ -n "$window_id" ]; then
            # Get window class for group management
            class_name=$(jq -r --arg addr "$window_id" '.[] | select(.address == $addr) | .class' "$CACHE_FILE")
            
            current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
            
            if hyprctl clients -j | jq -e ".[] | select(.address == \"$window_id\")" >/dev/null; then
              # Trigger restore animation
              hyprctl dispatch animation window:restore,$window_id
              
              # Move window to current workspace
              if hyprctl dispatch movetoworkspace "$current_ws,address:$window_id"; then
                hyprctl dispatch focuswindow "address:$window_id"
                
                manage_group "remove" "$class_name" "$window_id"
                
                jq "map(select(.address != \"$window_id\"))" "$CACHE_FILE" > "$CACHE_FILE.tmp"
                mv "$CACHE_FILE.tmp" "$CACHE_FILE"
                
                rm -f "$PREVIEW_DIR/$window_id.thumb.png"
                
                pkill -RTMIN+8 waybar
              fi
            else
              # clean up if window no longer exists
              manage_group "remove" "$class_name" "$window_id"
              jq "map(select(.address != \"$window_id\"))" "$CACHE_FILE" > "$CACHE_FILE.tmp"
              mv "$CACHE_FILE.tmp" "$CACHE_FILE"
              rm -f "$PREVIEW_DIR/$window_id.thumb.png"
              pkill -RTMIN+8 waybar
            fi
          fi
          ;;

        "restore-group")
          class_name="$2"
          if [ -n "$class_name" ]; then
            # Get all windows in group
            windows=$(jq -r --arg class "$class_name" '.[] | select(.[0] == $class) | .[1][]' "$GROUP_FILE")
            
            current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
            
            echo "$windows" | while read -r window_id; do
              hyprctl dispatch animation window:restore,$window_id
              hyprctl dispatch movetoworkspace "$current_ws,address:$window_id"
              
              # Remove from cache and clean up
              jq "map(select(.address != \"$window_id\"))" "$CACHE_FILE" > "$CACHE_FILE.tmp"
              mv "$CACHE_FILE.tmp" "$CACHE_FILE"
              rm -f "$PREVIEW_DIR/$window_id.thumb.png"
            done
            
            # Remove group
            jq --arg class "$class_name" 'map(select(.[0] != $class))' "$GROUP_FILE" > "$GROUP_FILE.tmp"
            mv "$GROUP_FILE.tmp" "$GROUP_FILE"
            
            pkill -RTMIN+8 waybar
          fi
          ;;

        "minimize-group")
          class_name="$2"
          if [ -n "$class_name" ]; then
            # Get all visible windows of the class
            hyprctl clients -j | jq -r ".[] | select(.class == \"$class_name\") | .address" | while read -r window_id; do
              # Use existing minimize logic
              $0 minimize "$window_id"
            done
          fi
          ;;
    esac
    '';
 mode = "0755";
    user = "root";
    group = "wheel";
  };


#21>[Script-Nixian-Jump]

"nixian-jump.sh" = {
    text = ''
      #!/bin/sh
      
      if [ "$(id -u)" = "0" ]; then
          REAL_USER="${username}"
          REAL_USER_ID=$(id -u $REAL_USER)
          
          REAL_USER_WAYLAND_DISPLAY=$(su - $REAL_USER -c 'echo $WAYLAND_DISPLAY')
          REAL_USER_XDG_RUNTIME_DIR="/run/user/$REAL_USER_ID"
          
          exec sudo -H -u $REAL_USER \
              WAYLAND_DISPLAY="$REAL_USER_WAYLAND_DISPLAY" \
              XDG_RUNTIME_DIR="$REAL_USER_XDG_RUNTIME_DIR" \
              DISPLAY=:0 \
              "$0" "$@"
      fi          

if ! pgrep -x "ydotoold" > /dev/null; then
  echo "ydotoold is not running. Starting it..."
  systemctl --user start ydotool
  sleep 1
fi

CONFIG_FILE="/etc/nixos/configuration.nix"

show_menu() {
  local prompt_text="$1"
  
  {
    grep -n "^#[0-9]\+\[\(.*\)\]" "$CONFIG_FILE" | \
    sed 's/:#\([0-9]*\)\[\(.*\)\]/|\1|\2/' | \
    awk -F'|' '{printf "%s|%s\n", $1, $3}'
    
    grep -n "^#[0-9]\+>\[\(.*\)\]" "$CONFIG_FILE" | \
    sed 's/:#\([0-9]*\)>\[\(.*\)\]/|\1|    ┗━ \2/' | \
    awk -F'|' '{printf "%s|%s\n", $1, $3}'
    
  } | sort -n | \
    column -t -s'|' | \
    rofi -dmenu \
         -p "$prompt_text" \
         -theme-str '
            window {
                width: 800px;
                height: 600px;
                location: center;
                anchor: center;
                transparency: "real";
                background-color: #2E3440;
                border: 3px solid;
                border-color: #4C566A;
                border-radius: 12px;
            }
            mainbox {
                background-color: transparent;
                children: [inputbar, listview];
            }
            inputbar {
                padding: 0px;
                margin: 0px 0px 20px 0px;
                background-color: #3B4252;
                text-color: #ECEFF4;
                border-radius: 8px;
                border: 1px solid;
                border-color: #4C566A;
                children: [prompt, textbox-prompt-colon, entry];
            }
            prompt {
                enabled: true;
                padding: 12px;
                background-color: transparent;
                text-color: inherit;
            }
            textbox-prompt-colon {
                expand: false;
                str: "";
                padding: 12px;
                text-color: inherit;
            }
            entry {
                padding: 12px;
                background-color: transparent;
                text-color: inherit;
                placeholder: "Search sections...";
                placeholder-color: #4C566A;
            }
            listview {
                columns: 1;
                lines: 10;
                scrollbar: true;
                padding: 10px;
                background-color: transparent;
                border: 0px;
            }
            scrollbar {
                width: 4px;
                padding: 0;
                handle-width: 8px;
                border: 0;
                handle-color: #4C566A;
            }
            element {
                padding: 12px;
                background-color: transparent;
                text-color: #ECEFF4;
                border-radius: 8px;
            }
            element normal.normal {
                background-color: transparent;
                text-color: #ECEFF4;
            }
            element alternate.normal {
                background-color: transparent;
                text-color: #ECEFF4;
            }
            element selected.normal {
                background-color: #3B4252;
                text-color: #88C0D0;
                border: 1px solid;
                border-color: #4C566A;
            }
            element-text {
                background-color: transparent;
                text-color: inherit;
                highlight: bold #88C0D0;
            }
         ' \
         -matching fuzzy \
         -i \
         -no-custom \
         -hover-select \
         -me-select-entry "" \
         -me-accept-entry "MousePrimary"
}

simulate_keys() {
    local line_number="$1"
    
    if [ -n "$SUDO_USER" ]; then
        REAL_USER_ID=$(id -u "$SUDO_USER")
        REAL_USER_WAYLAND_DISPLAY=$(ps e -u "$SUDO_USER" | grep -m 1 "WAYLAND_DISPLAY=" | sed 's/.*WAYLAND_DISPLAY=\([^ ]*\).*/\1/')
        REAL_USER_XDG_RUNTIME_DIR="/run/user/$REAL_USER_ID"

        sudo -u "$SUDO_USER" \
            WAYLAND_DISPLAY="$REAL_USER_WAYLAND_DISPLAY" \
            XDG_RUNTIME_DIR="$REAL_USER_XDG_RUNTIME_DIR" \
            DISPLAY=:0 \
            ${pkgs.ydotool}/bin/ydotool type "$line_number"
        
        
        sudo -u "$SUDO_USER" \
            WAYLAND_DISPLAY="$REAL_USER_WAYLAND_DISPLAY" \
            XDG_RUNTIME_DIR="$REAL_USER_XDG_RUNTIME_DIR" \
            DISPLAY=:0 \
            ${pkgs.ydotool}/bin/ydotool type "G"
    else
        # Normal user execution
        ${pkgs.ydotool}/bin/ydotool type "$line_number"
        ${pkgs.ydotool}/bin/ydotool type "G"
    fi
}

if [ ! -r "$CONFIG_FILE" ]; then
  echo "Error: Cannot read $CONFIG_FILE"
  exit 1
fi

selection=$(show_menu "Jump to section")

if [ -n "$selection" ]; then
  line_number=$(echo "$selection" | awk '{print $1}')
  
  if [ -n "$line_number" ]; then
    simulate_keys "$line_number"
  fi
fi
    '';
    mode = "0755"; 
    user = "root";
    group = "wheel";
};

#21>[Script-Brightness-Control]
"brightness-control.sh" = {
    text = ''
      #!/bin/sh
      
      set -e  # Exit on error
      
      NIGHT_MODE_DIR="/run/user/$(id -u)/night-mode"
      NIGHT_MODE_FILE="$NIGHT_MODE_DIR/status"
      
      mkdir -p "$NIGHT_MODE_DIR"
      
      exec 1> >(tee -a "/tmp/brightness-debug.log")
      exec 2>&1
      echo "Starting brightness adjustment: $1"
      
      get_current_mode() {
        echo "Getting current mode..."
        if [ -f "$NIGHT_MODE_FILE" ]; then
          cat "$NIGHT_MODE_FILE" 2>/dev/null | grep -o '"class":"[^"]*"' | cut -d'"' -f4
        else
          echo "day"
        fi
      }
      
      get_mode_icon() {
        case "$(get_current_mode)" in
          "day") echo "󰖨" ;;
          "night") echo "󰖔" ;;
          "deep-night") echo "🌑" ;;
          *) echo "󰖨" ;;
        esac
      }
      
      adjust_brightness() {
        direction=$1
        echo "Getting current brightness..."
        current_brightness=$(${pkgs.brightnessctl}/bin/brightnessctl get)
        echo "Current brightness: $current_brightness"
        
        echo "Getting max brightness..."
        max_brightness=$(${pkgs.brightnessctl}/bin/brightnessctl max)
        echo "Max brightness: $max_brightness"
        
        current_percent=$((current_brightness * 100 / max_brightness))
        echo "Current percentage: $current_percent%"
        
        if [ "$direction" = "up" ]; then
          echo "Increasing brightness..."
          ${pkgs.brightnessctl}/bin/brightnessctl set 5%+ >/dev/null 2>&1
        elif [ "$direction" = "down" ] && [ $current_percent -gt 5 ]; then
          echo "Decreasing brightness..."
          ${pkgs.brightnessctl}/bin/brightnessctl set 5%- >/dev/null 2>&1
        fi
        
        new_brightness=$(${pkgs.brightnessctl}/bin/brightnessctl get)
        new_percent=$((new_brightness * 100 / max_brightness))
        echo "New brightness percentage: $new_percent%"
        
        icon=$(get_mode_icon)
        mode_text=$(get_current_mode | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++)sub(/./,toupper(substr($i,1,1)),$i)}1')
        output=$(printf '{"text": "%s", "class": "%s", "tooltip": "%s Mode\nBrightness: %d%%"}\n' \
          "$icon" \
          "$(get_current_mode)" \
          "$mode_text" \
          "$new_percent")
        
        echo "Writing to status file: $output"
        echo "$output" > "$NIGHT_MODE_FILE"
        
        echo "Sending signal to waybar..."
        pkill -RTMIN+8 waybar || true
      }
      
      case "$1" in
        "up"|"down") adjust_brightness "$1" ;;
        *) echo "Usage: $0 [up|down]" >&2; exit 1 ;;
      esac
    '';
    mode = "0755";
    user = "root";
    group = "wheel";
};
#21>[Script-Night-Mode]
 "toggle-night-mode.sh" = {
    text = ''
      #!/bin/sh
      set -euo pipefail

      NIGHT_MODE_DIR="/run/user/$(id -u)/night-mode"
      NIGHT_MODE_FILE="$NIGHT_MODE_DIR/status"

      mkdir -p "$NIGHT_MODE_DIR"
      chmod 755 "$NIGHT_MODE_DIR"
      
      output_status() {
          local status="$1"
          local brightness="$(${pkgs.brightnessctl}/bin/brightnessctl get -m | grep -oE '[0-9]+%')"
          case "$status" in
              0) echo '{"text": "󰖨", "class": "day", "tooltip": "Day Mode\nBrightness: '"$brightness"'"}' ;;
              1) echo '{"text": "󰖔", "class": "night", "tooltip": "Night Mode\nBrightness: '"$brightness"'"}' ;;
              2) echo '{"text": "🌑", "class": "deep-night", "tooltip": "Deep Night Mode\nBrightness: '"$brightness"'"}' ;;
              *) echo '{"text": "󰖨", "class": "day", "tooltip": "Day Mode\nBrightness: '"$brightness"'"}' ;;
          esac
      }
            
      if [ ! -f "$NIGHT_MODE_FILE" ]; then
          echo "0" > "$NIGHT_MODE_FILE"
          chmod 644 "$NIGHT_MODE_FILE"
      fi

      if [ $# -eq 0 ]; then
          CURRENT_STATUS=$(cat "$NIGHT_MODE_FILE" 2>/dev/null || echo "0")
          output_status "$CURRENT_STATUS"
          exit 0
      fi

      CURRENT_STATUS=$(cat "$NIGHT_MODE_FILE" 2>/dev/null || echo "0")

      if [ "$1" = "right_click" ]; then
          NEW_STATUS="2"
      else
          case "$CURRENT_STATUS" in
              0) NEW_STATUS="1" ;;
              1) NEW_STATUS="0" ;;
              2) NEW_STATUS="0" ;;
              *) NEW_STATUS="1" ;;
          esac
      fi

      pkill -f wlsunset || true

      case "$NEW_STATUS" in
          0) 
              output_status "0"
              ;;
          1) 
              ${pkgs.wlsunset}/bin/wlsunset -T 4000 -t 2500 &
              output_status "1"
              ;;
          2) 
              ${pkgs.wlsunset}/bin/wlsunset -T 2500 -t 1500 &
              output_status "2"
              ;;
      esac

      echo "$NEW_STATUS" > "$NIGHT_MODE_FILE"

      pkill -RTMIN+8 waybar || true
    '';
    mode = "0755";
  };

  
#21>[Script-Gif-recorder]
"record-gif.sh" = {
    text = ''
      #!/bin/sh
      
      # Create unique filenames based on timestamp
      output=$(date +'%Y-%m-%d_%H-%M-%S_recording.mp4')
      echo "Starting recording to $output" >> /tmp/record-gif.log
      
      # Record the video using wf-recorder
      wf-recorder -g "$(slurp)" -f "$output" &
      echo $! > /tmp/wf-recorder.pid
      wait $!
      echo "Recording stopped" >> /tmp/record-gif.log
      
      # Convert to GIF with optimizations:
      # 1. Generate an optimal color palette for better compression
      # 2. Reduce colors to 256 (GIF limitation) in the most effective way
      # 3. Use dithering to maintain visual quality while reducing file size
      ffmpeg -i "$output" \
        -vf "fps=10,scale=1024:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=256:reserve_transparent=0[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
        -loop 0 \
        output.gif
        
      echo "Converted to GIF" >> /tmp/record-gif.log
      
      # Optional: Further optimize the GIF using gifsicle
      gifsicle -O3 output.gif -o output_optimized.gif
    '';
    mode = "0755";
  };
#21>[Script-Clipboard]
    "clipboard-wrapper.sh" = {
      text = ''
        #!/bin/sh
        if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
          case "$1" in
            copy) wl-copy ;;
            paste) wl-paste ;;
            *) echo "Unknown command: $1" >&2; exit 1 ;;
          esac
        else
          case "$1" in
            copy) xclip -selection clipboard ;;
            paste) xclip -selection clipboard -o ;;
            *) echo "Unknown command: $1" >&2; exit 1 ;;
          esac
        fi
      '';
      mode = "0755";
    };
     
#21>[Script-Helix-Config]
    "helix/config.toml".text = ''
      theme = "resting_night_owl"

      [editor]
      auto-info = true
      auto-save = true
      auto-pairs = true
      color-modes = true
      cursorline = true
      true-color = true
      undercurl = true
      line-number = "relative"
      bufferline = "multiple"
      popup-border = "all"
      completion-timeout = 10
      completion-trigger-len = 1

      [editor.cursor-shape]
      insert = "bar"
      normal = "block"
      select = "underline"

      [editor.lsp]
      enable = true
      display-messages = true
      display-inlay-hints = true
      
      [editor.indent-guides]
      character = "╎"
      render = true
      
      [editor.file-picker]
      hidden = true
      
      [keys.normal]
      S-j = ["extend_to_line_bounds", "delete_selection", "paste_after"]
      S-k = ["extend_to_line_bounds", "delete_selection", "move_line_up", "paste_before"]
      up = "no_op"
      down = "no_op"
      left = "no_op"
      right = "no_op"
      "`" =  [":write-all"]
      
      [keys.insert]
      "esc" = ["normal_mode"]
      up = "no_op"
      down = "no_op"
      left = "no_op"
      right = "no_op"
      "`" =  [":write-all"]

      [keys.normal.space]
      u = [":sh hx-jump"]
      r = [":write-all", ":sh alacritty -e fish -c 'cargo run'"]
    '';
#21>[Script-Helix-Languages]
    "helix/languages.toml".text = ''
      [[language]]
      name = "rust"
      scope = "source.rust"
      file-types = ["rs"]
      roots = ["Cargo.toml", "Cargo.lock"]
      auto-format = true
      language-server = { command = "/run/current-system/sw/bin/rust-analyzer" }
      formatter = { command = "rustfmt" }
      
      [language.auto-pairs]
      '(' = ')'
      '{' = '}'
      '[' = ']'
      '`' = '`'
      '<' = '>'
      
      [language.config.rust-analyzer]
      cargo = { features = "all" }
      checkOnSave = { command = "clippy", extraArgs = ["--", "-Z", "unstable-options"] }
      procMacro = { enable = true }
      cargo.allFeatures = true
      checkOnSave.allFeatures = true
      rustc.source = "discover"
      diagnostics.unstable = true
      cargo.buildScripts.enable = true
      
      [language-server.rust-analyzer.config.check]
      command = "clippy"
      
      [[language]]
      name = "python"
      scope = "source.python"
      file-types = ["py", "pyi", "pyc", "pyd", "pyw"]
      roots = ["pyproject.toml", "setup.py", "requirements.txt", "poetry.lock"]
      auto-format = true
      language-servers = ["pyright", "ruff", "pylyzer"]
      
      [language-server.pyright.config.python.analysis]
      typeCheckingMode = "basic"
      
      [language-server.ruff]
      command = "ruff"
      args = ["server"]
      
      [language-server.pylyzer]
      command = "pylyzer"
      args = ["--server"]

      [[language]]
      name = "nix"
      scope = "source.nix"
      file-types = ["nix"]
      roots = ["flake.nix", "shell.nix", "default.nix"]
      comment-token = "#"
      auto-format = true
      formatter = { command = "/run/current-system/sw/bin/nixpkgs-fmt" }
      language-server = { command = "rnix-lsp" }
      
      [language.auto-pairs]
      '(' = ')'
      '{' = '}'
      '[' = ']'
      '"' = '"'
      '`' = '`'
    '';

#21>[Script-Helix-Themes]
    "helix/themes/resting_night_owl.toml".text = ''
      inherits = "night_owl"

      "ui.virtual" = { fg = "faint-blue" }
      "type" = { fg = "#1e720d" }
      "variable.builtin" = { fg = "#30b715", modifiers = ["italic"] }
      "warning" = { fg = "peach", modifiers = ["dim"] }
      "error" = { fg = "red", modifiers = ["dim"] }
      "info" = { fg = "blue", modifiers = ["dim"] }
      "hint" = { fg = "paleblue", modifiers = ["dim"] }

      [diagnostic]
      error = { underline = { color = "apricot", style = "curl" }, modifiers = ["italic", "bold"] }
      warning = { underline = { color = "lightning", style = "curl" }, modifiers = ["italic", "bold"] }
      info = { underline = { color = "delta", style = "curl" }, modifiers = ["italic", "bold"] }
      hint = { underline = { color = "#afdbcc", style = "curl" }, modifiers = ["italic", "bold"] }

      [palette]
      apricot = "#f47868"
      lightning = "#ffcd1c"
      delta = "#6F44F0"
      faint-blue = "#154c79"
    '';

#21>[Script-Fish-Tab-Complete]
    "fish/functions/custom_tab_complete.fish".text = ''
      function custom_tab_complete
        if commandline -P
          if test -z (commandline)
            complete
          else
            commandline -f complete-and-search
          end
        else
          if test -z (commandline)
            complete
          else if not commandline -P
            commandline -f end-of-line
          else
            if test -n "$fish_autosuggestion"
              commandline -f accept-autosuggestion
            else
              commandline -f complete-and-search
            end
          end
        end
      end
    '';

#21>[Script-Fish-Keybindings]
    "fish/fish_user_key_bindings.fish".text = ''
      function fish_user_key_bindings
        bind --erase --preset \t
        bind \t custom_tab_complete
        bind \e\t complete
        bind --erase --preset \ef
      end
    '';

    # cd /home/${username}/
#21>[Script-Fish-Config]
"fish/config.fish".text = ''
  if status is-interactive
    if type -q ayu_load_theme
      set --universal ayu_variant mirage
      ayu_load_theme
    end

    # Zellij setup
    if type -q zellij
      eval (zellij setup --generate-auto-start fish | string collect)
    end

    source /etc/fish/fish_user_key_bindings.fish
    source /etc/fish/functions/custom_tab_complete.fish

    set -g fish_autosuggestion_enabled 1
    set -g fish_complete_path $fish_complete_path ~/.config/fish/completions
  end
'';

#21>[Script-Fish-Variables]
    "fish/fish_variables".text = ''
      # This file contains fish universal variable definitions.
      # VERSION: 3.0
      SETUVAR __fish_initialized:3400
      SETUVAR ayu_variant:mirage
      SETUVAR fish_color_autosuggestion:707A8C
      SETUVAR fish_color_cancel:1F2430
      SETUVAR fish_color_command:5CCFE6
      SETUVAR fish_color_comment:5C6773
      SETUVAR fish_color_cwd:73D0FF
      SETUVAR fish_color_cwd_root:red
      SETUVAR fish_color_end:F29E74
      SETUVAR fish_color_error:FF3333
      SETUVAR fish_color_escape:95E6CB
      SETUVAR fish_color_history_current:\x2d\x2dbold
      SETUVAR fish_color_host:D4BFFF
      SETUVAR fish_color_host_remote:D4BFFF
      SETUVAR fish_color_match:F28779
      SETUVAR fish_color_normal:CBCCC6
      SETUVAR fish_color_operator:FFCC66
      SETUVAR fish_color_param:CBCCC6
      SETUVAR fish_color_quote:BAE67E
      SETUVAR fish_color_redirection:D4BFFF
      SETUVAR fish_color_search_match:\x2d\x2dbackground\x1eFFCC66
      SETUVAR fish_color_selection:FFCC66
      SETUVAR fish_color_status:red
      SETUVAR fish_color_user:FFA759
      SETUVAR fish_color_valid_path:\x2d\x2dunderline
      SETUVAR fish_key_bindings:fish_default_key_bindings
      SETUVAR fish_pager_color_completion:normal
      SETUVAR fish_pager_color_description:yellow\x1e\x2di
      SETUVAR fish_pager_color_prefix:normal\x1e\x2d\x2dbold\x1e\x2d\x2dunderline
      SETUVAR fish_pager_color_progress:brwhite\x1e\x2d\x2dbackground\x3dcyan
      SETUVAR fish_pager_color_selected_background:\x2dr
    '';

#21>[Script-Fish-Theme]
    "fish/functions/ayu.fish".text = ''
      function ayu_load_theme
          set --query ayu_path || set --local ayu_path $__fish_config_dir

          switch $ayu_variant
              case light
                  source $ayu_path/conf.d/ayu-light.fish && enable_ayu_theme_light
                  and colorize "Ayu %s light %s enabled!\n"
              case dark
                  source $ayu_path/conf.d/ayu-dark.fish && enable_ayu_theme_dark
                 and colorize "Ayu %s dark %s enabled!\n"
              case mirage
                  source $ayu_path/conf.d/ayu-mirage.fish && enable_ayu_theme_mirage
                  and colorize "Ayu %s mirage %s enabled!\n"
              case '*'
                  echo '⚠️  Invalid variant, choose among: light, dark or mirage'
          end
      end

      function colorize \
          --argument-names text
          printf $text (set_color $fish_color_quote --reverse) (set_color normal)
      end

      function _ayu_save_current_theme
          set --local previous_theme_file $__fish_config_dir/functions/_ayu_restore_previous_theme.fish

          test -e $previous_theme_file && command rm -f $previous_theme_file
          touch $previous_theme_file

          echo 'function _ayu_restore_previous_theme' > $previous_theme_file
          set color_variables (set --names | grep fish_color)
          for color_name in $color_variables
              set --local color_value $$color_name
              printf "\tset --universal $color_name $color_value\n" >> $previous_theme_file
          end
          echo 'end' >> $previous_theme_file
      end

      function _ayu_install --on-event ayu_install
          _ayu_save_current_theme
          and echo 'Previous theme saved! 🎉'
      end

      function _ayu_uninstall --on-event ayu_uninstall
          functions --erase enable_ayu_theme_light
          functions --erase enable_ayu_theme_dark
          functions --erase enable_ayu_theme_mirage

          set --local previous_theme_file $__fish_config_dir/functions/_ayu_restore_previous_theme.fish
          source $previous_theme_file && _ayu_restore_previous_theme
          command rm -f $previous_theme_file
          functions --erase _ayu_restore_previous_theme
          set --erase ayu_variant
      end

      function ayu_display_colorscheme
          set color_vars (set --names | grep fish_color)
          for color_var in $color_vars
              printf "%-30s %s\n" \
                  $color_var \
                  (set_color $$color_var --reverse)"$$color_var"(set_color normal)
          end
      end
    '';
#21>[Script-Fish-Theme-Config]
 "fish/conf.d/ayu-mirage.fish".text = ''
      function enable_ayu_theme_mirage
          set --universal fish_color_autosuggestion 707A8C # ayu:common.ui        autosuggestions
          set --universal fish_color_command        5CCFE6 # ayu:syntax.tag       commands
          set --universal fish_color_comment        5C6773 # ayu:syntax.comment   code comments
          set --universal fish_color_cwd            73D0FF # ayu:syntax.entity    current working directory in the default prompt
          set --universal fish_color_end            F29E74 # ayu:syntax.operator  process separators like ';' and '&'
          set --universal fish_color_error          FF3333 # ayu:syntax.error     highlight potential errors
          set --universal fish_color_escape         95E6CB # ayu:syntax.regexp    highlight character escapes like '\n' and '\x70'
          set --universal fish_color_match          F28779 # ayu:syntax.markup    highlight matching parenthesis
          set --universal fish_color_normal         CBCCC6 # ayu:common.fg        default color
          set --universal fish_color_operator       FFCC66 # ayu:syntax.accent    parameter expansion operators like '*' and '~'
          set --universal fish_color_param          CBCCC6 # ayu:common.fg        regular command parameters
          set --universal fish_color_quote          BAE67E # ayu:syntax.string    quoted blocks of text
          set --universal fish_color_redirection    D4BFFF # ayu:syntax.constant  IO redirections
          set --universal fish_color_search_match   --background FFCC66 # ayu:syntax.accent    highlight history search matches and the selected pager item (must be a background)
          set --universal fish_color_selection      FFCC66 # ayu:syntax.accent    when selecting text (in vi visual mode)

          # color for fish default prompts item
          set --universal fish_color_cancel         1F2430 # ayu:common.bg        the '^C' indicator on a canceled command
          set --universal fish_color_host           D4BFFF # ayu:syntax.constant  current host system in some of fish default prompts
          set --universal fish_color_host_remote    D4BFFF # ayu:syntax.constant  current host system in some of fish default prompts, if fish is running remotely (via ssh or similar)
          set --universal fish_color_user           FFA759 # ayu:syntax.keyword   current username in some of fish default prompts
      end
    '';

#21>[Script-Fish-Fish_Promt]
    "fish/functions/fish_prompt.fish".text = ''
      function fish_prompt
        set -l nix_shell_info (
          if test -n "$IN_NIX_SHELL"
            echo -n -s (set_color yellow) "nix-shell" (set_color normal) " "
          end
        )
        echo -n -s "$nix_shell_info"(set_color $fish_color_cwd)(prompt_pwd)(set_color normal) "> "
      end
    '';

#21>[Alacritty-Config]
    "alacritty/alacritty.toml".text = ''
env = { TERM = "xterm-256color" }

    [colors.primary]
    background = "#001d24"
    bright_foreground = "#93a1a1"
    dim_foreground = "#6a7779"
    foreground = "#839496"
    
    [colors.cursor]
    cursor = "#93a1a1"
    text = "#002b36"

    [colors.normal]
    black = "#002b36"
    red = "#dc322f"
    green = "#859900"
    yellow = "#b58900"
    blue = "#268bd2"
    magenta = "#d33682"
    cyan = "#2aa198"
    white = "#eee8d5"

    [colors.bright]
    black = "#073642"
    red = "#cb4b16"
    green = "#586e75"
    yellow = "#657b83"
    blue = "#839496"
    magenta = "#6c71c4"
    cyan = "#93a1a1"
    white = "#fdf6e3"

    [cursor]
    blink_interval = 500
    thickness = 0.4

    [cursor.style]
    blinking = "On"
    shape = "Underline"

    [font]
    size = 14.0

    [font.normal]
    family = "Monospace"
    style = "Regular"

    [[keyboard.bindings]]
    action = "ToggleFullscreen"
    key = "Return"
    mods = "Alt"

    [[keyboard.bindings]]
    action = "CreateNewWindow"
    key = "N"
    mods = "Control|Shift"

    [[keyboard.bindings]]
    action = "Quit"
    key = "W"
    mods = "Alt|Shift"

    [[keyboard.bindings]]
    chars = "_"
    key = "Space"
    mods = "Shift"

    [[keyboard.bindings]]
    chars = "&"
    key = "Period"
    mods = "Shift"

    [[keyboard.bindings]]
    chars = "*"
    key = "Comma"
    mods = "Shift"

    [selection]
    save_to_clipboard = true

    [window]
    decorations = "full"
    startup_mode = "Fullscreen"
    opacity = 0.85

    [window.padding]
    x = 15
    y = 15
    '';

#21>[Create-Workspace-Config]
"create-workspace.sh" = {
    text = ''
      #!/bin/sh
      
      # Ensure we have the necessary commands
      if ! command -v hyprctl >/dev/null 2>&1; then
          notify-send "Error" "hyprctl command not found"
          exit 1
      fi
      
      if ! command -v jq >/dev/null 2>&1; then
          notify-send "Error" "jq command not found"
          exit 1
      fi
      
      # Get current workspaces with error handling
      workspaces_json=$(hyprctl workspaces -j) || {
          notify-send "Error" "Failed to get workspace information"
          exit 1
      }
      
      current_workspaces=$(echo "$workspaces_json" | jq -r '.[].id') || {
          notify-send "Error" "Failed to parse workspace information"
          exit 1
      }
      
      # Find the first available workspace number from 1 to 10
      for i in $(seq 1 10); do
          if ! echo "$current_workspaces" | grep -q "^$i$"; then
              hyprctl dispatch workspace "$i"
              exit 0
          fi
      done
      
      # If all numbers 1-10 are taken, create the next available number
      next_workspace=$(($(echo "$current_workspaces" | sort -n | tail -n1) + 1))
      hyprctl dispatch workspace "$next_workspace"
    '';
    mode = "0755";
};  
#21>[Waybar-Config]
"xdg/waybar/config".text = let
      hasBacklight = builtins.pathExists "/sys/class/backlight/intel_backlight";
    in builtins.toJSON [{
      layer = "top";
      position = "bottom";
      height = 46;  
      modules-left = ["custom/start-menu" "hyprland/workspaces" "custom/create-workspace" "hyprland/window" ];
      modules-center = [];
      modules-right = [
        "custom/minimize-manager"
        "custom/nightmode"
          "pulseaudio"
      ] ++ lib.optionals isLaptop [ "battery" ]
        ++ [
          "network"
          "clock"
          "blueberry"
          "tray"
          "custom/brightness"
        ];
      "hyprland/workspaces" = {
        disable-scroll = true;
        all-outputs = true;
        format = "{name}";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          urgent = "";
          focused = "";
          default = "";
        };
      };
      "hyprland/window" = {
        format = "{}";
        separate-outputs = true;
        max-length = 40;
        icon = true;
        icon-size = 24;
      };
"clock" = {
    format = "{:%H:%M}";
    format-alt = "{:%Y-%m-%d %H:%M:%S}";
    tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>\n<tt>$(curl 'https://wttr.in/?format=3')</tt>";
    calendar = {
        mode = "month";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        on-click-right = "mode";
        format = {
            months = "<span color='#ffead3'><b>{}</b></span>";
            days = "<span color='#ecc6d9'><b>{}</b></span>";
            weeks = "<span color='#99ffdd'><b>W{}</b></span>";
            weekdays = "<span color='#ffcc66'><b>{}</b></span>";
            today = "<span color='#ff6699'><b><u>{}</u></b></span>";
        };
    };
    actions = {
        on-click-right = "mode";
        on-click-forward = "tz_up";
        on-click-backward = "tz_down";
        on-scroll-up = "shift_up";
        on-scroll-down = "shift_down";
    };
    interval = 1;
};
      "battery" = {
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
        format = "{icon}";
        format-charging = "󰂄";
        format-plugged = "󰚥";
        format-full = "󰁹";
        tooltip = true;
        tooltip-format = "Battery at {capacity}%\n{timeTo}";
        format-icons = ["󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };
      "network" = {
        format-wifi = "{icon}";
        format-ethernet = "󰈀";
        format-disconnected = "󰖪";
        tooltip = true;
        on-click = "nm-applet";
        tooltip-format = "Connected to {essid}\nStrength: {signalStrength}%\nIP: {ipaddr}";
        format-icons = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
      };
      "pulseaudio" = {  
        format = "{icon} {volume}%";
        format-muted = "󰝟 Muted";
        format-icons = {
          default = ["󰕿" "󰖀" "󰕾"];
          headphone = "󰋋";
          hands-free = "󰥰";
          headset = "󰋎";
          phone = "󰏲";
          portable = "󰖃";
          car = "󰄋";
        };
        on-click = "hyprctl dispatch togglespecialworkspace pavucontrol && pavucontrol-qt";
        on-scroll-up = "pamixer -i 5";
        on-scroll-down = "pamixer -d 5";
        smooth-scrolling-threshold = 1;
        tooltip = true;
        tooltip-format = "{icon} {volume}%\n{desc}";
      };
"bluetooth" = {
    format = "󰂯";
    format-disabled = "󰂲";
    format-off = "󰂲";
    on-click = "blueberry";
    tooltip = true;
};
      
      "tray" = {
        icon-size = 21;
        spacing = 10;
      };
      "custom/start-menu" = {
        format = "<span size='large'><b>✧</b></span>";
        on-click = "/etc/start-menu.sh click";
        interval = "once";
        tooltip = false;
      };
      "custom/create-workspace" = {
        format = ">";
        exec = "/etc/create-workspace.sh";
        on-click = "/etc/create-workspace.sh click";
        tooltip = false;
        interval = "once";
        signal = 1;
      };
"custom/nightmode" = {
    format = "{}";
    exec = "/etc/toggle-night-mode.sh";
    interval = "once";
    return-type = "json";
    on-click = "/etc/toggle-night-mode.sh click";
    on-click-right = "/etc/toggle-night-mode.sh right_click";
    on-scroll-up = "/etc/brightness-control.sh up";
    on-scroll-down = "/etc/brightness-control.sh down";
    signal = 8;
    tooltip = true;
};
      
      
      "custom/minimize-manager" = {
        format = "{}";
        exec = "/etc/minimize-manager.sh show";
        on-click = "/etc/wofi-toggle.sh minimize click";
        return-type = "json";
        interval = "once";
        signal = 8;
        tooltip = true;
      };
    }];

  ###########################################
  # Styles
  ###########################################

#22[Styles]
#22>[Waybar-Style]
  "xdg/waybar/style.css".source = pkgs.writeText "waybar-style" ''
    * {
    border: none;
    border-radius: 0;
    font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", sans-serif;
    font-size: 14px;
    min-height: 0;
}

window#waybar {
    background: rgba(11, 18, 27, 0.9);
    color: #eceff4;
}
#custom-create-workspace{
  margin-top: 10px;
    color: #88c0d0;
    background: #3b4252;
    border: 1px solid #4c566a;
  border-radius: 0px 10px 10px 0px;
    margin-left: 0px;
    padding: 0 10px;
    font-size: 16px;
    transition: all 0.3s ease-in-out;
}
#custom-create-workspace:hover {
    background-color: #434c5e;
    color: #88c0d0;
    border-color: #88c0d0;
}
#custom-start-menu {
    color: #88c0d0;
    background: #3b4252;
    border: 1px solid #4c566a;
    border-radius: 10px 0px 0px 10px;
    margin-top: 10px;
    margin-left: 10px;
    padding: 0 10px;
    font-size: 24px;
    transition: all 0.3s ease-in-out;
}

#custom-start-menu:hover {
    animation: textGradient 6s linear infinite;
    border-color: #88c0d0;
}

@keyframes textGradient {
    0% { color: #ff69b4; }
    33% { color: #9370db; }
    66% { color: #191970; }
    100% { color: #ff69b4; }
}
tooltip {
    background: #3b4252;
    border-radius: 10px;
    border-width: 2px;
    border-style: solid;
    border-color: #4c566a;
}
#workspaces button {
    padding: 5px;
    color: #d8dee9;
    margin-right: 5px;
}

#workspaces button.active {
    color: #88c0d0;
    background: #3b4252;
    border-radius: 10px;
}

#workspaces button.urgent {
    color: #2e3440;
    background: #ebcb8b;
    border-radius: 10px;
}

#workspaces button:hover {
    background: #3b4252;
    color: #88c0d0;
    border-radius: 10px;
}

#custom-nightmode,
#window,
#clock,
#battery,
#pulseaudio,
#network,
#workspaces,
#tray{
   background: #3b4252;
   padding: 0px 10px;
   margin: 0px 0px;
   margin-top: 10px;
   border: 1px solid #4c566a;
}
#custom-minimize-manager {
    background-color: #3b4252;
    color: #eceff4;
    padding: 0 10px;
    min-width: 30px;
    margin-top: 10px;
    border: 1px solid #4c566a;
    border-radius: 10px 0px 0px 10px;
    transition: all 0.3s ease-in-out;
}

#custom-minimize-manager:hover,
#custom-minimize-manager:active {
    background-color: #434c5e;
    border-color: #88c0d0;
}
#custom-minimize-manager.empty {
    color: #4c566a;
}

#custom-nightmode {
    padding: 0 10px;
    margin: 0;
    color: #ffffff;
    background-color: #3b4252;
    border-radius: 0px;
    margin-top: 10px;
    min-width: 30px;
    font-size: 18px;
    transition: all 0.3s ease-in-out;

}

#custom-nightmode:hover {
    background-color: #434c5e;
    border-color: #88c0d0;
}
#custom-nightmode.day {
    color: #ebcb8b;
}

#custom-nightmode.night {
    color: #5e81ac;
}

#custom-nightmode.deep-night {
    color: #b48ead;
}

#tray {
    border-radius: 0px;
    margin-right: 0px;
}

#workspaces {
    margin-top: 10px;
    background-color: #434c5e;
    border-radius: 0px;
    border: 1px solid #4c566a;
    margin-left: 0px;
    padding-right: 0px;
    padding-left: 5px;
    transition: all 0.3s ease-in-out;
}

#workspaces:hover {
    background: #3b4252;
    border-color: #88c0d0;
}

#window {
    border-radius: 10px;
    margin-left: 10px;
    margin-right: 60px;
    transition: all 0.3s ease-in-out;
}

#window:hover {
    background-color: #434c5e;
    border-color: #88c0d0;
}
#clock {
    color: #88c0d0;
    border-radius: 0px;
    margin-right: 0px;
    border-right: 0px;
    transition: all 0.3s ease-in-out;
}

#clock:hover {
    background-color: #434c5e;
    border-color: #88c0d0;
}
#network {
    color: #88c0d0;
    border-left: 0px;
    border-right: 0px;
}

#pulseaudio {
    color: #ebcb8b;
    transition: all 0.3s ease-in-out;
}

#pulseaudio:hover {
    background-color: #434c5e;
    border-color: #88c0d0;
}


#battery {
    color: #81a1c1;
    border-left: 0px;
    border-right: 0px;
}

#clock.calendar-today {
    color: #ff6699;
    transition: all 0.3s ease-in-out;
}

'';
#22>[Audio-Style]

"xdg/qt5ct/qss/pavucontrol-qt-custom.qss".text = ''
    QMainWindow {
        background-color: #2e3440;
        border-radius: 8px;
    }

    QWidget {
        color: #d8dee9;
        background-color: #2e3440;
        font-size: 10pt;
    }

    QSlider::groove:horizontal {
        height: 4px;
        background: #3b4252;
        border-radius: 2px;
    }

    QSlider::handle:horizontal {
        background: #88c0d0;
        width: 16px;
        height: 16px;
        margin: -6px 0;
        border-radius: 8px;
    }

    QSlider::sub-page:horizontal {
        background: #88c0d0;
        border-radius: 2px;
    }

    /* Tabs */
    QTabWidget::pane {
        border: 1px solid #3b4252;
        border-radius: 4px;
        top: -1px;
    }

    QTabBar::tab {
        background: #3b4252;
        color: #d8dee9;
        padding: 6px 16px;
        border-top-left-radius: 4px;
        border-top-right-radius: 4px;
        margin-right: 2px;
    }

    QTabBar::tab:selected {
        background: #4c566a;
        border-bottom: 2px solid #88c0d0;
    }

    QComboBox {
        background: #3b4252;
        border: 1px solid #4c566a;
        border-radius: 4px;
        padding: 4px 8px;
        min-width: 100px;
    }

    QComboBox::drop-down {
        border: none;
        width: 20px;
    }

    QComboBox::down-arrow {
        image: none;
        border: none;
    }

    /* Scrollbars */
    QScrollBar:vertical {
        border: none;
        background: #3b4252;
        width: 6px;
        border-radius: 3px;
    }

    QScrollBar::handle:vertical {
        background: #4c566a;
        min-height: 30px;
        border-radius: 3px;
    }

    QScrollBar::add-line:vertical,
    QScrollBar::sub-line:vertical {
        border: none;
        background: none;
        height: 0px;
    }

    QTreeView {
        background: #2e3440;
        border: 1px solid #3b4252;
        border-radius: 4px;
    }

    QTreeView::item {
        padding: 4px;
        border-radius: 4px;
    }

    QTreeView::item:selected {
        background: #4c566a;
        border: none;
    }

    QPushButton {
        background: #3b4252;
        border: 1px solid #4c566a;
        border-radius: 4px;
        padding: 4px 16px;
        min-width: 60px;
    }

    QPushButton:hover {
        background: #4c566a;
        border-color: #88c0d0;
    }

    QPushButton:pressed {
        background: #2e3440;
    }

    QProgressBar {
        border: 1px solid #3b4252;
        border-radius: 2px;
        background: #2e3440;
        height: 4px;
        text-align: right;
        margin: 2px;
    }

    QProgressBar::chunk {
        background: #88c0d0;
        border-radius: 2px;
    }

    QToolTip {
        background: #2e3440;
        color: #d8dee9;
        border: 1px solid #4c566a;
        border-radius: 4px;
        padding: 4px;
    }
  '';
#22>[Rofi-Notification-Style]

"xdg/rofi/themes/notification.rasi".text = ''
  * {
      background: #2E3440;
      foreground: #D8DEE9;
      border-color: #4C566A;
      width: 300px;
      font: "JetBrainsMono Nerd Font 10";
  }

  window {
      padding: 8px;
      border: 2px solid;
      border-color: @border-color;
      border-radius: 8px;
      background-color: @background;
      x-offset: -20px;
      y-offset: -20px;
      location: southeast;
  }

  mainbox {
      padding: 8px;
      background-color: transparent;
  }

  message {
      padding: 8px;
      background-color: transparent;
      text-color: @foreground;
  }
'';


#22>[Wofi-Hypr-Bindings-Style]

"xdg/rofi/themes/keybindings.rasi".text = ''

/*****----- Configuration -----*****/
configuration {
    show-icons:                 false;
    hover-select:               true;
    me-select-entry:            "";
    me-accept-entry:            "MousePrimary";
    scroll-method:              0;
}

/*****----- Global Properties -----*****/

* {
    font:                        "JetBrainsMono Nerd Font 10";
    background:                  #2E3440;
    background-alt:              #3B4252;
    foreground:                  #ECEFF4;
    selected:                    #88C0D0;
    active:                      #A3BE8C;
    urgent:                      #BF616A;
}

/*****----- Main Window -----*****/
window {
    transparency:                "real";
    location:                    southwest;
    anchor:                      southwest;
    fullscreen:                  false;
    width:                       800px;
    height:                      1000px;
    x-offset:                    10px;
    y-offset:                    -10px;
    padding:                     0px;
    border:                      2px solid;
    border-radius:               12px;
    border-color:                @background-alt;
    cursor:                      "default";
    background-color:            @background;
    /* Added depth with a shadow */
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    border:                      3px solid;
    border-color:                #4C566A;
    box-shadow:                  0 8px 16px;
}

/*****----- Main Box -----*****/
mainbox {
    enabled:                     true;
    spacing:                     0px;
    background-color:            transparent;
    children:                    [ "inputbar", "listview", "message" ];
}

/*****----- Inputbar -----*****/

inputbar {
    enabled:                     true;
    spacing:                     0px;
    padding:                     0px;
    margin:                      0px 0px 20px 0px;
    background-color:            @background-alt;
    text-color:                  @foreground;
    border-radius:               8px;
    border:                      1px solid;
    border-color:                #4C566A;
    /* Modified to dark-light-dark vertical gradient */
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    children:                    [ "textbox-prompt-colon", "prompt"];
}

textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    padding:                     12px;
    background-color:            transparent;
    text-color:                  inherit;
    font:                        "JetBrainsMono Nerd Font 28";
}

prompt {
    enabled:                     true;
    padding:                     12px;
    background-color:            transparent;
    text-color:                  inherit;
    font:                        "JetBrainsMono Nerd Font 20";
    font-weight:                 bold;
}

/*****----- Message -----*****/

message {
    enabled:                     true;
    margin:                      20px 0px 0px 0px;
    padding:                     12px;
    border-radius:               2px;
    border:                      1px solid;
    border-color:                #4C566A;
    background-color:            transparent;
    text-color:                  @foreground;
    /* Changed to dark background */
    background-image:            linear-gradient(#2E3440, #2E3440);
}

textbox {
    background-color:            inherit;
    text-color:                  inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}
/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     2;
    lines:                       6;
    cycle:                       false;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    reverse:                     false;
    fixed-height:                true;
    fixed-columns:               true;
    spacing:                     5px;
    margin:                      10px;
    padding:                     10px;
    background-color:            transparent;
    cursor:                      "default";
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    padding:                     12px;
    background-color:            transparent;
    text-color:                  @foreground;
    cursor:                      pointer;
    border-radius:               8px;
    border:                      1px solid;
    border-color:                transparent;
    /* Added transition for smooth hover effect */
}

element normal.normal {
    background-color:            transparent;
    text-color:                  @foreground;
}

element selected.normal {
    background-color:            @background-alt;
    text-color:                  @selected;
    border:                      1px solid;
    border-color:                #4C566A;
    /* Added gradient and shadow for selected items */
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    box-shadow:                  0 2px 4px;
}

element-text {
    font:                        "JetBrainsMono Nerd Font 12";
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}

/* Added hover effect */
element.hover {
    border:                      2px solid;
    border-color:                #4C566A;
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    box-shadow:                  0 2px 4px;
}

'';
#22>[Wofi-Start-Menu-Style]
"xdg/rofi/themes/start-menu.rasi".text ='' 

/*****----- Configuration -----*****/
configuration {
    show-icons:                 false;
    hover-select:               true;
    me-select-entry:            "";
    me-accept-entry:            "MousePrimary";
    scroll-method:              0;
}

/*****----- Global Properties -----*****/
* {
    font:                        "JetBrainsMono Nerd Font 10";
    background:                  #2E3440;
    background-alt:              #3B4252;
    foreground:                  #ECEFF4;
    selected:                    #88C0D0;
    active:                      #A3BE8C;
    urgent:                      #BF616A;
}

/*****----- Main Window -----*****/
window {
    transparency:                "real";
    location:                    southwest;
    anchor:                      southwest;
    fullscreen:                  false;
    width:                       800px;
    height:                      600px;
    x-offset:                    10px;
    y-offset:                    -10px;
    padding:                     0px;
    border:                      2px solid;
    border-radius:               12px;
    border-color:                @background-alt;
    cursor:                      "default";
    background-color:            @background;
    /* Added depth with a shadow */
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    border:                      3px solid;
    border-color:                #4C566A;
    box-shadow:                  0 8px 16px;
}

/*****----- Main Box -----*****/
mainbox {
    enabled:                     true;
    spacing:                     0px;
    background-color:            transparent;
    children:                    [ "inputbar", "listview", "message" ];
}

/*****----- Inputbar -----*****/

inputbar {
    enabled:                     true;
    spacing:                     0px;
    padding:                     0px;
    margin:                      0px 0px 20px 0px;
    background-color:            @background-alt;
    text-color:                  @foreground;
    border-radius:               8px;
    border:                      1px solid;
    border-color:                #4C566A;
    /* Modified to dark-light-dark vertical gradient */
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    children:                    [ "textbox-prompt-colon", "prompt"];
}

textbox-prompt-colon {
    enabled:                     true;
    expand:                      false;
    padding:                     12px;
    background-color:            transparent;
    text-color:                  inherit;
    font:                        "JetBrainsMono Nerd Font 28";
}

prompt {
    enabled:                     true;
    padding:                     12px;
    background-color:            transparent;
    text-color:                  inherit;
    font:                        "JetBrainsMono Nerd Font 20";
    font-weight:                 bold;
}

/*****----- Message -----*****/

message {
    enabled:                     true;
    margin:                      20px 0px 0px 0px;
    padding:                     12px;
    border-radius:               2px;
    border:                      1px solid;
    border-color:                #4C566A;
    background-color:            transparent;
    text-color:                  @foreground;
    /* Changed to dark background */
    background-image:            linear-gradient(#2E3440, #2E3440);
}

textbox {
    background-color:            inherit;
    text-color:                  inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}
/*****----- Listview -----*****/
listview {
    enabled:                     true;
    columns:                     2;
    lines:                       6;
    cycle:                       false;
    dynamic:                     true;
    scrollbar:                   false;
    layout:                      vertical;
    reverse:                     false;
    fixed-height:                true;
    fixed-columns:               true;
    spacing:                     5px;
    margin:                      10px;
    padding:                     10px;
    background-color:            transparent;
    cursor:                      "default";
}

/*****----- Elements -----*****/
element {
    enabled:                     true;
    padding:                     12px;
    background-color:            transparent;
    text-color:                  @foreground;
    cursor:                      pointer;
    border-radius:               8px;
    border:                      1px solid;
    border-color:                transparent;
    /* Added transition for smooth hover effect */
}

element normal.normal {
    background-color:            transparent;
    text-color:                  @foreground;
}

element selected.normal {
    background-color:            @background-alt;
    text-color:                  @selected;
    border:                      1px solid;
    border-color:                #4C566A;
    /* Added gradient and shadow for selected items */
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    box-shadow:                  0 2px 4px;
}

element-text {
    font:                        "JetBrainsMono Nerd Font 12";
    background-color:            transparent;
    text-color:                  inherit;
    cursor:                      inherit;
    vertical-align:              0.5;
    horizontal-align:            0.0;
}

/* Added hover effect */
element.hover {
    border:                      2px solid;
    border-color:                #4C566A;
    background-image:            linear-gradient(
        #2E3440,
        #3B4252,
        #2E3440
    );
    box-shadow:                  0 2px 4px;
}


''; 
#22>[Wofi-Right-Click-Style]
"xdg/wofi/right-click-style.css".text =''

window {
    background-color: #2e3440;
    border: 2px solid #4c566a;
    border-radius: 8px;
}

#outer-box {
    margin: 0px;
    padding: 0px;
}

#inner-box {
    margin: 0px;
    padding: 0px;
    background: transparent;
}

#scroll {
    margin: 0px;
    padding: 0px;
}

#text {
    margin: 0px;
    padding: 8px 12px;
    color: #eceff4;
        font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
}

#entry {
        padding: 8px;
        margin: 4px 8px;
        border-radius: 8px;
        background: #3b4252;
        transition: all 0.2s ease;
}

#entry:hover {
    background-color: #3b4252;
    border-radius: 4px;
    margin: 0 4px;
}

#entry.selected {
    background: transparent;
}

/* Hide search elements */
#input, #prompt, #img {
    display: none !important;
    opacity: 0;
    margin: 0;
    padding: 0;
    border: 0;
    height: 0;
}


'';
#22>[Wofi-Style]
"xdg/wofi/minimize-style.css".text = ''
    window {
         background-color: rgba(46, 52, 64, 0.95);  
        border: 2px solid #4c566a;
        border-radius: 8px;
    }

     #input {
        border: none;
        background: #3b4252;
        border-radius: 4px;
        margin: 8px;
        padding: 8px;
        color: #eceff4;
        font-family: "JetBrainsMono Nerd Font";
    }

    #entry {
        padding: 8px;
        margin: 4px 8px;
        border-radius: 8px;
        background: #3b4252;
        transition: all 0.2s ease;
    }

    #entry:selected {
        background: #4c566a;
        border: 1px solid #88c0d0;
    }

    #entry box {
        padding: 0px;
        margin: 0px;
    }
#outer-box {
    margin: 0;
    border: none;
}
    #entry image {
        margin-right: 8px;
        min-width: 200px;
        min-height: 150px;
        border-radius: 4px;
        background: #2e3440;
        padding: 2px;
    }

    #entry label {
        color: #eceff4;
        font-family: "JetBrainsMono Nerd Font";
        padding: 0 8px;
    }

    #entry:last-child {
        background: #2a317c;
        margin-bottom: 8px;
    }

    #entry:first-child image {
        min-width: 24px;
        min-height: 24px;
        margin: 0 8px;
    }

    #entry:first-child:selected {
    }
      /* Main categories */
    #entry.category {
        background: #434c5e;
        border-left: 4px solid #88c0d0;
    }


    #entry.category {
    background: #434c5e;
    border-left: 4px solid #88c0d0;
}

    #entry.subcategory {
    margin-left: 16px;
    background: #3b4252;
    border-left: 4px solid #81a1c1;
}
  '';
   
#22>[Zellij-Config]
  "zellij/config.kdl".text = ''

    // If you'd like to override the default keybindings completely, be sure to change "keybinds" to "keybinds clear-defaults=true"
    keybinds clear-defaults=true {
      normal {
        // uncomment this and adjust key if using copy_on_select=false
        // bind "Alt c" { Copy; }
      }
      locked {
        bind "Alt g" { SwitchToMode "Normal"; }
      }
      resize {
        bind "Alt n" { SwitchToMode "Normal"; }
        bind "h" "Left" { Resize "Increase Left"; }
        bind "j" "Down" { Resize "Increase Down"; }
        bind "k" "Up" { Resize "Increase Up"; }
        bind "l" "Right" { Resize "Increase Right"; }
        bind "H" { Resize "Decrease Left"; }
        bind "J" { Resize "Decrease Down"; }
        bind "K" { Resize "Decrease Up"; }
        bind "L" { Resize "Decrease Right"; }
        bind "=" "+" { Resize "Increase"; }
        bind "-" { Resize "Decrease"; }
      }
      pane {
        bind "Alt p" { SwitchToMode "Normal"; }
        bind "h" "Left" { MoveFocus "Left"; }
        bind "l" "Right" { MoveFocus "Right"; }
        bind "j" "Down" { MoveFocus "Down"; }
        bind "k" "Up" { MoveFocus "Up"; }
        bind "p" { SwitchFocus; }
        bind "n" { NewPane; SwitchToMode "Normal"; }
        bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
        bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
        bind "x" { CloseFocus; SwitchToMode "Normal"; }
        bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
        bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
        bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
        bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
      }
      move {
        bind "Alt m" { SwitchToMode "Normal"; }
        bind "n" "Tab" { MovePane; }
        bind "p" { MovePaneBackwards; }
        bind "Alt h" "Left" { MovePane "Left"; }
        bind "j" "Down" { MovePane "Down"; }
        bind "k" "Up" { MovePane "Up"; }
        bind "l" "Right" { MovePane "Right"; }
      }
      tab {
        bind "Alt t" { SwitchToMode "Normal"; }
        bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
        bind "h" "Left" "Up" "k" { GoToPreviousTab; }
        bind "l" "Right" "Down" "j" { GoToNextTab; }
        bind "n" { NewTab; SwitchToMode "Normal"; }
        bind "x" { CloseTab; SwitchToMode "Normal"; }
        bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
        bind "b" { BreakPane; SwitchToMode "Normal"; }
        bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
        bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
        bind "1" { GoToTab 1; SwitchToMode "Normal"; }
        bind "2" { GoToTab 2; SwitchToMode "Normal"; }
        bind "3" { GoToTab 3; SwitchToMode "Normal"; }
        bind "4" { GoToTab 4; SwitchToMode "Normal"; }
        bind "5" { GoToTab 5; SwitchToMode "Normal"; }
        bind "6" { GoToTab 6; SwitchToMode "Normal"; }
        bind "7" { GoToTab 7; SwitchToMode "Normal"; }
        bind "8" { GoToTab 8; SwitchToMode "Normal"; }
        bind "9" { GoToTab 9; SwitchToMode "Normal"; }
        bind "Tab" { ToggleTab; }
      }
      scroll {
        bind "Alt s" { SwitchToMode "Normal"; }
        bind "e" { EditScrollback; SwitchToMode "Normal"; }
        bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
        bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
        bind "j" "Down" { ScrollDown; }
        bind "k" "Up" { ScrollUp; }
        bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
        bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
        bind "d" { HalfPageScrollDown; }
        bind "u" { HalfPageScrollUp; }
        // uncomment this and adjust key if using copy_on_select=false
        bind "Alt c" { Copy; }
      }
      search {
        bind "Alt s" { SwitchToMode "Normal"; }
        bind "Alt c" { ScrollToBottom; SwitchToMode "Normal"; }
        bind "j" "Down" { ScrollDown; }
        bind "k" "Up" { ScrollUp; }
        bind "Alt f" "PageDown" "Right" "l" { PageScrollDown; }
        bind "Alt b" "PageUp" "Left" "h" { PageScrollUp; }
        bind "d" { HalfPageScrollDown; }
        bind "u" { HalfPageScrollUp; }
        bind "n" { Search "down"; }
        bind "p" { Search "up"; }
        bind "c" { SearchToggleOption "CaseSensitivity"; }
        bind "w" { SearchToggleOption "Wrap"; }
        bind "o" { SearchToggleOption "WholeWord"; }
      }
      entersearch {
        bind "Alt c" "Esc" { SwitchToMode "Scroll"; }
        bind "Enter" { SwitchToMode "Search"; }
      }
      renametab {
        bind "Alt c" { SwitchToMode "Normal"; }
        bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
      }
      renamepane {
        bind "Alt c" { SwitchToMode "Normal"; }
        bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
      }
      session {
        bind "Alt o" { SwitchToMode "Normal"; }
        bind "Alt s" { SwitchToMode "Scroll"; }
        bind "d" { Detach; }
        bind "w" {
            LaunchOrFocusPlugin "session-manager" {
                floating true
                move_to_focused_tab true
            };
            SwitchToMode "Normal"
        }
      }
      tmux {
        bind "[" { SwitchToMode "Scroll"; }
        bind "Alt b" { Write 2; SwitchToMode "Normal"; }
        bind "\"" { NewPane "Down"; SwitchToMode "Normal"; }
        bind "%" { NewPane "Right"; SwitchToMode "Normal"; }
        bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "c" { NewTab; SwitchToMode "Normal"; }
        bind "," { SwitchToMode "RenameTab"; }
        bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
        bind "n" { GoToNextTab; SwitchToMode "Normal"; }
        bind "Left" { MoveFocus "Left"; SwitchToMode "Normal"; }
        bind "Right" { MoveFocus "Right"; SwitchToMode "Normal"; }
        bind "Down" { MoveFocus "Down"; SwitchToMode "Normal"; }
        bind "Up" { MoveFocus "Up"; SwitchToMode "Normal"; }
        bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
        bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
        bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
        bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
        bind "o" { FocusNextPane; }
        bind "d" { Detach; }
        bind "Space" { NextSwapLayout; }
        bind "x" { CloseFocus; SwitchToMode "Normal"; }
      }
      shared_except "locked" {
        bind "Alt g" { SwitchToMode "Locked"; }
        bind "Alt q" { Quit; }
        bind "Alt n" { NewPane; }
        bind "Alt i" { MoveTab "Left"; }
        bind "Alt o" { MoveTab "Right"; }
        bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
        bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
        bind "Alt j" "Alt Down" { MoveFocus "Down"; }
        bind "Alt k" "Alt Up" { MoveFocus "Up"; }
        bind "Alt =" "Alt +" { Resize "Increase"; }
        bind "Alt -" { Resize "Decrease"; }
        bind "Alt [" { PreviousSwapLayout; }
        bind "Alt ]" { NextSwapLayout; }
      }
      shared_except "normal" "locked" {
        bind "Enter" "Esc" { SwitchToMode "Normal"; }
      }
      shared_except "pane" "locked" {
        bind "Alt p" { SwitchToMode "Pane"; }
      }
      shared_except "resize" "locked" {
        bind "Alt n" { SwitchToMode "Resize"; }
      }
      shared_except "scroll" "locked" {
        bind "Alt s" { SwitchToMode "Scroll"; }
      }
      shared_except "session" "locked" {
        bind "Alt o" { SwitchToMode "Session"; }
      }
      shared_except "tab" "locked" {
        bind "Alt t" { SwitchToMode "Tab"; }
      }
      shared_except "move" "locked" {
        bind "Alt m" { SwitchToMode "Move"; }
      }
      shared_except "tmux" "locked" {
        bind "Alt b" { SwitchToMode "Tmux"; }
      }
    }
              
                                                                         
  load_plugins {
        plugin "file:${zjstatus-plugin}/share/zellij/plugins/zjframes.wasm" {
            hide_frame_for_single_pane       "true"
            hide_frame_except_for_search     "true"
            hide_frame_except_for_fullscreen "true"
        }
    }

    plugins {
      session-manager { path "session-manager"; }
    }
    simplified_ui true
    default_shell "fish"
    pane_frames false
    auto_layout true
    mouse_mode true
    copy_command "wl-copy"
    layout_dir "/etc/zellij/layouts/"
    theme "solarized-dark"
    default_layout "solarized"

    themes {
      solarized-dark {
          fg 253 246 227
          bg 0 43 54
          black 7 54 66
          red 220 50 47
          green 133 153 0
          yellow 181 137 0
          blue 38 139 210
          magenta 211 54 130
          cyan 42 161 152
          white 238 232 213
          orange 203 75 22
      }
    }
  '';
                # plugin location="file:~/.config/zellij/plugins/zjstatus.wasm" {
#22>[Zellij-Style]

"zellij/layouts/solarized.kdl".text = ''
    layout {
        default_tab_template {
            children
            pane size=1 borderless=true {
                plugin location="file:${zjstatus-plugin}/share/zellij/plugins/zjstatus.wasm" {
                    

    color_bg0 "#001b26" // base02
    color_bg1 "#002b36" // base03
    color_bg2 "#586e75" // base01
    color_bg3 "#000000" // base00
    color_bg4 "#839496" // base0
    color_fg0 "#fbf1c7" //light0
    color_fg1 "#000000" //light1
    color_fg2 "#d5c4a1" //light2
    color_fg3 "#bdae93" //light3
    color_fg4 "#000000" //light4
    color_red "#fb4934" // bright_red
    color_green "#b8bb26" //bright_green
    color_yellow "#fabd2f" // bright_yellow
    color_blue "#83a598" //bright_blue
    color_purple "#d3869b" //bright_purple
    color_aqua "#8ec07c" //bright_aqua
    color_gray "#a89984" //bright_gray
    color_orange "#fe8019" //bright_orange
    color_neutral_red "#cc241d" //neutral_red
    color_neutral_green "#98971a" //neutral_green
    color_neutral_yellow "#d79921" //neutral_yellow
    color_neutral_blue "#458588" //neutral_blue
    color_neutral_purple "#b16286" //neutral_purple
    color_neutral_aqua "#689d6a" //neutral_aqua
    color_neutral_gray "#928374" //neutral_gray
    color_neutral_orange "#d65d0e" //neatural_orange



    format_left   "#[bg=$bg3,fg=$fg3] {session} {mode}#[bg=$bg1]{tabs}"
    format_center "{notifications}"
    format_right  "#[bg=$bg1,fg=$bg2]#[bg=$bg2,fg=$fg4] {command_user}@{command_host} #[bg=$bg2,fg=$fg1]#[bg=$fg1,fg=$fg3] {datetime} "
    format_space  "#[bg=$bg1,fg=$fg1]"
    format_hide_on_overlength "true"
    format_precedence "lrc"

    border_enabled  "true"
    border_char     "─"
    border_format   "#[fg=$bg3]{char}"
    border_position "top"

    hide_frame_for_single_pane "true"

    mode_normal        "#[bg=$blue,fg=$bg3]#[bg=$blue,fg=$fg1] NORMAL#[bg=$bg1,fg=$blue]"
    mode_tmux          "#[bg=$green,fg=$bg2]#[bg=$green,fg=$bg0,bold] TMUX#[bg=$bg1,fg=$green]"
    mode_locked        "#[bg=$red,fg=$bg2]#[bg=$red,fg=$bg0,bold] LOCKED#[bg=$bg1,fg=$red]"
    mode_pane          "#[bg=$aqua,fg=$bg2]#[bg=$aqua,fg=$bg0,bold] PANE#[bg=$bg1,fg=$aqua]"
    mode_tab           "#[bg=$aqua,fg=$bg2]#[bg=$aqua,fg=$bg0,bold] TAB#[bg=$bg1,fg=$aqua]"
    mode_scroll        "#[bg=$blue,fg=$bg2]#[bg=$blue,fg=$bg0,bold] SCROLL#[bg=$bg1,fg=$blue]"
    mode_enter_search  "#[bg=$blue,fg=$bg2]#[bg=$blue,fg=$bg0,bold] ENT-SEARCH#[bg=$bg1,fg=$blue]"
    mode_search        "#[bg=$blue,fg=$bg2]#[bg=$blue,fg=$bg0,bold] SEARCH#[bg=$bg1,fg=$blue]"
    mode_resize        "#[bg=$yellow,fg=$bg2]#[bg=$yellow,fg=$bg0,bold] RESIZE#[bg=$bg1,fg=$yellow]"
    mode_rename_tab    "#[bg=$yellow,fg=$bg2]#[bg=$yellow,fg=$bg0,bold] RESIZE#[bg=$bg1,fg=$yellow]"
    mode_rename_pane   "#[bg=$yellow,fg=$bg2]#[bg=$yellow,fg=$bg0,bold] RESIZE#[bg=$bg1,fg=$yellow]"
    mode_move          "#[bg=$yellow,fg=$bg2]#[bg=$yellow,fg=$bg0,bold] MOVE#[bg=$bg1,fg=$yellow]"
    mode_session       "#[bg=$purple,fg=$bg2]#[bg=$purple,fg=$bg0,bold] MOVE#[bg=$bg1,fg=$purple]"
    mode_prompt        "#[bg=$purple,fg=$bg2]#[bg=$purple,fg=$bg0,bold] PROMPT#[bg=$bg1,fg=$purple]"

    tab_normal              "#[bg=$bg2,fg=$bg1]#[bg=$bg2,fg=$fg1] {index} #[bg=$bg2,fg=$fg1] {name} {floating_indicator}#[bg=$bg1,fg=$bg2]"
    tab_normal_fullscreen   "#[bg=$bg2,fg=$bg1]#[bg=$bg2,fg=$fg1] {index} #[bg=$bg2,fg=$fg1] {name} {fullscreen_indicator}#[bg=$bg1,fg=$bg2]"
    tab_normal_sync         "#[bg=$bg2,fg=$bg1]#[bg=$bg2,fg=$fg1] {index} #[bg=$bg2,fg=$fg1] {name} {sync_indicator}#[bg=$bg1,fg=$bg2]"
    tab_active              "#[bg=$yellow,fg=$bg1]#[bg=$yellow,fg=$bg3] {index} #[bg=$yellow,fg=$bg3] {name} {floating_indicator}#[bg=$bg1,fg=$yellow]"
    tab_active_fullscreen   "#[bg=$yellow,fg=$bg1]#[bg=$yellow,fg=$bg3] {index} #[bg=$yellow,fg=$bg3] {name} {fullscreen_indicator}#[bg=$bg1,fg=$yellow]"
    tab_active_sync         "#[bg=$yellow,fg=$bg1]#[bg=$yellow,fg=$bg3] {index} #[bg=$yellow,fg=$bg3] {name} {sync_indicator}#[bg=$bg1,fg=$yellow]"
    tab_separator           "#[bg=$bg1,fg=$fg1]"

    tab_sync_indicator       ""
    tab_fullscreen_indicator "󰊓"
    tab_floating_indicator   "󰹙"

    notification_format_unread "#[bg=$orange,fg=$bg1]#[bg=$orange,fg=$bg1] {message} #[bg=$bg1,fg=$orange]"
    notification_format_no_notifications ""
    notification_show_interval "10"

    command_host_command    "uname -n"
    command_host_format     "{stdout}"
    command_host_interval   "0"
    command_host_rendermode "static"

    command_user_command    "whoami"
    command_user_format     "{stdout}"
    command_user_interval   "0"
    command_user_rendermode "static"

    datetime          "{format}"
    datetime_format   "%Y-%m-%d %H:%M"
    datetime_timezone "${timezone}"

                }
            }
        }
    }
'';





};                                               
  ###########################################
  #  System State Version
  ###########################################
#23>[System]
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.stateVersion = "24.05";
  ###########################################
  #  Templates And Help. Do Not Remove
  ###########################################
#23>[Templates]
  # Template for setting up custom configurations
  # system.activationScripts = {
  #   setup-custom-configs = ''
  #     # Create system-wide config directory
 #     mkdir -p /etc/customapp
  #     chmod 755 /etc/customapp - So, the numbers mean, in order, owner, group and others. you know, for permissions

  #     # Create user-specific config directory
  #     mkdir -p /home/username/.config/customapp

  #     # Create symlinks from user directory to system directory
  #     ln -sf /etc/customapp/config.toml /home/username/.config/customapp/config.toml
      
  #     # If there are subdirectories, you can symlink them too
  #     # ln -sf /etc/customapp/subdir /home/username/.config/customapp/subdir

  #     # Set correct ownership
  #     chown -R username:users /home/username/.config/customapp
  #   '';
  # };
}
