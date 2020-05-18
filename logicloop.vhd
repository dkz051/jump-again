entity logicloop is
	port(
		clk,rst: in std_logic; -- we need clock
		left,right,up: in std_logic; -- "keyboard input"
		curX, curY: out integer; -- place of hero
		num_of_map: out integer; -- which map?
		-- if there's no moving parts other than hero, if the status of grid won't change, then,
		-- (X,Y) of hero and number of map, is enough to send to VGA control module
	    )
end entity logicloop;	
architecture logic of logicloop is
	component crash_checker is 
	port(
        clk: in std_logic;
        curX,deltaX, gridX: in x_t; curY,deltaY, gridY: in y_t; -- Xord: 1..640 Yord: 1...480
        grid: in grid_t; -- type of grid, use enumeration?
        nextX: out x_t; nextY: out y_t; -- the modified coordinate(crash into brick?)
        crash: out crash_t; -- 5 possible values: no crash, crash in a direction(WASD) up crash or down crash cause Y speed change to 0
        success, death: out std_logic --whether crashing into brick, succeed, or die
        );
	end component;
	
begin
end architecture logic;
