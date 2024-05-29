from lupa import LuaRuntime

class LuaScriptExecutor:
    def __init__(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)

    def lua_table_to_list(self, lua_table):
        # Convert LuaTable to a Python list of integers
        return [int(lua_table[i]) for i in range(1, len(lua_table) + 1)]

    def execute_script(self, script: str, *params) -> bytearray:
        # Execute the Lua script
        lua_func = self.lua.execute(script)
        if not lua_func:
            raise ValueError("Lua script did not return a callable function")

        # Call the Lua function with the specified parameters
        bmp_data_table = lua_func(*params)

        # Convert the LuaTable to a list of integers
        bmp_data_list = self.lua_table_to_list(bmp_data_table)

        # Convert the list of integers to a bytearray
        bmp_bytearray = bytearray(bmp_data_list)
        return bmp_bytearray

# Lua script with function definition
with open("imagegen.lua") as fp:
    lua_script = fp.read()

# Create an instance of the LuaScriptExecutor and execute the script with parameters
executor = LuaScriptExecutor()
bmp_bytearray = executor.execute_script(lua_script, 100, 100, 255, 0, 0)  # 100x100 image, red color

# Save the bytearray to a file to verify
with open('output.bmp', 'wb') as bmp_file:
    bmp_file.write(bmp_bytearray)