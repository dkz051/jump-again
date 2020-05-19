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
	component mover is
		port(
		-- x_t, y_t, s_t are all integer types
		-- x_t, y_t for coordinate, s_t for speed
		-- should we use higher resolution than 640*480 in computing?
		-- not much overhead if x is 0 to 64000, y is 0 to 48000 when physics simulation?	
		-- mover consider deltaX, deltaY (0 or 1), not absolute X, Y
		clk, rst: in std_logic; -- clk is very important for this component!
		keyLeft, keyUp, keyRight: in std_logic;
		equalX, equalY, plusX, plusY: out std_logic  -- equalX: X+=0 plusX: X+=1(move right) plusY: Y+=1(move down)
	    -- delta X, Y, need to be modified by crach checker
	    ); -- when rst, set speed_y to 0, then free falling
	end component;
	signal heroX: std_logic_vector(9 downto 0);
	signal heroY: std_logic_vector(8 downto 0);
	signal clk_counter: integer;
	signal clk2: std_logic; 
	signal clk2_counter: integer;
	signal x_counter: integer;
	signal equalX, equalY, plusX, plusY: std_logic;
begin

	curX <= heroX;
	curY <= heroY;
	num_of_map <= 0;
	move: mover port map(clk2, rst, keyLeft, keyRight, keyUp, equalX, equalY, plusX, plusY);
	process(clk,rst)
	begin
		if rst = '0' then
			clk_counter <= 0;
			clk2 <= '0';
		elsif rising_edge(clk) then
			clk_counter <= clk_counter + 1;
			if clk_counter = 100000 then
				clk2 <= not clk2; -- clk2: 500Hz the frequency is high, so that we move 1 pixel or 0 pixel in one cycle
										-- mover: return direction: left/right/no movement?
										-- simplify crash checker?(only 1 pixel)
				clk_counter <= 0;
			end if;
		end if;
	end process;
	process(rst, clk2)
	begin
		if rst = '0' then
			heroX <= "0111000000";
			heroY <= "011001111";
		elsif  rising_edge(clk2) then
			if equalX = '0' then
				if plusX = '1' then
					heroX <= heroX + 1;
				else 
					heroX <= heroX - 1;
				end if;
			end if;
			
			if equalY = '0' then
				if plusY = '1' then
					heroY <= heroY + 1;
				else 
					heroY <= heroY - 1;
				end if;
			end if;
		end if;
	end process;
end architecture logic;
