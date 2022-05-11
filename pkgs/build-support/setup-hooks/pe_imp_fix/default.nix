{ lib
, rustPlatform
, fetchFromGitHub
 }:

rustPlatform.buildRustPackage rec {
  pname = "pe_imp_fix";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "mehmooda";
    repo = pname;
    rev = "0ea619c0937953bb7f6ce9da329019930da5bc27";
    sha256 = "V+fO0Smzqr0ZtliIQUYeTPSEb7rRgyOUtWsJOTgUcdM=";
  };

  cargoSha256 = "HcBV715zDjPHc+mueWFInpg0ijl0hQWd76sCXevn+Rw=";

  meta = with lib; {
    description = "pe_imp_fix";
    homepage = "https://github.com/mehmooda/pe_imp_fix";
    license = licenses.free;
  };
}
