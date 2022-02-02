{
  description = "Yants devshell";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.devshell.url = "github:numtide/devshell";
  inputs.treefmt.url = "github:numtide/treefmt";
  inputs.alejandra.url = "github:kamadorueda/alejandra";
  inputs.alejandra.inputs.treefmt.url = "github:divnix/blank";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs =
    inputs:
    inputs.flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ] (
      system:
      let
        devshell = inputs.devshell.legacyPackages.${system};
        nixpkgs = inputs.nixpkgs.legacyPackages.${system};
        alejandra = inputs.alejandra.defaultPackage.${system};
        treefmt = inputs.treefmt.defaultPackage.${system};
      in
        {
          devShells.__default = devshell.mkShell {
            name = "Yants";
            packages = [
              alejandra
              treefmt
              nixpkgs.shfmt
              nixpkgs.nodePackages.prettier
            ];
          };
        }
    );
}
