{ lib
, fetchurl
, runCommandNoCC
, fdbBindings
, fdbLib
, buildGoApplication
}:
buildGoApplication rec {
  pname = "fdb-prometheus-exporter";
  version = "2.0.0";
  src = ./src;
  modules = ./src/gomod2nix.toml;
  CGO_ENABLED = "1";
  CGO_CFLAGS = "-I${fdbBindings}";
  CGO_LDFLAGS = "-L${fdbLib}";
}

