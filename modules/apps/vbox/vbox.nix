{...}: {
  virtualisation.virtualbox.host = {
    enable = true;
    enableExtensionPack = true;
  };

  virtualisation.virtualbox.guest = {
    enable = true;
    dragAndDrop = true;
  };

  users.extraGroups.vboxusers.members = ["radekp"];
}
