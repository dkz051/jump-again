library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity Renderer is
	port(
	--	crash_block: in std_logic_vector(2 downto 0);
		signal num_of_map: in integer;
		signal reset: in std_logic;
		signal clock: in std_logic; -- 25 MHz clock


		signal heroX,enemyX: in std_logic_vector(9 downto 0);
		signal heroY,enemyY: in std_logic_vector(8 downto 0);
		signal enemy_exist,reverse_g: in std_logic;

		signal readAddress: out std_logic_vector(15 downto 0);
		signal readOutput: in std_logic_vector(8 downto 0);

		signal writeAddress: out std_logic_vector(13 downto 0);
		signal writeContent: out std_logic_vector(8 downto 0);

		signal imageReadAddress: out std_logic_vector(14 downto 0);
		signal imageColorOutput: in std_logic_vector(8 downto 0)
	);
end entity Renderer;

architecture Render of Renderer is
	constant ramLines: integer := 12;

	signal x: std_logic_vector(9 downto 0) := (others => '0');
	signal y: std_logic_vector(9 downto 0) := (others => '0');
	signal color_typ: std_logic_vector(2 downto 0):= (others => '0');
	signal x_20, y_20: integer range 0 to 19; -- x%20, y%20, maintained by increment
	signal cnt3_x0: integer;
	signal cnt3: integer;
	signal readFrom: std_logic_vector(15 downto 0) := (others => '0');
	signal readFrom_x0: std_logic_vector(15 downto 0) := (others => '0');
	signal writeTo: std_logic_vector(13 downto 0) := (others => '0');
	signal writeData: std_logic_vector(8 downto 0) := (others => '0');
	signal lastData: std_logic_vector(2 downto 0); -- last data in a word, (2 downto 0)
	signal firstData: std_logic_vector(2 downto 0); -- first data in a line
	signal lastColor: std_logic_vector(8 downto 0);
begin
	readAddress <= readFrom;
	writeAddress <= writeTo;
	writeContent <= writeData;

	process(reset, clock)
	begin
		if reset = '0' then
			--x <= (others => '0');
			x <= ((0)=>'1', others => '0'); -- (x,y): the pixel we are rendering (x,y) - 1: the pixel we are feeding to video memory (last Color)
			y <= (others => '0');
			x_20 <= 0;
			y_20 <= 0;
			readFrom <= std_logic_vector(to_unsigned(num_of_map * 256, 16));
			writeTo <= (others => '0');
			readFrom_x0 <= std_logic_vector(to_unsigned(num_of_map * 256, 16));
			cnt3_x0 <= 0;
		elsif rising_edge(clock) then
			if x = 700 then
				lastData <= readOutput(2 downto 0);
			end if;
			writeData <= lastColor;
			if x < 640 and y < 480 then
				if x = 639 and y = 479 then
					readFrom_x0 <= std_logic_vector(to_unsigned(num_of_map * 256, 16));
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
								readFrom <= readFrom +  1;
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
	process (cnt3, readOutput)
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
			case color_typ is
				when "000" => -- air
					-- writeData <= "111111111";
					imageReadAddress <= "00000" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "001" => -- brick
					-- writedata <= "111000000";
					imageReadAddress <= "00001" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "010" => -- trap
					-- writeData <= "000111000";
					imageReadAddress <= "00010" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "011" => -- destination
					-- writeData <= "111111000";
					imageReadAddress <= "00011" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
				when "100" =>
					-- writeData <= "101001100";
					if reverse_g = '0' then
						imageReadAddress <= "00100" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
					else
						imageReadAddress <= "00101" & std_logic_vector(to_unsigned(y_20, 5)) & std_logic_vector(to_unsigned(x_20, 5));
					end if;
				when others =>
					-- writeData <= "000000000";
					imageReadAddress <= (others => '0');
			end case;
		end if;
	end process;
	process(reset, imageColorOutput, x)
	begin
		if reset = '0' then
			--writeData <= (others => '0');
			lastColor <= (others => '0');
		else
			if x < 640 and y < 480 then -- inside the map
				if  heroX + 6 > x or heroY + 7 > y or  x > heroX + 14 or  y > heroY + 19  then
					if enemy_exist = '0' or enemyX + 6 > x or enemyY + 7 > y or x > enemyX + 14 or Y > enemyY + 19 then
			--	if  heroX > x or heroY > y or  x > heroX + 19 or  y > heroY + 19  then
			--		if enemy_exist = '0' or enemyX > x or enemyY > y or x > enemyX + 19 or Y > enemyY + 19 then
						lastColor <= imageColorOutput;
					else
						lastColor <= "000000000"; -- black enemy
					end if;
				else
					lastColor <= "000000111";
				end if;
			else
				lastColor <= (others => '0');
			end if; -- render a pixel, output it in the next pulse
		end if;
	end process;
end architecture Render;
