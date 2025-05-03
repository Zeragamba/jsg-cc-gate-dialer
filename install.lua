print("== SSGD-CC installer ==")

local raw_files_url = "https://raw.githubusercontent.com/Zeragamba/jsg-cc-gate-dialer"
local ref_name = "0.2.1"

local function download_file(src_path, dest_path)
    local src_url = raw_files_url .. "/refs/heads/" .. ref_name .. "/src/" .. src_path
    shell.execute("wget", src_url, dest_path or src_path)
end

local files = {
    "ssgd.lua",
    "lib/errors.lua",
    "lib/stargate.lua",
    "lib/ui/main-menu.lua",
}

for _, file in ipairs(files) do
    local dest_path = shell.resolve(file)

    if fs.exists(dest_path) then
        fs.delete(dest_path)
    end

    download_file(file, dest_path)
end

local address_book_file = shell.resolve("address-book.lua")
if not fs.exists(address_book_file) then
    download_file("address-book.lua")
end

local versionFile = fs.open(shell.resolve('lib/version.lua'), "w")
versionFile.write("return \"" .. ref_name .. "\"")
versionFile.close()

print("== SSGD-CC installed! ==")
print()
print("run the following command to edit your address book:")
print("  edit address-book.lua")
print()
print("Safe travels!")
