print("== SSGD-CC installer ==")

local raw_files_url = "https://raw.githubusercontent.com/Zeragamba/jsg-cc-gate-dialer"
local ref_name = "main"

local dialer_filename = "ssgd.lua"
local address_book_filename = "address-book.lua"

local function download_file(src_path, dest)
  local src_url = raw_files_url .. "/refs/heads/" .. ref_name .. "/src/" .. src_path
  local dest_file = shell.resolve(dest or src_path)
  shell.execute("wget", src_url, dest_file)
end

if fs.exists(dialer_filename) then
  fs.move(dialer_filename, "ssgd.bak.lua")
end

download_file(dialer_filename)

if not fs.exists(address_book_filename) then
  download_file(address_book_filename)
end

print("== SSGD-CC installed! ==")
print()
print("run the following command to edit your address book:")
print("  edit address-book.lua")
print()
print("Safe travels!")