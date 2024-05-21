{
  fetchgit,
  radicle-node,
  unstableGitUpdater,
}:
radicle-node.overrideAttrs (old: rec {
  version = "064ece32ac0a0bd0efe4f459dcb0462bafc236e6";

  src = fetchgit {
    inherit (old.src) url;
    rev = "064ece32ac0a0bd0efe4f459dcb0462bafc236e6";
    hash = "sha256-IDLai0nnjTL54z3J7XmFKCndRiMLrhdhPF2YKGPgDlU=";
  };

  cargoHash = "sha256-IDLai0nnjTL54z3J7XmFKCndRiMLrhdhPF2YKGPgDlU=";

  passthru =
    (old.passthru or {})
    // {
      updateScript = unstableGitUpdater {branch = "064ece32ac0a0bd0efe4f459dcb0462bafc236e6";};
    };

  meta = (old.meta or {}) // {broken = true;};
})
