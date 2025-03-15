print("== SSGD-CC installer ==")

local raw_files_url = "https://raw.githubusercontent.com/Zeragamba/jsg-cc-gate-dialer"
local ref_name = 'main'

local function download_file(src_path, dest)
    local src_url = raw_files_url .. "/refs/heads/" .. ref_name .. "/src/" .. src_path
    local dest_file = shell.resolve(dest or src_path)
    shell.execute("wget", src_url, dest_file)
end

download_file('ssgd.lua')

if not fs.exists('address-book.lua') then
    download_file("address-book.lua")
end

print("== SSGD-CC installed! ==")
print("run the following command to edit your address book:")
print("  edit address-book.lua")