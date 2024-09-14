{
  lib,
  stdenv,
  runCommandNoCC,
  python3,
  fetchArtifact,
}: {
  pname,
  version,
  src,
  dependencyFilter ? depSpec: true,
  repositories ? ["https://plugins.gradle.org/m2/" "https://repo1.maven.org/maven2/"],
  verificationFile ? "gradle/verification-metadata.xml",
}: let
  filteredSrc = lib.sources.cleanSourceWith {
    inherit src;
    filter = path: type: null != builtins.match ".*/${verificationFile}";
  };

  depSpecs = builtins.filter dependencyFilter (
    # Read all build and runtime dependencies from the verification-metadata XML
    builtins.fromJSON (builtins.readFile (
      stdenv.mkDerivation (finalAttrs: {
        pname = "depSpecs";
        src = ./.;
        
        buildPhase = ''
          ${python3}/bin/python3 ${./parse.py} ${filteredSrc}/${verificationFile} ${builtins.toString (builtins.map lib.escapeShellArg repositories)} > depSpecs.json
        '';

        installPhase = ''
          cp depSpecs.json $out 
        '';

        meta = {
          description = "bla";
        };
      })
    ))
  );
  mkDep = depSpec: {
    inherit (depSpec) urls path name hash component;
    jar = fetchArtifact {
      inherit (depSpec) urls hash name;
    };
  };
  dependencies = builtins.map (depSpec: mkDep depSpec) depSpecs;

  # write a dedicated script for the m2 repository creation. Otherwise, the m2Repository derivation might crash with 'Argument list too long'
  m2Repository =
    runCommandNoCC "${pname}-${version}-m2-repository"
    {src = filteredSrc;}
    (
      "mkdir $out"
      + lib.concatMapStringsSep "\n" (dep: "mkdir -p $out/${dep.path}\nln -s ${builtins.toString dep.jar} $out/${dep.path}/${dep.name}") dependencies
    );
in {inherit dependencies m2Repository;}
