{pkgs}: {
  packages = with pkgs; [
    git-cliff
    lychee
    nodePackages.pnpm
    python311Packages.pre-commit-hooks
    uv
  ];
}
