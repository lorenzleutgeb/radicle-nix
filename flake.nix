{
  description = "radicle-nix";

  inputs = {
    dream2nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/dream2nix";
    };
    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks = {
      inputs = {
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:cachix/pre-commit-hooks.nix";
    };
    sops-nix = {
      inputs = {
        nixpkgs-stable.follows = "nixpkgs-stable";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:Mic92/sops-nix";
    };
    systems.url = "github:nix-systems/default";
  };

  outputs = {
    self,
    dream2nix,
    flake-utils,
    nixpkgs,
    pre-commit-hooks,
    sops-nix,
    ...
  }: let
    # Take Nixpkgs' lib and update it with the definitions in ./lib.nix
    lib = nixpkgs.lib.recursiveUpdate nixpkgs.lib (import ./lib.nix {inherit (nixpkgs) lib;});

    inherit
      (builtins)
      mapAttrs
      attrValues
      ;

    inherit
      (lib)
      concatMapAttrs
      mapAttrs'
      foldr
      recursiveUpdate
      nameValuePair
      nixosSystem
      filterAttrs
      attrByPath
      mapAttrByPath
      flattenAttrsDot
      flattenAttrsSlash
      optionalAttrs
      ;

    importRadiclePackages = pkgs: let
      callPackage = pkgs.newScope (
        radiclePackages // {inherit callPackage;}
      );

      radiclePackages = import ./pkg {
        inherit (pkgs) lib;
        inherit callPackage dream2nix pkgs;
      };
    in
      radiclePackages;

    rawNixosConfigurations = {};

    rawNixosModules.radicle = ./os/module/services/radicle.nix;

    extendedNixosModules =
      self.nixosModules
      // {
        sops-nix = sops-nix.nixosModules.default;
      };

    extendedNixosConfigurations =
      mapAttrs
      (_: config: nixosSystem {modules = [config ./dummy.nix] ++ attrValues extendedNixosModules;})
      rawNixosConfigurations;
    # Then, define the system-specific outputs.
  in ((flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};

      radiclePackages = importRadiclePackages pkgs;

      toplevel = name: config: nameValuePair "nixosConfigurations/${name}" config.config.system.build.toplevel;

      optionsDoc = pkgs.nixosOptionsDoc {
        options =
          (import (nixpkgs + "/nixos/lib/eval-config.nix") {
            inherit system;
            modules =
              [
                {
                  networking = {
                    domain = "invalid";
                    hostName = "options";
                  };

                  system.stateVersion = "23.05";
                }
              ]
              ++ attrValues self.nixosModules;
          })
          .options;
      };

      /*
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
      */

      nonBrokenRadiclePackages = filterAttrs (_: v: !(attrByPath ["meta" "broken"] false v)) (removeFetchers radiclePackages);

      removeFetchers = x: builtins.removeAttrs x ["fetchFromRadicle" "fetchRadiclePatch"]; # TODO(lorenzleutgeb): Think about fetchers...

      hooks = pre-commit-hooks.lib.${system}.run {
        src = ./.;
        #nativeBuildInputs = with pkgs; [ tree ];
        hooks = {
          actionlint.enable = true;
          alejandra.enable = true;
          mdsh.enable = true;
          markdownlint.enable = true;
        };
      };
    in rec {
      packages =
        nonBrokenRadiclePackages
        // {
          /*
             TODO(lorenzleutgeb)
          page = import ./page {
            inherit lib pkgs self;
            options = optionsDoc.optionsNix;
          };
          */

          options =
            pkgs.runCommand "options.json" {
              build = optionsDoc.optionsJSON;
            } ''
              mkdir $out
              cp $build/share/doc/nixos/options.json $out/
            '';
        };

      checks =
        mapAttrs' toplevel extendedNixosConfigurations
        // {
          pre-commit = hooks.overrideAttrs (old: {
            nativeBuildInputs =
              (old.nativeBuildInputs or [])
              ++ (with pkgs; [
                tree
              ]);
          });
        }
        // (mapAttrs' (name: check: nameValuePair "packages/${name}" check) nonBrokenRadiclePackages);

      devShells.default = pkgs.mkShell {
        buildInputs =
          [
            hooks.enabledPackages
          ]
          ++ (with pkgs; [
            nix-update
            tree
          ]);

        shellHook = let
          banner = pkgs.writeText "radicle-nix-banner" ''
            Welcome!

            If your goal is to update packages, run

            	./update

            If you face any issues, feel free to chat:

            	<https://radicle.zulipchat.com/#narrow/stream/nix>

            Hide this massage by executing

            	touch .banner
          '';
        in
          hooks.shellHook
          + ''
            if ! [ -f .banner ]
            then
              cat ${banner}
            fi
          '';
      };

      formatter = pkgs.writeShellApplication {
        name = "formatter";
        text = ''
          # shellcheck disable=all
          shell-hook () {
            ${hooks.shellHook}
          }

          shell-hook
          pre-commit run --all-files
        '';
      };

      /*
      hydraJobs = let
        passthruTests = concatMapAttrs (name: value:
          optionalAttrs (value ? passthru.tests) {${name} = value.passthru.tests;})
        nonBrokenRadiclePackages;
      in {
        packages.${system} = nonBrokenRadiclePackages;
        tests.${system} = {
          passthru = passthruTests;
        };

        nixosConfigurations.${system} =
          mapAttrs
          (name: config: config.config.system.build.toplevel)
          extendedNixosConfigurations;
      };
      */
    }))
    // {
      nixosConfigurations =
        extendedNixosConfigurations;

      nixosModules =
        {
          unbootable = ./os/module/unbootable.nix;
          default.nixpkgs.overlays = [self.overlays.default];
        }
        // rawNixosModules;

      overlays.default = import ./overlay/default.nix;
    });
}
