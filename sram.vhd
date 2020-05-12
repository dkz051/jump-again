entity map_reader is
	port(
	cur_map: in integer; --the number of current map, if change: reload
	query_X1, query_Y1, query_X2, query_Y2: in integer;
	type_1, type_2: out grid_t; 
	    );
        type grid_t is (air, brick, deadly, desti, start);
end entity map_reader;


