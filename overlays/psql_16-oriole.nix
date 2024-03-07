final: prev: {
  postgresql_16 = prev.postgresql_16.overrideAttrs (old: {
    pname = "postgresql_16";
    version = "16_24";
    src = prev.fetchurl {
      url = "https://github.com/orioledb/postgres/archive/refs/heads/patches16-tableam-compat-2.tar.gz";
      sha256 = "sha256-CoUSk+sWJ3OEzfDqQWS9kG6HK5D4vQiGbLURazCceNU=";
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
  });
  postgresql_orioledb_16 = final.postgresql_16;
}
