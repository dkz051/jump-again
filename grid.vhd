entity crash_checker is
	port(
	clk: in std_logic;
	curX,deltaX, gridX: in x_t; curY,deltaY, gridY: in y_t; -- Xord: 1..640 Yord: 1...480
	grid: in grid_t; -- type of grid, use enumeration?
	nextX: out x_t; nextY: out y_t; --Ð the modified coordinate(crash into brick?)
	crash,success, death: out std_logic --whether crashing into brick, succeed, or die
	    );
	type grid_t is (air, brick, deadly, desti, start);
end entity grid;	
architecture grid_arch of crash_checker is

begin
	process(clk) is --this clk don't need a high frequency. same as fps, at most 60Hz is enough 
		begin
			case grid is
				when air =>

				when brick =>

				when deadly =>
				
				when desti =>
				
				when start =>

		end process;
end architecture grid_arch;
