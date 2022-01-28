{
  description = "FDB Prometheus Exporter";

  inputs = {
    hotPot.url = "github:shopstic/nix-hot-pot";
    nixpkgs.follows = "hotPot/nixpkgs";
    flakeUtils.follows = "hotPot/flakeUtils";
    gomod2nix = {
      url = "github:tweag/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.utils.follows = "flakeUtils";
    };
    fdb.url = "github:shopstic/nix-fdb";
  };

  outputs = { self, nixpkgs, flakeUtils, hotPot, gomod2nix, fdb }:
    flakeUtils.lib.eachSystem [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              gomod2nix.overlay
            ];
          };
          hotPotPkgs = hotPot.packages.${system};
          vscodeSettings = pkgs.writeTextFile {
            name = "vscode-settings.json";
            text = builtins.toJSON {
              "yaml.schemaStore.enable" = true;
              "yaml.schemas" = {
                "https://json.schemastore.org/github-workflow.json" = ".github/workflows/*.yaml";
              };
              "nix.enableLanguageServer" = true;
              "nix.formatterPath" = pkgs.nixpkgs-fmt + "/bin/nixpkgs-fmt";
              "nix.serverPath" = pkgs.rnix-lsp + "/bin/rnix-lsp";
            };
          };
          fdbBindings = fdb.defaultPackage.${system}.bindings;
          fdbLib = fdb.defaultPackage.${system}.lib;
          fdbPrometheusExporter = pkgs.callPackage ./build.nix
            {
              inherit fdbBindings fdbLib;
            };
        in
        rec {
          defaultPackage = fdbPrometheusExporter;
          packages = pkgs.lib.optionalAttrs pkgs.stdenv.isLinux {
            image = pkgs.callPackage ./image {
              inherit (pkgs) dumb-init;
              inherit fdbLib fdbPrometheusExporter;
              buildahBuild = pkgs.callPackage hotPot.lib.buildahBuild;
            };
          };
          devShell = pkgs.mkShellNoCC {
            shellHook = ''
              mkdir -p ./.vscode
              cat ${vscodeSettings} > ./.vscode/settings.json
            '';
            buildInputs = [ gomod2nix.defaultPackage.${system} ] ++ builtins.attrValues {
              inherit (hotPotPkgs)
                manifest-tool
                ;
              inherit (pkgs)
                skopeo
                awscli2
                go
                binutils
                ;
            };
          };
        }
      );
}
