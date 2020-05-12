entity mover is
	-- mover don't care about grid crash 
	-- mover cares about "keyboard" input and "gravity" 
	-- y speed is variable, x speed is not variable
	port(
		-- x_t, y_t, s_t are all integer types
		-- x_t, y_t for coordinate, s_t for speed
		-- should we use higher resolution than 640*480 in computing?
		-- not much overhead if x is 0 to 64000, y is 0 to 48000 when physics simulation?	
		left, up, right: in std_logic;
		clk: in std_logic;
		curX: in x_t; curY: in y_t;
		curYspeed: in s_t; -- speed type
		deltaX: out x_t; deltaY: out y_t;
		nxtYspeed: out s_t; -- speed type
	    -- delta X, Y, need to be modified by crach checker
	    );
end entity;
architecture move of mover is 
	process(clk) is  -- 60Hz? update the position 60 times in a second
	begin
	end process;
end architecture move;
