{ pkgs, ... }:

let
  localPackages = import ../../../packages { inherit pkgs; };
  goTools = localPackages.go-tools;
in
{
  home.packages = with pkgs; [
    cmake
    gcc
    git
    gnumake
    go_1_27
    python312

    # Go service tooling, latest releases built with Go 1.27: linters/formatters
    # (v2 bundles gofumpt and goimports), OpenAPI codegen and SQL migrations.
    goTools.golangci-lint
    goTools.oapi-codegen
    goTools.goose

    localPackages.postman
  ];
}
