# Add this to your configuration.nix
# Print - Either via app (libre office or )
{
  pkgs,
  lib,
  ...
}:
# Brother DCP-L2622DW Command Line Printing Guide
# Check your available printers
#lpstat -p
#lpstat -v
# Basic printing commands:
# 1. Print text to default printer
#echo "Hello World" | lp
# 2. Print text to specific printer
#echo "Hello World" | lp -d Brother_DCP_L2622DW
# or
#echo "Hello World" | lp -d BrotherDCPL2622DW
# 3. Print a file
#lp document.pdf
#lp document.txt
#lp image.jpg
# 4. Print file to specific printer
#lp -d Brother_DCP_L2622DW document.pdf
# 5. Print with options
#lp -o sides=two-sided-long-edge document.pdf    # Duplex printing
#lp -o media=A4 document.pdf                     # Paper size
#lp -o orientation-requested=4 document.pdf      # Landscape
#lp -o print-quality=5 document.pdf              # High quality
# 6. Print multiple copies
#lp -n 3 document.pdf                            # 3 copies
# 7. Print with title
#lp -t "My Document" document.pdf
# 8. Print from stdin with options
#cat document.txt | lp -o sides=two-sided-long-edge
# 9. Print images with fit-to-page
#lp -o fit-to-page image.jpg
# 10. Check printer status
#lpstat -p Brother_DCP_L2622DW
#lpq -P Brother_DCP_L2622DW                      # Print queue
# 11. Cancel print jobs
#lpq                                             # See job numbers
#cancel 123                                      # Cancel job 123
#cancel -a                                       # Cancel all jobs
# 12. Set default printer (so you don't need -d every time)
#sudo lpadmin -d Brother_DCP_L2622DW
# 13. Print test page
#echo "NixOS Test Page - $(date)" | lp
# 14. Print with specific paper and quality
#lp -o media=A4 -o print-quality=4 -o sides=one-sided document.pdf
# 15. Print HTML (converts automatically)
#echo "<h1>Hello HTML</h1><p>This is a test</p>" | lp -T "HTML Test"
# Common Brother DCP-L2622DW options:
# -o sides=one-sided                    # Single-sided
# -o sides=two-sided-long-edge          # Duplex (flip long edge)
# -o sides=two-sided-short-edge         # Duplex (flip short edge)
# -o media=A4                           # A4 paper
# -o media=Letter                       # US Letter
# -o print-quality=3                    # Draft quality
# -o print-quality=4                    # Normal quality
# -o print-quality=5                    # High quality
# -o ColorModel=Gray                    # Force grayscale
# Useful aliases you can add to ~/.bashrc:
# alias print='lp -d Brother_DCP_L2622DW'
# alias printduplex='lp -d Brother_DCP_L2622DW -o sides=two-sided-long-edge'
# alias printqueue='lpq -P Brother_DCP_L2622DW'
#-------------------------------------------------------------------------------------
# Brother DCP-L2622DW Command Line Scanning Guide
# First, check available scanners
#scanimage -L
# Your Brother scanner devices:
# device `brother4:net1;dev0' is a Brother *DCP-L2622DW DCP-L2622DW
# device `brother5:net1;dev0' is a Brother DCP-L2622DW DCP-L2622DW
# Basic scanning commands:
# 1. Basic scan to PNG (recommended for Brother)
#scanimage --device "brother5:net1;dev0" --format=png > scan.png
# 2. Scan to different formats
#scanimage --device "brother5:net1;dev0" --format=jpeg > scan.jpg
#scanimage --device "brother5:net1;dev0" --format=tiff > scan.tiff
#scanimage --device "brother5:net1;dev0" --format=pnm > scan.pnm
# 3. High resolution scan (300 DPI for documents, 600 DPI for photos)
#scanimage --device "brother5:net1;dev0" --resolution 300 --format=png > document.png
#scanimage --device "brother5:net1;dev0" --resolution 600 --format=png > photo.png
# 4. Different scan modes
#scanimage --device "brother5:net1;dev0" --mode Color --format=png > color-scan.png
#scanimage --device "brother5:net1;dev0" --mode Gray --format=png > gray-scan.png
#scanimage --device "brother5:net1;dev0" --mode Lineart --format=png > bw-scan.png
# 5. Scan specific area (in mm)
#scanimage --device "brother5:net1;dev0" \
#  -l 10 -t 10 -x 100 -y 150 \
#  --format=png > area-scan.png
# -l = left margin, -t = top margin, -x = width, -y = height
# 6. Scan with timestamp filename
#scanimage --device "brother5:net1;dev0" --format=png > "scan-$(date +%Y%m%d-%H%M%S).png"
# 7. Preview scan (low resolution, quick)
#scanimage --device "brother5:net1;dev0" --resolution 75 --format=png > preview.png
# 8. Batch scanning to dated folder
#mkdir -p ~/Scans/$(date +%Y-%m-%d)
#scanimage --device "brother5:net1;dev0" --format=png > ~/Scans/$(date +%Y-%m-%d)/scan-$(date +%H%M%S).png
# 9. Get scanner capabilities/options
#scanimage --device "brother4:net1;dev0" --help
# 10. Using alternative brother4 backend (if brother5 has issues)
#scanimage --device "brother4:net1;dev0" --format=png > scan-brother4.png
# 11. Scan document with optimal settings
#scanimage --device "brother5:net1;dev0" \
#  --resolution 300 \
#  --mode Gray \
#  --format=png > document.png
# 12. Scan photo with optimal settings
#scanimage --device "brother5:net1;dev0" \
#  --resolution 600 \
#  --mode Color \
#  --format=png > photo.png
# 13. Quick scan with auto-detection (may not work reliably)
#scanimage --format=png > auto-scan.png
# 14. Scan to PDF (requires ImageMagick)
#scanimage --device "brother5:net1;dev0" --format=png | convert png:- pdf:scan.pdf
# 15. Multiple page scanning to PDF
#for i in {1..5}; do
#  echo "Place page $i and press Enter"
#  read
#  scanimage --device "brother5:net1;dev0" --format=png > page$i.png
#done
#convert page*.png document.pdf
# Brother DCP-L2622DW specific options (use --help to see all):
# --resolution 75|100|150|200|300|600 dpi
# --mode Color|Gray|Lineart
# --source Flatbed (only flatbed available on DCP-L2622DW)
# --brightness -100 to 100
# --contrast -100 to 100
# Common resolution guide:
# 75-100 DPI:  Preview, web images
# 150 DPI:     Text documents (draft)
# 300 DPI:     Text documents (good quality)
# 600 DPI:     Photos, detailed images
# 1200 DPI:    High-quality photos (slow)
# Useful aliases you can add to ~/.bashrc:
# alias scan='scanimage --device "brother5:net1;dev0" --format=png'
# alias scandoc='scanimage --device "brother5:net1;dev0" --resolution 300 --mode Gray --format=png'
# alias scanphoto='scanimage --device "brother5:net1;dev0" --resolution 600 --mode Color --format=png'
# alias scanpreview='scanimage --device "brother5:net1;dev0" --resolution 75 --format=png'
# Troubleshooting:
# If you get HTML instead of scan data, the scanner service isn't running properly
# If scanning is slow, try lower resolution or brother4 backend
# If colors look wrong, try different --mode settings
{
  # Enable printing with Brother DCP-L2622DW support
  # Go to http://localhost:631/admin and add the printer

  systemd.services.cups = {
    environment = {
      LD_LIBRARY_PATH = lib.mkForce "";
    };
  };

  services.printing = {
    enable = true;
    browsing = false;
    defaultShared = true;
    openFirewall = true;
    drivers = with pkgs; [
      brlaser
    ];
  };

  # Declaratively configure the printer
  hardware.printers = {
    ensurePrinters = [
      {
        name = "Brother_DCP_L2622DW";
        location = "Office";
        description = "Brother DCP-L2622DW";
        deviceUri = "lpd://10.0.150.7/binary_p1";
        model = "drv:///brlaser.drv/br7030.ppd"; # Generic Brother laser driver
        #model = "drv:///brlaser.drv/brl2500d.ppd";
        ppdOptions = {
          PageSize = "A4";
          Duplex = "DuplexNoTumble";
        };
      }
    ];
    ensureDefaultPrinter = "Brother_DCP_L2622DW";
  };

  # Enable scanning support for your multifunction device
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      brscan5 # Brother scanner backend for DCP-L2622DW
    ];
    netConf = "10.0.150.7";
  };

  hardware.sane.brscan5 = {
    enable = true;
    netDevices = {
      "DCP-L2622DW" = {
        model = "DCP-L2622DW";
        ip = "10.0.150.7";
      };
    };
  };

  hardware.sane.brscan4.enable = false;

  # Allow unfree packages (Brother drivers are proprietary)
  nixpkgs.config.allowUnfree = true;

  # Add your user to printing and scanning groups
  users.users.radekp = {
    # Replace YOUR_USERNAME with your actual username
    extraGroups = ["lp" "scanner"];
  };

  # Optional: Enable network discovery for easier printer detection
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  networking.firewall = {
    allowedTCPPorts = [54921 54925 161 515 631 9100];
    allowedUDPPorts = [161];
  };

  # Optional: Install useful printing/scanning utilities
  environment.systemPackages = with pkgs; [
    simple-scan # GUI scanner application
    xsane # Advanced scanner interface
    system-config-printer # GUI printer configuration tool
    brscan5
  ];
}
