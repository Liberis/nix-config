{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "sddm-sugar-dark";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "MarianArlt";
    repo = "sddm-sugar-dark";
    rev = "v${version}";
    sha256 = "sha256-C3qB9hFUeuT5+Dos2zFj5SyQegnghpoFV9wHvE9VoD8=";
  };

  installPhase = ''
    mkdir -p $out/share/sddm/themes/sugar-dark
    cp -r * $out/share/sddm/themes/sugar-dark/
  '';

  meta = {
    description = "Dark theme for SDDM with a sugar-sweet aesthetic";
    homepage = "https://github.com/MarianArlt/sddm-sugar-dark";
  };
}
