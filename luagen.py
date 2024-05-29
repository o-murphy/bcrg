from lupa import LuaRuntime
import os
from pathlib import Path

# Get the current directory
current_directory = os.path.dirname(os.path.abspath(__file__))
print(f"Current directory: {current_directory}")

current_directory = Path(current_directory).as_posix()

# Set up the Lua environment
lua = LuaRuntime(unpack_returned_tuples=True)

# Update the package path to include the current directory
lua_path = f'package.path = package.path .. ";{current_directory}/?.lua"'
print(f"Lua path: {lua_path}")
lua.execute(lua_path)

# Load and execute the Lua script
main_lua_path = os.path.join(current_directory, 'main.lua')
print(f"Executing Lua script: {main_lua_path}")
with open(main_lua_path, 'r') as file:
    script = file.read()

lua.execute(script)
