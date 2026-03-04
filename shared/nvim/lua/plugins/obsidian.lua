return {

  {
    "epwalsh/obsidian.nvim",
    version = "*", -- Recomenda-se usar a versão estável mais recente
    lazy = true,
    ft = "markdown",
    
    -- Carrega apenas se estivermos dentro do cofre (opcional, mas economiza recursos)
    event = {
      "BufReadPre " .. vim.fn.expand("~") .. "/personal/notas/*.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/personal/notas/*.md",
    },

    dependencies = {
      "nvim-lua/plenary.nvim",
      -- Se você usa Telescope, isso ajuda nas buscas
      "nvim-telescope/telescope.nvim", 
    },

    opts = {
      -- 1. Definição do Cofre (Vault)
      workspaces = {
        {
          name = "Personal",
          path = "~/personal/notas",
        },
      },

      -- 2. Onde novas notas são criadas (ex: quando segue um link para uma nota que não existe)
      notes_subdir = "new",
      new_notes_location = "notes_subdir",

      -- 3. Compleção (Crucial para funcionar com Blink/Cmp)
      completion = {
        nvim_cmp = true, -- O obsidian.nvim cria um source 'obsidian' para compleção
        min_chars = 2,
      },

      -- 4. Frontmatter (Metadados)
      disable_frontmatter = false,
      note_id_func = function(title)
        -- Gera IDs legíveis em vez de aleatórios (ex: "Minha Nota" -> "Minha-Nota")
        local suffix = ""
        if title ~= nil then
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          for _ = 1, 4 do suffix = suffix .. string.char(math.random(65, 90)) end
        end
        return tostring(os.time()) .. "-" .. suffix
      end,

      -- 5. Templates Robusto
      templates = {
        subdir = "templates", -- Pasta: ~/personal/notas/templates
        date_format = "%d/%m/%Y",
        time_format = "%H:%M",
        tags = "",
        substitutions = {
          -- Aqui você pode criar variáveis customizadas para usar nos templates
          -- Exemplo no md: {{yesterday}}
          yesterday = function()
            return os.date("%Y-%m-%d", os.time() - 86400)
          end,
        }
      },

      -- 6. UI (Desativada para usar render-markdown sem conflitos)
      ui = {
        enable = true,  -- Deixe o render-markdown cuidar da beleza
      },

      -- 7. Anexos (Imagens)
      attachments = {
        img_folder = "assets/imgs", -- Organização é tudo
      },

      -- 8. Mapeamentos Buffer-Local (Só funcionam dentro de notas)
      mappings = {
        -- "gf" para seguir links (Go File)
        ["gf"] = {
          action = function() return require("obsidian").util.gf_passthrough() end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        -- Toggle checkbox com <leader>ch
        ["<leader>ch"] = {
          action = function() return require("obsidian").util.toggle_checkbox() end,
          opts = { buffer = true },
        },
        -- Enter inteligente (segue link ou cria nova linha)
        ["<cr>"] = {
          action = function() return require("obsidian").util.smart_action() end,
          opts = { buffer = true, expr = true },
        },
      },
    },

    config = function(_, opts)
      local obsidian = require("obsidian")
      obsidian.setup(opts)

      -- === MENU CENTRALIZADO (Obsidian Hub) ===
      -- Acionado por <leader>o
      vim.keymap.set("n", "<leader>o", function()
        local actions = {
          { label = "📝 Nova Nota", cmd = "ObsidianNew" },
          { label = "🔍 Pesquisar Notas (Quick Switch)", cmd = "ObsidianQuickSwitch" },
          { label = "🔎 Pesquisar Texto (Grep)", cmd = "ObsidianSearch" },
          { label = "📅 Nota Diária (Today)", cmd = "ObsidianToday" },
          { label = "📄 Inserir Template", cmd = "ObsidianTemplate" },
          { label = "🔗 Ver Backlinks", cmd = "ObsidianBacklinks" },
          { label = "🖼️ Colar Imagem", cmd = "ObsidianPasteImg" },
          { label = "🏷️ Renomear Nota (com refactor)", cmd = "ObsidianRename" },
          { label = "📂 Mover para Pasta", func = function() 
              -- Exemplo de função customizada dentro do menu
              local current_file = vim.fn.expand("%:p")
              -- Aqui você poderia usar um input para pedir a pasta, ou mover para uma padrão
              print("Função de mover ainda não implementada, edite o config!") 
            end 
          },
        }

        -- Prepara as opções para o menu
        local options = {}
        for i, action in ipairs(actions) do
          options[i] = action.label
        end

        -- Abre o menu usando vim.ui.select (integra com Telescope/Dressing se tiver)
        vim.ui.select(options, {
          prompt = "Obsidian Actions",
        }, function(choice)
          if not choice then return end

          -- Encontra a ação correspondente
          for _, action in ipairs(actions) do
            if action.label == choice then
              if action.cmd then
                vim.cmd(action.cmd)
              elseif action.func then
                action.func()
              end
              return
            end
          end
        end)
      end, { desc = "Obsidian Menu" })
    end,
  },
}
