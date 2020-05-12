entity map_reader is
	port(
	cur_map: in integer; --the number of current map, if change: reload
	-- store the map data of cur_map inside map_reader
	query_X1, query_Y1, query_X2, query_Y2: in integer;
	type_1, type_2: out grid_t; 
	addr: out std_logic_vector(0 to 19);
	readbit: in std_logic; -- addr, readbit: connect to ram/rom chip
	    );
        type grid_t is (air, brick, deadly, desti, start);
end entity map_reader;


