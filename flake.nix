{
  description = "An incremental parsing system for programming tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixCargoIntegration = {
      url = "github:yusdacra/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rustOverlay.follows = "rust-overlay";
    };
  };

  # see also the upstream nixpkgs builder https://github.com/NixOS/nixpkgs/blob/38639e08a03681159e1cd406b02a75b0bc9bcb15/pkgs/development/tools/parsing/tree-sitter/default.nix
  outputs = { nixCargoIntegration, nixpkgs, ... }:
    let
      pkgs = nixpkgs;
      inherit (pkgs) lib stdenv;
    in nixCargoIntegration.lib.makeOutputs {
      root = ./.;
      renameOutputs = { "tree-sitter-cli" = "tree-sitter"; };
      crateOverrides = common: _: rec {
        tree-sitter-cli = prev:
          let inherit (common) pkgs lib stdenv;
          in {
            buildInputs = (prev.buildInputs or [ ])
              ++ (lib.optionals stdenv.isDarwin
                [ pkgs.darwin.apple_sdk.frameworks.Security ]);

            # need emscripten to build tree-sitter.wasm
            nativeBuildInputs = (prev.nativeBuildInputs or [ ])
              ++ [ pkgs.which pkgs.emscripten ];

            # build tree-sitter.wasm for the playground
            preBuild = ''
              ${prev.preBuild or ""}
              bash ./script/build-wasm --debug
            '';

            postInstall = ''
              ${prev.postInstall or ""}
              PREFIX=$out make install
            '';
          };
      };
    };
}
