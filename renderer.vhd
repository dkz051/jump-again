library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity Renderer is
	port(
          	signal num_of_map: in integer; -- which map is displaying?
		signal reset: in std_logic;
		signal clock: in std_logic; -- 25 MHz clock


		signal heroX,enemyX: in std_logic_vector(9 downto 0); -- X ordinate of hero and enemy(upmost ordinate)
		signal heroY,enemyY: in std_logic_vector(8 downto 0); -- Y ordinate of hero and enemy(leftmost ordinate)
		signal enemy_exist,reverse_g: in std_logic; -- flag,whether enemy exists, whether the gravity is reversing, the image will be different

		signal readAddress: out std_logic_vector(15 downto 0); -- connect to rom, read the map infomation(the type of blocks)
		signal readOutput: in std_logic_vector(8 downto 0); -- output of rom, type of 3 continuous blocks(3 bit for one block)

		signal writeAddress: out std_logic_vector(13 downto 0); -- connect to video memory
		signal writeContent: out std_logic_vector(8 downto 0); -- write to video memory, 9 bit RGB color of 1 pixel

		signal imageReadAddress: out std_logic_vector(14 downto 0); -- read the 20 * 20 image resources for blocks
		signal imageColorOutput: in std_logic_vector(8 downto 0);

		signal heroReadAddress: out std_logic_vector(14 downto 0); -- read the 20 * 20 image resources for hero
		signal heroColorOutput: in std_logic_vector(8 downto 0);

		signal directions: in std_LOGIC_VECTOR(2 downto 0); -- the orientation of hero, used to choose hero image resources 
		signal herox_20, heroy_20: in integer -- hero X, Y ordinate(mod 20), used to choose the correct pixel of image resources 
	);
end entity Renderer;

architecture Render of Renderer is
	constant ramLines: integer := 12; -- how many lines does video memory have

	signal x: std_logic_vector(9 downto 0) := (others => '0');
	signal y: std_logic_vector(9 downto 0) := (others => '0');
	signal color_typ: std_logic_vector(2 downto 0):= (others => '0');
	signal x_20, y_20: integer; -- x%20, y%20, maintained by increment
	signal cnt3_x0: integer;
	signal cnt3: integer; -- each word contain 3 block (3 bit for one block), which block is the current block?(0, 1, 2)
	signal readFrom: std_logic_vector(15 downto 0) := (others => '0');
	signal readFrom_x0: std_logic_vector(15 downto 0) := (others => '0'); -- wrap back at the end of one line
	signal writeTo: std_logic_vector(13 downto 0) := (others => '0');
	signal writeData: std_logic_vector(8 downto 0) := (others => '0');
	signal lastData: std_logic_vector(2 downto 0); -- last data in a word, (2 downto 0), used to prefetch next word without losing data in last word
	signal firstData: std_logic_vector(2 downto 0); -- first data in a line
	signal lastColor: std_logic_vector(8 downto 0);
	signal heroMapNum: std_logic_vector(4 downto 0);
	signal SlowClock1,SlowClock2: std_logic; -- SlowClock, SlowCounter: animate the hero, change the image resources according to slow counter(2Hz, 4Hz)
	signal slow_counter: integer;
	signal slow_count2,slow_count4: integer;
begin
	readAddress <= readFrom;
	writeAddress <= writeTo;
	writeContent <= writeData;
	process(reset, clock) -- generate slow clock used to animate the hero (2 fps/4 fps)
	begin
		if reset = '0' then
			slow_counter <= 0;
			SlowClock1 <= '0';
			SlowClock2 <= '0';
			slow_count2 <= 0;
			slow_count4 <= 0;
		elsif rising_edge(clock) then
			if slow_counter = 3125000 then
				slow_counter <= 0;
				SlowClock1 <= not SlowClock1; -- 4Hz
				SlowClock2 <= SlowClock2 xor SlowClock1; -- 2Hz
				if slow_count2 = 1 then
					slow_count2 <= 0;
				else
					slow_count2 <= 1;
				end if;
				if slow_count4 = 3 then
					slow_count4 <= 0;
				else
					slow_count4 <= slow_count4 + 1;
				end if;
			else
				slow_counter <= slow_counter + 1;
			end if;
		end if;
	end process;
	process(reset, SlowClock1) -- choose the correct image resources for Hero: first choose orientation type, then choose animation frames according to timer
	begin
		if reset = '0' then
			heroMapNum <= "01000";
		elsif rising_edge(SlowClock1) then
		-- update heroMapNum according to directions
		-- direction(2): face left / right direction(0 left, 1 right): "00" no movement "01" horizontal move "10" up "11" down
			--direction(2) : face left / right
			--direction(1) : whether move vertically
			--direction(0): whether move horizontally/whether move upward
			case directions is 
				when "100" => -- face right, no move
					case slow_count4 is
						when 0 =>
							heroMapNum <= "01000";
						when 1 =>
							heroMapNum <= "01001";
						when 2 =>
							heroMapNum <= "01010";
						when others =>
							heroMapNum <= "01011";
					end case;
				when "101" => -- face right, horizontal
					case slow_count4 is
						when 0 =>
							heroMapNum <= "01100";
						when 1 =>
							heroMapNum <= "01101";
						when 2 =>
							heroMapNum <= "01110";
						when others =>
							heroMapNum <= "01111";
					end case; 
				when "111" => -- face right, move down 
					case slow_count2 is
						when 0 =>
							heroMapNum <= "10000";
						when others =>
							heroMapNum <= "10001";
					end case;
				when "110" => -- face right, move up
					case slow_count2 is
						when 0 =>
							heroMapNum <= "10010";
						when others =>
							heroMapNum <= "10011";
					end case;
				when "000" => -- face left, no move
					case slow_count4 is
						when 0 =>
							heroMapNum <= "10100";
						when 1 =>
							heroMapNum <= "10101";
						when 2 =>
							heroMapNum <= "10110";
						when others =>
							heroMapNum <= "10111";
					end case;
				when "001" => 
					case slow_count4 is
						when 0 =>
							heroMapNum <= "11000";
						when 1 =>
							heroMapNum <= "11001";
						when 2 =>
							heroMapNum <= "11010";
						when others =>
							heroMapNum <= "11011";
					end case;
				when "011" =>
					case slow_count2 is
						when 0 =>
							heroMapNum <= "11100";
						when others =>
							heroMapNum <= "11101";
					end case;
				when "010" =>
					case slow_count2 is
						when 0 =>
							heroMapNum <= "11110";
						when others =>
							heroMapNum <= "11111";
					end case;
			end case;
		end if;
	end process;
	process(reset, clock) 
	-- simple 2 level pipeline. render a pixel need 2 steps:
	-- 1. choose the type of block according to map infomation, read the color from image resources
	-- 2. write the color to video memory
	-- every pulse, we write the last pixel's color to video memory, read the next pixel's color from image resources
	begin
		if reset = '0' then
			x <= ((0)=>'1', others => '0');
			-- (x,y): the pixel we are rendering
			-- (x,y) - 1: the pixel we are feeding to video memory (last Color)
			y <= (others => '0');
			x_20 <= 0;
			y_20 <= 0;
			readFrom <= std_logic_vector(to_unsigned(num_of_map * 256, 16)); -- each map occupy 256 words
			writeTo <= (others => '0');
			readFrom_x0 <= std_logic_vector(to_unsigned(num_of_map * 256, 16));
			cnt3_x0 <= 0;
		elsif rising_edge(clock) then
			-- read the block type from map, read one word, get infomation of three block 
			if x = 700 then
				lastData <= readOutput(2 downto 0);
			end if;
			writeData <= lastColor;
			if x < 640 and y < 480 then
				if x = 639 and y = 479 then
					readFrom_x0 <= std_logic_vector(to_unsigned(num_of_map * 256, 16)); -- the address of the first block, wrap back at the end of one line
					cnt3_x0 <= 0; 
					readFrom <= std_logic_vector(to_unsigned(num_of_map * 256, 16));
					cnt3 <= 0;
				else
					if x = 0 then
						readFrom_x0 <= readFrom;
						cnt3_x0 <= cnt3;
					end if;
					if x_20 = 19 then
						if y_20 /= 19 and x = 639 then -- wrap back one line
							readFrom <= readFrom_x0; --  invisible region provide enough time here
							cnt3 <= cnt3_x0;
						else -- y_20 = 19 or
							if cnt3 = 1 then
								lastData <= readOutput(2 downto 0);
								readFrom <= readFrom +  1; -- prefetch, change the readFrom address before one pulse 
								cnt3 <= cnt3 + 1;
							elsif cnt3 = 2 then
								cnt3 <= 0;
							else
								cnt3 <= cnt3 + 1;
							end if;
						end if;
					end if;
				end if;
			end if;

			if writeTo = ramLines * 800 - 1 then
				writeTo <= (others => '0'); -- the video memory wrap back
			else
				writeTo <= writeTo + 1;
			end if;

------------------- update x, y, x %= 800 y%=525 x_20 = x%20, y_20 = y%20
			if x = 799 then
				x <= (others => '0');
				x_20 <= 0;
				if y = 524 then
					y <= (others => '0');
					y_20 <= 0;
				else
					y <= y + 1;
					if y_20 = 19 then
						y_20 <= 0;
					else
						y_20 <= y_20 + 1;
					end if;
				end if;
			else
				x <= x + 1;
				if x_20 = 19 then
					x_20 <= 0;
				else
					x_20 <= x_20 + 1;
				end if;
			end if;
		end if;
	end process;
	process (cnt3, readOutput) -- we use 9 bit words to store map, 9 bit word contains 3 blocks, numbered by 0, 1, 2
	begin 
		case cnt3 is
				when 0 =>
					color_typ <= readOutput(8 downto 6);
				when 1 =>
					color_typ <= readOutput(5 downto 3);
				when others =>
					color_typ <= lastData;
		end case;
	end process;
------------------------connect render result and video memory
	process(x)
	begin
		if x < 640 and y < 480 then -- inside the map
			case color_typ is -- now we know the type of current block, read the corresponding pixel in image resource
				when "000" => -- air
					imageReadAddress <= "00000" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "001" => -- brick
					imageReadAddress <= "00001" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "010" => -- trap
					imageReadAddress <= "00010" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "011" => -- destination
					imageReadAddress <= "00011" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "100" =>
					if reverse_g = '0' then
						imageReadAddress <= "00100" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
					else
						imageReadAddress <= "00101" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
					end if;
				when others =>
					imageReadAddress <= (others => '0');
			end case;

			-- direction(2): face left / right direction(1,0): "00" no movement "01" horizontal move "10" up "11" down
			--direction(2) : face left / right
			--direction(1) : whether move vertically
			--direction(0): whether move horizontally/whether move upward
			-- normal: (y_20 - heroy_20) % 20
			-- now: (19 - y_20 + heroy_20) %20 
			-- heroMapNum: which image resource should be use.  then concatenate it with the relative x, y 
			if y_20 >= heroy_20 then
				if x_20 >= herox_20 then
					heroReadAddress <=  heroMapNum &  std_logic_vector(to_unsigned(19 + heroy_20 - y_20, 5)) & std_logic_vector(to_unsigned(19 + herox_20 - x_20, 5));
				else
					heroReadAddress <=  heroMapNum &  std_logic_vector(to_unsigned(19 + heroy_20 - y_20, 5)) & std_logic_vector(to_unsigned(herox_20 - x_20 - 1, 5));
				end if;
			else
				if x_20 >= herox_20 then
					heroReadAddress <=  heroMapNum &  std_logic_vector(to_unsigned(heroy_20 - y_20 - 1, 5)) & std_logic_vector(to_unsigned(19 + herox_20 - x_20, 5));
				else
					heroReadAddress <=  heroMapNum &  std_logic_vector(to_unsigned(heroy_20 - y_20 - 1, 5)) & std_logic_vector(to_unsigned(herox_20 - x_20 - 1, 5));
				end if;
			end if;
			-- assign heroReadAddress
		end if;
	end process;
	process(reset, imageColorOutput, x)
	begin
		if reset = '0' then
			--writeData <= (others => '0');
			lastColor <= (others => '0');
		else
			if x < 640 and y < 480 then -- inside the map
				if  heroColorOutput = "111111111" or heroX + 0 > x or heroY + 0 > y or  x > heroX + 19 or  y > heroY + 19  then 
					if enemy_exist = '0' or enemyX + 6 > x or enemyY + 7 > y or x > enemyX + 14 or Y > enemyY + 19 then
						lastColor <= imageColorOutput; -- this pixel is not enemy or hero, output the color of block 
					else
						lastColor <= "000000000"; -- this pixel is part of the enemy (black)
					end if;
				else -- this pixel is part of the hero
					lastColor <= heroColorOutput;
				end if;
			else
				lastColor <= (others => '0');
			end if; -- render a pixel in lastColor, output it in the next pulse
		end if;
	end process;
end architecture Render;
