{
  cacert,
  lib,
  git,
  coreutils,
  writeText,
  less,
  stdenvNoCC,
}: {
  oid,
  nid,
  rid,
  seed ? "ash.radicle.garden",
  hash,
  ...
} @ args:
assert lib.hasPrefix "rad:" rid; let
  shortRid = builtins.substring 4 (-1) rid;
in
  stdenvNoCC.mkDerivation {
    name = "${shortRid}-${nid}-patch-${oid}";
    nativeBuildInputs = [git coreutils less];
    outputHashAlgo = null;
    outputHashMode = "recursive";
    outputHash =
      if hash == ""
      then lib.fakeHash
      else hash;
    buildCommand = ''
      git clone "https://${seed}/${shortRid}.git" ${shortRid}
      cd ${shortRid}
      git fetch origin "refs/namespaces/${nid}/refs/heads/patches/${oid}:patch"
      git diff origin/HEAD..patch > $out
    '';
    passAsFile = ["buildCommand"];

    GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";
  }
