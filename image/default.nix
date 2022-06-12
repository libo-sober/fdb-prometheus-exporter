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
        fromDigest = "sha256:62b8f60c5c8e1717f460bb7af05e558b74feb8ac460ff2abbdd3a98becdc15ce";
      };
      outputHash =
        if stdenv.isx86_64 then
          "sha256-NKAxcX9A1OF27iQGtBk8DWkbu7uF1zo1CwLvdPKjfm4=" else
          "sha256-D2glKVuZLyTJJorA+pQn8VqhBZiI6RzW+EZUs3jZw58=";
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
