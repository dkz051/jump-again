maplist = ["map_0.txt", "map_1.txt", "map1.txt", "map2.txt", "map3.txt","map4.txt"]
f = open("map0.mif", "w")
f.write("WIDTH=9;\n")
f.write("DEPTH=%d;\n"%(256*len(maplist)))
f.write("ADDRESS_RADIX=HEX;\n")
f.write("DATA_RADIX=HEX;\n")
f.write("CONTENT BEGIN\n")
mapdata = [[0 for i in range(32) ] for j in range(24)]
cnt = 0
tmp = 0
addr = 0
map_count = 0
for ma in maplist:
    m = open(ma, "r")
    for i in range(0, 24):
        r = m.readline().split()
        for j in range(0, 32):
            mapdata[i][j] = int(r[j])
            cnt += 1
            tmp = (tmp * 8) + mapdata[i][j]
            if cnt == 3:
                f.write("%x:%x;\n"%(addr + map_count * 256,tmp))
                tmp = 0
                cnt = 0
                addr += 1
f.write("END")
