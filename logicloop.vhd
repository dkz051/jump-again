library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
-- i//3 = (i*1366) >> 12
-- bin(1366)
-- '0b10101010110'	
entity logicloop is
	port(
--		crash_block: out std_logic_vector(2 downto 0);
		clk,rst: in std_logic; -- we need clock clk: 100 MHz
		keyLeft,keyRight,keyUp: in std_logic; -- "keyboard input", may be simulated by sensor
		curX,enemyX: out std_logic_vector(9 downto 0); --output hero X, Y, enemy X, Y to renderer
		curY,enemyY: out std_logic_vector(8 downto 0);
		enemy_exist, reverse_g: out std_logic; -- whether enemy should be displayed, whether gravity is reversed, passed to renderer
		num_of_map: out integer;  -- which map?
		mapReadAddress: out std_logic_vector(15 downto 0); -- read block type, used by crash checking
		mapReadReturn: in std_logic_vector(8 downto 0);
		move_direction: out std_logic_vector(2 downto 0); -- hero orientation,passed to renderer
		herox_20, heroy_20: out integer
		-- if there's no moving parts other than hero, if the status of grid won't change, then,
		-- (X,Y) of hero and number of map, is enough to send to VGA control module
		-- consider 4 block: the block contain "left-right" point (heroX, heroY)
		-- and the right block, down block, right-down block?
		-- actually, crash event happens only when knock into a brick by 1 pixel? when x_20 = 0 and move left/right, y_20 = 0 and move up/down
		-- if equalX = '1', then no crash in X direction
		-- if equalY = '1', then no crash in Y direction
		-- if equalX = '0', then only crash in the moving direction (only crash left or right)
		-- actually only 4 block may be crashing
	    );
end entity logicloop;	
architecture logic of logicloop is
	component reader is -- read block type (x, y) from rom 
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
		keyLeft, keyUp, keyRight,crash_Y, crash_down, reverse, reload_map: in std_logic;
		--crash_Y: in std_logic; -- crash into brick in y direction, delta Y is not applied to heroY, set speed_y to 0
		equalX, equalY, plusX, plusY,revG: out std_logic  -- equalX: X+=0 plusX: X+=1(move right) plusY: Y+=1(move down)
		-- only when delta X, Y makes hero "rush into" brick, we consider it as "crashed". 
	    -- delta X, Y, need to be modified by crach checker
	    ); -- when rst, set speed_y to 0, then free falling
	end component;
	component xyqueue -- queue of (x, y) ordinates, 500 ordinates, allow the enemy emerges at the position of hero 5 seconds ago
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (8 DOWNTO 0); --read
		address_b		: IN STD_LOGIC_VECTOR (8 DOWNTO 0); --write
		clock		: IN STD_LOGIC  := '1';
		data_a		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;
	signal heroX,enemy_X: std_logic_vector(9 downto 0);
	signal heroY,enemy_Y: std_logic_vector(8 downto 0);
	signal clk1_counter,clk2_counter,clk3_counter, clk3_sum: integer;
	signal clk1,clk2,clk3: std_logic;
	signal equalX, equalY, plusX, plusY: std_logic;
	signal crash_X, crash_Y: std_logic;
	signal crash_down: std_logic;
	signal blockX, blockY: integer; -- X: 0 to 31 Y: 0 to 23 current place
	signal x_20, y_20: integer; -- 0 to 19
	signal flag: integer;
	signal queryX,queryY: integer;
	signal ans_type: std_logic_vector(2 downto 0);
	signal buf_equalX, buf_equalY, buf_plusX, buf_plusY: std_logic;
	signal numofmap: integer;
	signal reload_map: std_logic;
	signal reverse: std_logic;
	signal should_rev: std_logic;
	signal queue_read_addr, queue_write_addr: unsigned(8 downto 0);
	signal queue_write_data,queue_read_data: std_LOGIC_VECTOR(31 downto 0);
	signal EnemyExist,reverseG: std_logic;
	signal real_directions, directions: std_logic_vector(2 downto 0); 
	signal rev_counter: integer;
begin

	curX <= heroX;
	curY <= heroY;
	enemyX <= enemy_X;
	enemyY <= enemy_Y;
	num_of_map <= numofmap;
	enemy_exist <= EnemyExist;
	reverse_g <= reverseG;
	herox_20 <= x_20;
	heroy_20 <= y_20;
	move_direction <= real_directions;
	xyq: xyqueue port map(
		std_LOGIC_VECTOR(queue_read_addr), std_LOGIC_VECTOR(queue_write_addr), clk, 
		(others => '0'), queue_write_data,
		'0', '1', 
		queue_read_data,open);
	readmap: reader port map(numofmap,clk, mapReadAddress,mapReadReturn,queryX,queryY,ans_type); 
	move: mover port map(clk2, rst, keyLeft, keyUp, keyRight,crash_Y,crash_down,reverse,reload_map, equalX, equalY, plusX, plusY, reverseG);
	process(clk,rst) --  counter at different frequency
	begin
		if rst = '0' then
			clk1_counter <= 0;
			clk2_counter <= 0;
			clk3_counter <= 0;
			clk1 <= '0';
			clk2 <= '0';
			clk3 <= '0';
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
			
			if clk3_counter = 500000 then  -- clk3: 100hz 
				clk3 <= not clk3;
				clk3_counter <= 0;
			else
				clk3_counter <= clk3_counter + 1;
			end if;
		end if;
	end process;
	process(rst, reload_map, clk3) -- enemy at the position of hero 5 seconds ago
	begin
		if rst = '0' or reload_map = '1' then
			queue_read_addr <= "000001010";
			queue_write_addr <= (others => '0'); -- 5 second?
			
			clk3_sum <= 0;
		elsif rising_edge(clk3) then
			queue_write_data(8 downto 0) <= heroY(8 downto 0);
			queue_write_data(18 downto 9)<= heroX(9 downto 0); -- 32 bit word
			enemy_X(9 downto 0) <= queue_read_data(18 downto 9);
			enemy_Y(8 downto 0) <= queue_read_data(8 downto 0);
			if queue_write_addr = 511 then
				queue_write_addr <= (others => '0');
			else
				queue_write_addr <= queue_write_addr + 1;
			end if; -- two pointer, queue_read_addr shoule follow behind queue_write_addr
			if queue_read_addr = 511 then -- cyclic queue, size 512
				queue_read_addr <= (others => '0');
			else
				queue_read_addr <= queue_read_addr + 1;
			end if;
			clk3_sum <= clk3_sum + 1;
		end if;		
	end process;
	process(rst, clk1)
	begin
		if rst = '0' then
			numofmap <= 0;
			heroX <= "0000011110"; -- 30
			heroY <= "110111000"; -- 440
			x_20 <= 10; -- fixed initial ordinate (30, 440)
			y_20 <= 0;
			blockX <= 1;
			blockY <= 22;
			flag <= 0;
			reload_map <= '0';
			EnemyExist <= '0';
			reverse <= '0';
			should_rev <= '0';
			directions <= "000"; -- direction(2): face left / right direction(1,0): "00" no movement "01" horizontal move "10" up "11" down
			rev_counter <= 0;
			--direction(2) : face left / right
			--direction(1) : whether move vertically
			--direction(0): whether move horizontally/whether move upward
		elsif  rising_edge(clk1) then -- 10 state, check 4 block in order. 0 state: request the block type 1 state: get the block type and emit signal
			if clk3_sum = 515 then -- 5 second
				EnemyExist <= '1';
			end if;
			if reload_map = '1' then
				flag <= 0;
				heroX <= "0000011110"; -- 30
				heroY <= "110111000"; -- 440
				x_20 <= 10;
				y_20 <= 0;
				blockX <= 1;
				blockY <= 22;
				reload_map <= '0';
				reverse <= '0';
				should_rev <= '0';
				directions <= "000";
				rev_counter <= 0;
			else
			 reverse <= '0';
			 if rev_counter > 0 then
				rev_counter <= rev_counter - 1;
			 end if;
			case flag is -- use DFA to check crashing, 10  
			 when 0 => -- move X, crash upper block
						--state 0, 1, 2: check if crash_X
					real_directions <= directions; -- after finish a round , emit directions
					directions(1) <= '0'; -- horizontal
					directions(0) <= '0';
					should_rev <= '0';
		
					crash_X <= '0';
					buf_plusX <= plusX;
					buf_equalX <= equalX;
					
					if plusX = '1' then -- move right 
						queryX <= blockX + 1;
						queryY <= blockY;
					else  --move left
						queryX <= blockX;
						queryY <= blockY;
					end if;
			 when 1 =>
				if y_20 < 13 then
					if (x_20 = 6 and buf_plusX = '1') or (x_20 = 14 and buf_plusX = '0')then
						case ans_type is
							when "001" => --brick
								crash_X <= '1';
							when "010" => --death
								reload_map <= '1';
								EnemyExist <= '0';
							when "011" => -- success, next map
								reload_map <= '1';
								EnemyExist <= '0';
								numofmap <= numofmap + 1;
							when "100" =>
								crash_X <= '1';
							when others =>
							end case;
					end if;
				end if;
			 when 2 => -- move X, crash lower block
					if buf_plusX = '1'  then -- move right
						queryX <= blockX + 1;
						queryY <= blockY + 1;
					else --move left
						queryX <= blockX; -- move left
						queryY <= blockY + 1;
					end if;
			when 3 => -- moveX ?
				if y_20 /= 0 then
					if (x_20 = 6 and buf_plusX = '1') or (x_20 = 14 and buf_plusX = '0') then
						case ans_type is
						when "001" =>
							crash_X <= '1';
						when "010" =>
							reload_map <= '1';
							EnemyExist <= '0';
						when "011" => -- success, next map
							reload_map <= '1';
							EnemyExist <= '0';
							numofmap <= numofmap + 1;
						when "100" =>
							crash_X <= '1';
						when others =>
						end case;
					end if;
				end if;
			when 4 =>
				if buf_equalX = '0' and crash_X = '0' then
						if buf_plusX = '1' then
							if heroX < 619 then
								heroX <= heroX + 1;
								directions(2) <= '1'; --face right
								directions(0) <= '1';
								if x_20 = 19 then
									x_20 <= 0;
									blockX <= blockX + 1;
								else
									x_20 <= x_20 + 1;
								end if;
							end if;
						else 
							if heroX > 0 then
								directions(2)<= '0'; -- face left
								directions(0) <= '1';
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
					directions(1) <= '0';
					crash_Y <= '0';
					buf_equalY <= equalY;
					buf_plusY <= plusY;
					if plusY = '1' then -- move down
						queryX <= blockX;
						queryY <= blockY + 1;
					else --move up
						queryX <= blockX;
						queryY <= blockY;
					end if;
			when 6 =>
				if x_20 < 14 then
					if (buf_plusY = '1' and y_20 = 0) or (buf_plusY = '0' and y_20 = 13) then
					case ans_type is
						when "001" =>
							crash_Y <= '1';
							crash_down <= buf_plusY;
						when "010" => --death, reload map
							reload_map <= '1';
							EnemyExist <= '0';
						when "011" => -- success, next map
							reload_map <= '1';
							EnemyExist <= '0';
							numofmap <= numofmap + 1;
						when "100" => --gravity reverse
							crash_Y <= '1';
							should_rev <= '1';
							crash_down <= buf_plusY;
						when others =>
						end case;
					end if;
				end if;
			when 7 =>
				if buf_plusY = '1' then -- move down
					queryX <= blockX + 1;
					queryY <= blockY + 1;
				else --move up
					queryX <= blockX + 1;
					queryY <= blockY;
				end if;
			when 8 =>
				if x_20 > 6 then
					if (buf_plusY = '1' and y_20 = 0) or (buf_plusY = '0' and y_20 = 13) then
							case ans_type is
							when "001" =>
								crash_Y <= '1';
								crash_down <= buf_plusY;
							when "010" =>
								reload_map <= '1';
								EnemyExist <= '0';
							when "011" => -- success, next map
								reload_map <= '1';
								EnemyExist <= '0';
								numofmap <= numofmap + 1;
							when "100" =>
								crash_Y <= '1';
								should_rev <= '1';
								crash_down <= buf_plusY;
							when others =>
							end case;
					end if;
				end if;
			when others => -- when 9
					if rev_counter = 0 and should_rev = '1' then
						reverse <= '1';
						rev_counter <= 5000; --wait for 1 second before next reverse
					end if;
					if buf_equalY = '0' and crash_Y = '0' then
						if buf_plusY = '1' then
							if heroY < 460 then
								heroY <= heroY + 1;
								directions(1) <= '1';
								directions(0) <= '1';
								if y_20 = 19 then
									y_20 <= 0;
									if blockY = 22 then -- bottom death
										reload_map <= '1';
										EnemyExist <= '0';

									end if;
									blockY <= blockY + 1;
									
								else 
									y_20 <= y_20 + 1;
								end if;
							end if;
						else
							if heroY > 0 then
								heroY <= heroY - 1;
								directions(1) <= '1';
								directions(0) <= '0';
								if y_20 = 0 then
									y_20 <= 19;
									blockY <= blockY - 1;
								else 
									y_20 <= y_20 - 1;
								end if;
							end if;
						end if;
					end if;
					-------------------------check enemy
					if EnemyExist = '1' then -- crash into enemy , reload map
						if enemy_X  < 8 + heroX and heroX  < 8 + enemy_X and enemy_Y  < 13 + heroY and heroY  < 13 + enemy_Y then
							reload_map <= '1';
							EnemyExist <= '0';
						end if;
					end if;
			end case;				
			if flag = 9 then
				flag <= 0;
			else 
				flag <= flag + 1;
			end if;
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
		-- implement divide by 3 using bitwise operator
		addr <= ((block_num sll 1) + (block_num sll 2) + (block_num sll 4) + (block_num sll 6) + (block_num sll 8) + (block_num sll 10) + (block_num sll 12) + (block_num sll 14)) srl 16;
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
