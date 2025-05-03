print("== SSGD-CC installer ==")

local install_dir = "/" .. shell.dir()
local raw_files_url =
	"https://raw.githubusercontent.com/Zeragamba/jsg-cc-gate-dialer"
local ref_name = "0.2.1"

local function download_file(src_path, dest_path)
	local src_url =
		raw_files_url .. "/refs/heads/" .. ref_name .. "/" .. src_path
	shell.execute("wget", src_url, dest_path)
end

local files = { "src/ssgd.lua", "src/lib/ui/main-menu.lua" }

for i, file in ipairs(files) do
	local dest_path = shell.resolve(install_dir, file)

	if fs.exists(dest_path) then
		fs.delete(dest_path)
	end

	print(line)
end

download_file(dialer_filename)

local address_book_file = shell.resolve(address_book_filename)
if not fs.exists(address_book_file) then
	download_file(address_book_filename)
end

print("== SSGD-CC installed! ==")
print()
print("run the following command to edit your address book:")
print("  edit address-book.lua")
print()
print("Safe travels!")
