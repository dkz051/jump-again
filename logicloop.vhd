library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
-- i//3 = (i*1366) >> 12
-- bin(1366)
-- '0b10101010110'	
entity logicloop is
	port(
--		crash_block: out std_logic_vector(2 downto 0);
		clk,rst: in std_logic; -- we need clock clk: 100 MHz
		keyLeft,keyRight,keyUp: in std_logic; -- "keyboard input"
		curX: out std_logic_vector(9 downto 0);
		curY: out std_logic_vector(8 downto 0);
		num_of_map: out integer;  -- which map?
		mapReadAddress: out std_logic_vector(15 downto 0);
		mapReadReturn: in std_logic_vector(8 downto 0)
		-- if there's no moving parts other than hero, if the status of grid won't change, then,
		-- (X,Y) of hero and number of map, is enough to send to VGA control module
		-- consider 4 block: the block contain "left-right" point (heroX, heroY)
		-- and the right block, down block, right-down block?
		-- actually, crash event happens only when knock into a brick by 1 pixel? when x_20 = 0 and move left/right, y_20 = 0 and move up/down
		-- if equalX = '1', then no crash in X direction
		-- if equalY = '1', then no crash in Y direction
		-- if equalX = '0', then only crash in the moving direction (only crash left or right)
		-- actually only two block may be crashing
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
	component reader is 
		port(
			num_of_map: in integer;
			clk: in std_logic;
			mapReadAddress: out std_logic_vector(15 downto 0);
			mapReadReturn: in std_logic_vector(8 downto 0);
			blockX, blockY: in integer;
			block_type: out std_logic_vector(2 downto 0)
		);
	end component;
	component mover is
		port(
		-- mover consider deltaX, deltaY (0 or 1), not absolute X, Y
		clk, rst: in std_logic; -- clk is very important for this component!
		keyLeft, keyUp, keyRight,crash_Y: in std_logic;
		--crash_Y: in std_logic; -- crash into brick in y direction, delta Y is not applied to heroY, set speed_y to 0
		equalX, equalY, plusX, plusY: out std_logic  -- equalX: X+=0 plusX: X+=1(move right) plusY: Y+=1(move down)
		-- only when delta X, Y makes hero "rush into" brick, we consider it as "crashed". 
	    -- delta X, Y, need to be modified by crach checker
	    ); -- when rst, set speed_y to 0, then free falling
	end component;
	signal heroX: std_logic_vector(9 downto 0);
	signal heroY: std_logic_vector(8 downto 0);
	signal clk1_counter,clk2_counter: integer;
	signal clk1: std_logic;
	signal clk2: std_logic; 
	signal equalX, equalY, plusX, plusY: std_logic;
	signal crash_X, crash_Y: std_logic;
	signal blockX, blockY: integer; -- X: 0 to 31 Y: 0 to 23 current place
	signal x_20, y_20: integer; -- 0 to 19
	signal flag: integer;
	signal queryX,queryY: integer;
	signal ans_type: std_logic_vector(2 downto 0);
	signal buf_equalX, buf_equalY, buf_plusX, buf_plusY: std_logic;
begin

	curX <= heroX;
	curY <= heroY;
	num_of_map <= 0;
	readmap: reader port map(0,clk, mapReadAddress,mapReadReturn,queryX,queryY,ans_type); -- pure combinational logic?
	move: mover port map(clk2, rst, keyLeft, keyUp, keyRight,crash_Y, equalX, equalY, plusX, plusY);
	process(clk,rst)
	begin
		if rst = '0' then
			clk1_counter <= 0;
			clk2_counter <= 0;
			clk1 <= '0';
			clk2 <= '0';
		elsif rising_edge(clk) then
			if clk1_counter = 10000 then -- 5000 Hz! 
				clk1 <= not clk1;
				clk1_counter <= 0;
			else
				clk1_counter <= clk1_counter + 1;
			end if;
			
			if clk2_counter = 100000 then
				clk2 <= not clk2; -- clk2: 500Hz the frequency is high, so that we move 1 pixel or 0 pixel in one cycle
										-- mover: return direction: left/right/no movement?
										-- simplify crash checker?(only 1 pixel)
				clk2_counter <= 0;
			else
				clk2_counter <= clk2_counter + 1;
			end if;
			
		end if;
	end process;
	process(rst, clk1)
	begin
		if rst = '0' then
			heroX <= "0000111100";
			heroY <= "001100100";
			x_20 <= 0;
			y_20 <= 0;
			blockX <= 3;
			blockY <= 5;
			flag <= 0;
		elsif  rising_edge(clk1) then -- 8 state, check 4 block in order. 0 state: request the block type 1 state: get the block type and try to issue signal
			case flag is 
			 when 0 => -- move X, crash upper block
						--state 0, 1, 2: check if crash_X
					crash_X <= '0';
					buf_plusX <= plusX;
					buf_equalX <= equalX;
					if plusX = '1' then -- move right problem: blockX - 1 < 0???? will wrong at edge
						queryX <= blockX + 1;
						queryY <= blockY;
					else  --move left
						queryX <= blockX - 1;
						queryY <= blockY;
					end if;
			 when 1 =>
				if x_20 = 0 then
					if ans_type = "001" or ans_type = "010" then
						crash_X <= '1';
					end if;
				end if;
			 when 2 => -- move X, crash lower block
						if buf_plusX = '1'  then -- move right
							queryX <= blockX + 1;
							queryY <= blockY + 1;
						else --move left
							queryX <= blockX - 1;
							queryY <= blockY + 1;
						end if;
			when 3 => -- moveX ?
					if x_20 = 0 and y_20 /= 0 then
						if ans_type = "001" or ans_type = "010" then
							crash_X <= '1';
						end if;
					end if;
			when 4 =>
				if buf_equalX = '0' and crash_X = '0' then
						if buf_plusX = '1' then
							if heroX < 619 then
							-- try heroX <= heroX + 1; maybe crash?
								heroX <= heroX + 1;
								if x_20 = 19 then
									x_20 <= 0;
									blockX <= blockX + 1;
								else
									x_20 <= x_20 + 1;
								end if;
							end if;
						else 
							if heroX > 0 then
								heroX <= heroX - 1;
								if x_20 = 0 then 
									x_20 <= 19;
									blockX <= blockX - 1;
								else
									x_20 <= x_20 - 1;
								end if;
							end if;
						end if;
					end if;
			when 5 =>
					crash_Y <= '0';
					buf_equalY <= equalY;
					buf_plusY <= plusY;
					if y_20 = 0 then
						if plusY = '1' then -- move down
							queryX <= blockX;
							queryY <= blockY + 1;
						else --move up
							queryX <= blockX;
							queryY <= blockY - 1;
						end if;
					end if;
			when 6 =>
					if y_20 = 0 then
					--	crash_block <= ans_type;
						if ans_type = "001" or ans_type = "010" then
							crash_Y <= '1';
						end if;
					end if;
			when 7 =>
					if y_20 = 0 then
						if buf_plusY = '1' then -- move down
							queryX <= blockX + 1;
							queryY <= blockY + 1;
						else --move up
							queryX <= blockX + 1;
							queryY <= blockY - 1;
						end if;
					end if;
			when 8 =>
					if y_20 = 0 and x_20 /= 0 then
						if ans_type = "001" or ans_type = "010" then
							crash_Y <= '1';
						end if;
					end if;
			when others => -- when 9
					if buf_equalY = '0' and crash_Y = '0' then
						if buf_plusY = '1' then
							if heroY < 459 then
								heroY <= heroY + 1;
								if y_20 = 19 then
									y_20 <= 0;
									blockY <= blockY + 1;
								else 
									y_20 <= y_20 + 1;
								end if;
							end if;
						else
							if heroY > 0 then
								heroY <= heroY - 1;
								if y_20 = 0 then
									y_20 <= 19;
									blockY <= blockY - 1;
								else 
									y_20 <= y_20 - 1;
								end if;
							end if;
						end if;
					end if;
			end case;
			
			if flag = 9 then
				flag <= 0;
			else 
				flag <= flag + 1;
			end if;
		end if;
	end process;
end architecture logic;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity reader is -- put num_of_map, blockX, blockY in, get block_type out
		port(
			num_of_map: in integer;
			clk: in std_logic;
			mapReadAddress: out std_logic_vector(15 downto 0);
			mapReadReturn: in std_logic_vector(8 downto 0);
			blockX, blockY: in integer;
			block_type: out std_logic_vector(2 downto 0)
		);
end entity reader;
architecture rea of reader is
	signal block_num: unsigned(31 downto 0);
	signal addr: unsigned(31 downto 0);
	signal block_num_mod3: unsigned(31 downto 0);
begin
	process(clk)
	begin
	if rising_edge(clk) then
		block_num <= to_unsigned(num_of_map * 768 + blockY * 32 + blockX, 32);	
	end if;
	end process;
	
	process(block_num)
	begin
		addr <= ((block_num sll 1) + (block_num sll 2) + (block_num sll 4) + (block_num sll 6) + (block_num sll 8) + (block_num sll 10)) srl 12;
	end process;
	
	process(block_num, addr)
	begin
		block_num_mod3 <= block_num - addr - addr - addr;
		mapReadAddress <= std_logic_vector(addr(15 downto 0));
	end process;
	
	process(mapReadReturn,block_num_mod3)
	begin
		case block_num_mod3(1 downto 0) is
			when "00" => 
				block_type <= mapReadReturn(8 downto 6);
			when "01" =>
				block_type <= mapReadReturn(5 downto 3);
			when others =>
				block_type <= mapReadReturn(2 downto 0);
		end case;
	end process;
end architecture rea;
