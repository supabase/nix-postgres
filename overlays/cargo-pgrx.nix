final: prev: {
  cargo-pgrx_0_9_8 = prev.cargo-pgrx.overrideAttrs (oldAttrs: rec {
    pname = "cargo-pgrx";
    version = "0.9.8";

    src = prev.fetchCrate {
      inherit version pname;
      hash = "sha256-Sk9fz84EheP+Ohq2e2E1q7dKDPE2Y4QSsHGlNvNb/g0=";
    };

    # NOTE (aseipp): normally, we would just use 'cargoHash' here, but
    # due to a fantastic interaction of APIs, we can't do that so
    # easily, and have to use this incantation instead, which is
    # basically the exact same thing but with 4 extra lines. see:
    #
    # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/5
    cargoDeps = oldAttrs.cargoDeps.overrideAttrs (prev.lib.const {
      name = "${pname}-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-F3/hdS7derrdSprSH4ONrhlhEDxJ52+X9jVFBU5Co8U=";
    });
  });

  buildPgrxExtension_0_9_8 = prev.buildPgrxExtension.override {
    cargo-pgrx = final.cargo-pgrx_0_9_8;
  };
}
