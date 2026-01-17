{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.0.1-rc30";

  # Map Nix system to Sprite's architecture naming
  archMap = {
    "x86_64-linux" = {
      arch = "amd64";
      sha256 = "9b6f4192987061133a8fb6aa8a0cc21202dace7799ce814240112aa721118305";
    };
    "aarch64-linux" = {
      arch = "arm64";
      sha256 = "19a38cef766cfecf45ea714a93568ac5b72a0e175ab80948ccc909325df50d12";
    };
  };

  # Get the architecture-specific data for the current system
  archData = archMap.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  arch = archData.arch;
in
stdenv.mkDerivation rec {
  pname = "sprite-cli";
  inherit version;

  src = fetchurl {
    url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-${arch}.tar.gz";
    sha256 = archData.sha256;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 sprite $out/bin/sprite

    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI tool for Sprites - stateful sandbox environments by Fly.io";
    homepage = "https://sprites.dev";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "sprite";
  };
}
