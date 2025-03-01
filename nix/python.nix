{pkgs}: {
  packages = with pkgs; [
    nodePackages.pnpm
    python313Packages.pipx
    python313
    ruff
    uv
  ];
}
