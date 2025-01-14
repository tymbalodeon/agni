{pkgs}: {
  packages = with pkgs; [
    nodePackages.pnpm
    python313
    ruff
    uv
  ];
}
