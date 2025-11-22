-- NixOS detection: Sets vim.g.system_id = 'nixos' if running on NixOS

local system_name = vim.loop.os_uname().sysname

if system_name == 'Linux' then
  local file = io.open('/etc/os-release', 'r')
  if file then
    local content = file:read('*all')
    file:close()
    if string.find(content, 'ID=nixos') then
      vim.g.system_id = 'nixos'
    end
  end
end
