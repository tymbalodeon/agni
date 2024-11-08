{pkgs}: {
  packages = with pkgs; [
    nodePackages.pnpm
    python311
    uv
  ];
}
