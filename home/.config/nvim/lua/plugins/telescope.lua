-- https://github.com/nvim-telescope/telescope.nvim

local function find_files()
	if vim.fn.has("win32") == 1 or string.find(vim.loop.os_uname().release, "arch") ~= nil then
		return { find_command = { "fd", "--follow", "--hidden" } }
	else
		return { find_command = { "fdfind", "--follow", "--hidden" } }
	end
end

return {
	{
		"nvim-telescope/telescope.nvim",
		version = "*",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				config = function()
					require("telescope").load_extension("fzf")
				end,
			},
		},
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "TELESCOPE Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "TELESCOPE Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "TELESCOPE List Buffers" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "TELESCOPE Find Help" },
			{ "<leader>fk", "<cmd>Telescope keymaps<cr>",    desc = "TELESCOPE Find Keymaps" },
			{ "<leader>fo", "<cmd>Telescope oldfiles<cr>",   desc = "TELESCOPE Find Old Files" },
		},
		opts = {
			defaults = {
				layout_config = { prompt_position = "top" },
				prompt_prefix = "> ",
				selection_caret = "> ",
				sorting_strategy = "ascending",
			},
			pickers = {
				find_files = find_files(),
			},
		},
	},
}
