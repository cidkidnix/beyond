{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs: let
    lib = inputs.nixpkgs.lib;
    project = self: self.callCabal2nix "beyond" ./. {};
    haskellPackages = pkgs: pkgs.haskell.packages.ghc948.override {
      overrides = self: super: {
        beyond = project self;
        hid = pkgs.haskell.lib.markUnbroken (pkgs.haskell.lib.doJailbreak super.hid);
      };
    };
    supportedSystems = lib.genAttrs
      [ "x86_64-linux"
        "aarch64-linux"
      ];
  in {
    packages = supportedSystems (system: let
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
    in { default = (haskellPackages pkgs).beyond; });

    devShells = supportedSystems (system: let
      pkgs = inputs.nixpkgs.legacyPackages."${system}";
      hsPkgs = haskellPackages pkgs;
    in {
      default = hsPkgs.shellFor {
        packages = ps: with ps; [ beyond ]; buildInputs = with hsPkgs; [ cabal-install ];
        shellHook = let
          ghcidWrapped = pkgs.writeShellScriptBin "ghcid" ''
            ${hsPkgs.ghcid.bin}/bin/ghcid --command "cabal repl"
          '';
          ghcidUnwrapped = pkgs.writeShellScriptBin "ghcid-unwrapped" ''
            ${hsPkgs.ghcid.bin}/bin/ghcid
          '';
        in ''
          # To find freshly-`cabal install`ed executables
          export PATH=~/.local/bin:${ghcidWrapped}/bin:${ghcidUnwrapped}/bin:$PATH
        '';
      };
      beyond = hsPkgs.shellFor {
        packages = ps: with ps; [ beyond ];
        buildInputs = with hsPkgs; [ cabal-install ];
      };
    });
  };
}
