{pkgs}: {
  packages = with pkgs; [
    git-cliff
    lychee
    nodePackages.pnpm
    pdm
    python311
    python311Packages.pre-commit-hooks
  ];
}
