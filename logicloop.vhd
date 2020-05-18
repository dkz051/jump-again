library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity logicloop is
	port(
		clk,rst: in std_logic; -- we need clock clk: 100 MHz
		keyLeft,keyRight,keyUp: in std_logic; -- "keyboard input"
		curX: out std_logic_vector(9 downto 0);
		curY: out std_logic_vector(8 downto 0);
		num_of_map: out integer  -- which map?
		-- if there's no moving parts other than hero, if the status of grid won't change, then,
		-- (X,Y) of hero and number of map, is enough to send to VGA control module
	    );
end entity logicloop;	
architecture logic of logicloop is
--	component crash_checker is 
--	port(
--        clk: in std_logic;
--        curX,deltaX, gridX: in x_t; curY,deltaY, gridY: in y_t; -- Xord: 1..640 Yord: 1...480
--        grid: in grid_t; -- type of grid, use enumeration?
--        nextX: out x_t; nextY: out y_t; -- the modified coordinate(crash into brick?)
--        crash: out crash_t; -- 5 possible values: no crash, crash in a direction(WASD) up crash or down crash cause Y speed change to 0
--        success, death: out std_logic --whether crashing into brick, succeed, or die
--        );
--	end component;
	signal heroX: std_logic_vector(9 downto 0);
	signal heroY: std_logic_vector(8 downto 0);
	signal clk_counter: integer;
	signal clk2: std_logic;
begin
	curX <= heroX;
	curY <= heroY;
	num_of_map <= 0;
	process(clk,rst)
	begin
		if rst = '0' then
			clk_counter <= 0;
			clk2 <= '0';
		elsif rising_edge(clk) then
			if clk_counter = 1000000 then
				clk2 <= not clk2; -- clk2: 50Hz
			end if;
		end if;
		
	end process;
	process(clk2,rst)
	begin
		if rst = '0' then
		else
			if keyLeft = '0' and keyRight = '1' then
				if heroX <620 then
					heroX <= heroX + 1;
				end if;
			elsif keyLeft = '1' and keyRight = '0' then
				if heroX > 0 then
					heroX <= heroX - 1;
				end if;
			end if;
		end if;
	end process;
end architecture logic;
