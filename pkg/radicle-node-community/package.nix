{
  radicle-node,
  fetchRadiclePatch,
}:
radicle-node.overrideAttrs (old: {
  name = "radicle-node-community";
  patches =
    (old.patches or [])
    ++ [
      (fetchRadiclePatch {
        # systemd Socket Activation
        rid = "rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5";
        nid = "z6MkkPvBfjP4bQmco5Dm7UGsX2ruDBieEHi8n9DVJWX5sTEz";
        oid = "b25bed2522ef91a5afdb9ee157bd16af20063cea";
        hash = "sha256-LFFHZvcDoAvq3wT8JA4tydj1hco9gZhxxFibCyU/Hf8=";
      })
    ];

  meta = (old.meta or {}) // {broken = true;};
})
