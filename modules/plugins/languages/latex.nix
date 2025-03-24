{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.lists) isList;
  inherit (lib.meta) getExe;
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
        example = "TODO";
        type = either package (listOf str);
        default = pkgs.texlab;
      };
      # buildTool = mkOption {
      # description = "latex build package, or the command to run as a list of strings";
      # example = "TODO";
      # type = either package (listOf str);
      # default = pkgs.texlivePackages.latexmk;
      # };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf cfg.lsp.enable {
      vim.lsp.lspconfig.enable = true;
      vim.lsp.lspconfig.sources.texlab = ''
        lspconfig.texlab.setup {
          cmd =
        ${
          if isList cfg.lsp.package
          then expToLua cfg.lsp.package
          else "{'${getExe cfg.lsp.package}'},"
        }
          filetypes = { 'tex', 'plaintex', 'bib' },
          root_dir = require('lspconfig.util').root_pattern('.git', '.latexmkrc', '.texlabroot', 'texlabroot', 'Tectonic.toml'),
          single_file_support = true,
          settings = {
            texlab = {
              rootDirectory = nil,
              build = {
                executable =
        ${
          # if isList cfg.lsp.buildTool
          # then expToLua cfg.lsp.buildTool
          # else ''{'${getExe cfg.lsp.buildTool}'}''
          # latemx doesn't specify a default program, so do this instead:
          "'${pkgs.texlivePackages.latexmk}/bin/latexmk'"
        },
                args = { '-pdf', '-interaction=nonstopmode', '-synctex=1', '%f' },
                onSave = true,
                forwardSearchAfter = false,
              },
              forwardSearch = {
                executable = nil,
                args = {},
              },
              chktex = {
                onOpenAndSave = true,
                onEdit = true,
              },
              diagnosticsDelay = 300,
              latexFormatter = 'latexindent',
              latexindent = {
                ['local'] = nil,
                modifyLineBreaks = false,
              },
              bibtexFormatter = 'texlab',
              formatterLineLength = 80,
            },
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
