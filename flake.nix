{
  description = "Sidecar Nix developer environment for TradingAgents";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          linuxLibraryPath = pkgs.lib.optionalString pkgs.stdenv.isLinux
            "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}";
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              python313
              uv
            ];

            shellHook = ''
              export UV_PYTHON="${pkgs.python313}/bin/python3.13"
              ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
                export LD_LIBRARY_PATH="${linuxLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              ''}
            '';
          };
        });

      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          linuxLibraryPath = pkgs.lib.optionalString pkgs.stdenv.isLinux
            "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}";
          runtimePrelude = ''
            export UV_PYTHON="${pkgs.python313}/bin/python3.13"
            ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
              export LD_LIBRARY_PATH="${linuxLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            ''}
            uv sync --frozen
            uv pip install --python .venv/bin/python langgraph-checkpoint-sqlite==2.0.11
          '';
        in
        {
          cli = pkgs.writeShellApplication {
            name = "tradingagents-cli";
            runtimeInputs = with pkgs; [
              python313
              uv
            ];
            text = ''
              ${runtimePrelude}
              exec .venv/bin/tradingagents "$@"
            '';
          };

          verify = pkgs.writeShellApplication {
            name = "tradingagents-verify";
            runtimeInputs = with pkgs; [
              python313
              uv
            ];
            text = ''
              ${runtimePrelude}
              uv pip install --python .venv/bin/python pytest==8.4.2
              .venv/bin/python -m pytest
            '';
          };
        });

      apps = forAllSystems (system: {
        cli = {
          type = "app";
          program = "${self.packages.${system}.cli}/bin/tradingagents-cli";
        };

        verify = {
          type = "app";
          program = "${self.packages.${system}.verify}/bin/tradingagents-verify";
        };
      });
    };
}
