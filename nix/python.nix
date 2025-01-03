{pkgs}: {
  packages = with pkgs; [
    nodePackages.pnpm
    # TODO fix this
    # py-spy
    python311
    ruff
    uv
  ];
}
