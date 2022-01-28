{ stdenv
, lib
, dumb-init
, fdbLib
, writeTextFile
, buildahBuild
, dockerTools
, fdbPrometheusExporter
}:
let
  name = "fdb-prometheus-exporter";
  baseImage = buildahBuild
    {
      name = "${name}-base";
      context = ./context;
      buildArgs = {
        fromDigest = "sha256:b5a61709a9a44284d88fb12e5c48db0409cfad5b69d4ff8224077c57302df9cf";
      };
      outputHash =
        if stdenv.isx86_64 then
          "sha256-LgAWO/2cXjninsxrkARiIh+iNsGMG/Uo3a7dZ0PfkH0=" else
          "sha256-AgXJgEJO5DttULFAPxuhCtZIX1Pfe5AaVoyWo6Q5TfE=";
    };
  entrypoint = writeTextFile {
    name = "entrypoint";
    executable = true;
    text = ''
      #!/usr/bin/env bash
      FDB_CONNECTION_STRING=''${FDB_CONNECTION_STRING:-""}
  
      if [[ "''${FDB_CONNECTION_STRING}" != "" ]]; then
      echo "FDB_CONNECTION_STRING=''${FDB_CONNECTION_STRING}"
      export FDB_CLUSTER_FILE=''${FDB_CLUSTER_FILE:-"/home/app/fdb.cluster"}
      echo "FDB_CLUSTER_FILE=''${FDB_CLUSTER_FILE}"
  
      echo "''${FDB_CONNECTION_STRING}" > "''${FDB_CLUSTER_FILE}"
      fi

      exec dumb-init -- "${fdbPrometheusExporter}"/bin/${name} "$@"
    '';
  };
in
dockerTools.buildLayeredImage
{
  inherit name;
  fromImage = baseImage;
  config = {
    Env = [
      "LD_LIBRARY_PATH=${fdbLib}"
      "PATH=${lib.makeBinPath [ dumb-init ]}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
    ];
    Entrypoint = [ entrypoint ];
  };
}
