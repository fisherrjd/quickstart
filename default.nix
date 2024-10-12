{ pkgs ? import
    (fetchTarball {
      name = "jpetrucciani-2024-10-02";
      url = "https://github.com/jpetrucciani/nix/archive/780d3f87919af2b7d36fa4f41e16c7d605cf83c3.tar.gz";
      sha256 = "1h0yxhap82wx9wxq35jydjnas1alz2ybbqnmr1wwyzsc4lb1w020";
    })
    { }
}:
let
  name = "frontend";
  node = pkgs.nodejs_20;


  tools = with pkgs; {
    cli = [
      coreutils
      gh
      nixpkgs-fmt
      docker
      docker-compose
    ];
    go = [
      go
      go-tools
      gopls
    ];
    node = [
      nodejs
      yarn
    ];
    run-caddy = pog {
      name = "run-caddy";
      script = ''
        ${zaddy}/bin/caddy run --config ./conf/Caddyfile --watch "$@"
      '';
    };
    run-frontend = pog {
      name = "run-frontend";
      # TODO Update frontend run bath (not sure what it is yet)
      script = ''
        cd ./frontend/ || exit
        BROWSER=none ${nodejs}/bin/npm start
      '';
    };
    run-backend = pog {
      name = "run-backend";
      # TODO Update backend run bath (run start.sh in /go)
      script = ''
        cd ./go || exit
        ./start.sh
      '';
    };
    run = pog {
      name = "run";
      script = ''
        ${concurrently}/bin/concurrently \
          --names "caddy,react,fastapi" \
          --prefix-colors "cyan,blue,green" \
          "run-caddy" \
          "run-frontend" \
          "run-backend"
      '';
    };
    scripts = pkgs.lib.attrsets.attrValues scripts;

  };

  scripts = with pkgs; { };
  paths = pkgs.lib.flatten [ (builtins.attrValues tools) ];
  env = pkgs.buildEnv {
    inherit name paths; buildInputs = paths;
  };
in
(env.overrideAttrs (_: {
  inherit name;
  NIXUP = "0.0.6";
})) // { inherit scripts; }
