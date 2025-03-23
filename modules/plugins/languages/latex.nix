{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.meta) getExe;
  inherit (lib.lists) isList;
  inherit (lib.types) either listOf package str;
  inherit (lib.nvim.types) mkGrammarOption;
  inherit (lib.nvim.lua) expToLua;

  cfg = config.vim.languages.latex;
in {
  options.vim.languages.latex = {
    enable = mkEnableOption "LaTeX language support";

    treesitter = {
      enable = mkEnableOption "LaTeX treesitter" // {default = config.vim.languages.enableTreesitter;};
      package = mkGrammarOption pkgs "latex";
    };

    lsp = {
      enable = mkEnableOption "LaTeX LSP support (texlab)" // {default = config.vim.languages.enableLSP;};
      package = mkOption {
        description = "latex language server package, or the command to run as a list of strings";
        example = ''[lib.getExe pkgs.texlab "-data" "~/.cache/jdtls/workspace"]'';
        type = either package (listOf str);
        default = pkgs.texlab;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.texlab = ''
        lspconfig.texlab.setup {
          capabilities = capabilities,
          on_attach = default_on_attach,
          cmd = ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else ''{'${cfg.lsp.package}/bin/texlab'}''
        },
        }
      '';
    })

    (mkIf cfg.treesitter.enable {
      vim.treesitter.enable = true;
      vim.treesitter.grammars = [cfg.treesitter.package];
    })
  ]);
}
