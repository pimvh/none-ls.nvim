local stub = require("luassert.stub")

local code_actions = require("null-ls.builtins").code_actions

local diagnostic_get = stub(vim.diagnostic, "get")
local nvim_set_lines = stub(vim.api, "nvim_buf_set_lines")
local nvim_cmd = stub(vim.api, "nvim_command")

describe("code_actions regal", function()
    local handler = code_actions.regal._opts.handler

    it("should create ignore rule action matching cursor location", function()
        local params = {
            bufnr = 1,
            row = 2,
            col = 5,
            content = { "normal line", "line with diagnostic" },
        }

        local d1 = { source = "regal", col = 2, end_col = 10, code = "code1" }
        local d2 = { source = "regal", col = 4, end_col = 10, code = "code2" }
        local d3 = { source = "regal", col = 10, end_col = 20, code = "code3" }

        diagnostic_get.returns({ d1, d2, d3 })

        local actions = handler(params)

        assert.equals(2, vim.tbl_count(actions))
        assert.equals("Ignore Regal rule code1 for this line", actions[1].title)
        assert.equals("Ignore Regal rule code2 for this line", actions[2].title)
    end)

    it("should insert new ignore comment above current line", function()
        local params = {
            bufnr = 1,
            row = 2,
            col = 5,
            content = { "normal line", "line with diagnostic" },
        }

        local d = { source = "regal", lnum = 1, col = 2, end_col = 10, code = "code1" }

        diagnostic_get.returns({ d })

        local actions = handler(params)

        assert.equals(1, vim.tbl_count(actions))
        actions[1].action()

        assert.stub(nvim_set_lines).was_called_with(params.bufnr, d.lnum, d.lnum, false, { "# regal ignore:code1" })
        assert.stub(nvim_cmd).was_called_with("write")
    end)

    it("should update existing ignore comment above current line", function()
        local params = {
            bufnr = 1,
            row = 2,
            col = 5,
            content = { "# regal ignore:aaa,bbb", "line with diagnostic" },
        }

        local d = { source = "regal", lnum = 1, col = 2, end_col = 10, code = "code1" }

        diagnostic_get.returns({ d })

        local actions = handler(params)

        assert.equals(1, vim.tbl_count(actions))
        actions[1].action()

        assert
            .stub(nvim_set_lines)
            .was_called_with(params.bufnr, d.lnum - 1, d.lnum, false, { "# regal ignore:aaa,bbb,code1" })
        assert.stub(nvim_cmd).was_called_with("write")
    end)
end)
