final: prev: {
  postgresql_orioledb_16 = prev.postgresql_16.overrideAttrs (old: {
    pname = "postgresql_16";
    version = "16.2";
    src = prev.fetchurl {
      url = "https://github.com/orioledb/postgres/archive/refs/tags/patches16_23.tar.gz";
      sha256 = "sha256-xWmcqn3DYyBG0FsBNqPWTFzUidSJZgoPWI6Rt0N9oJ4=";
    };

    buildInputs = old.buildInputs ++ [
      prev.bison
      prev.docbook5
      prev.docbook_xsl
      prev.docbook_xsl_ns
      prev.docbook_xml_dtd_45
      prev.flex
      prev.libxslt
      prev.perl
    ];
    doCheck = true;
  });
  pg16_oriole = final.postgresql_orioledb_16;
}
