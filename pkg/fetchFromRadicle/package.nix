{
  lib,
  fetchgit,
}: {
  rid,
  rev ? "HEAD",
  ref ? null,
  nid ? null,
  seed ? "ash.radicle.garden",
  ...
} @ args:
assert lib.hasPrefix "rad:" rid;
assert (nid != null) -> ref != null;
  fetchgit (
    {
      url = "https://${seed}/${builtins.substring 4 (-1) rid}.git";
    }
    // (
      if (ref != null)
      then
        (
          if nid == null
          then {
            rev = ref;
          }
          else {
            rev = "refs/namespaces/${nid}/refs/${ref}";
          }
        )
      else {
        inherit rev;
      }
    )
    // (builtins.removeAttrs args ["rid" "rev" "ref" "nid" "seed"])
  )
