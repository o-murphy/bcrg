local function create_bmp(width, height, r, g, b)
    local function int_to_bytes(int, size)
        local res = {}
        for i = 1, size do
            res[i] = int % 256
            int = math.floor(int / 256)
        end
        return res
    end

    local bmp_header = {0x42, 0x4D}  -- 'BM' header
    for _, v in ipairs(int_to_bytes(54 + 3 * width * height, 4)) do table.insert(bmp_header, v) end  -- file size
    table.insert(bmp_header, 0x00)
    table.insert(bmp_header, 0x00)
    table.insert(bmp_header, 0x00)
    table.insert(bmp_header, 0x00)  -- reserved
    for _, v in ipairs(int_to_bytes(54, 4)) do table.insert(bmp_header, v) end  -- data offset

    local dib_header = {0x28, 0x00, 0x00, 0x00}  -- DIB header size
    for _, v in ipairs(int_to_bytes(width, 4)) do table.insert(dib_header, v) end  -- width
    for _, v in ipairs(int_to_bytes(height, 4)) do table.insert(dib_header, v) end  -- height
    table.insert(dib_header, 0x01)
    table.insert(dib_header, 0x00)  -- color planes
    table.insert(dib_header, 0x18)
    table.insert(dib_header, 0x00)  -- bits per pixel
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)  -- compression
    for _, v in ipairs(int_to_bytes(3 * width * height, 4)) do table.insert(dib_header, v) end  -- image size
    for _, v in ipairs(int_to_bytes(2835, 4)) do table.insert(dib_header, v) end  -- horizontal resolution
    for _, v in ipairs(int_to_bytes(2835, 4)) do table.insert(dib_header, v) end  -- vertical resolution
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)  -- colors in color table
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)
    table.insert(dib_header, 0x00)  -- important color count

    local bmp_data = {}
    for y = 1, height do
        for x = 1, width do
            table.insert(bmp_data, b)  -- Blue pixel
            table.insert(bmp_data, g)  -- Green pixel
            table.insert(bmp_data, r)  -- Red pixel
        end
    end

    -- Combine headers and pixel data
    local bmp_file = {}
    for i = 1, #bmp_header do
        table.insert(bmp_file, bmp_header[i])
    end
    for i = 1, #dib_header do
        table.insert(bmp_file, dib_header[i])
    end
    for i = 1, #bmp_data do
        table.insert(bmp_file, bmp_data[i])
    end

    return bmp_file
end

return create_bmp