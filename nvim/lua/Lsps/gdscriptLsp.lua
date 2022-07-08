require('Lsps/defaultLspConf')
require'lspconfig'.gdscript.setup{
	capabilities = capabilities,
	cmd = { "ncat", "localhost", "6008" },
	on_attach = function (client)
		local _notify = client.notify
		client.notify = function (method, params)
			if method == 'textDocument/didClose' then
				-- Godot doesn't implement didClose yet
                                return
			end
			_notify(method, params)
		end
	end
}
