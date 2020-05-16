library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity VgaController is
	port(
		reset: in std_logic;
		clock: in std_logic; -- 25 MHz clock input
		hs, vs: out std_logic; -- horizontal/vertical sync signal
		r, g, b: out std_logic_vector(2 downto 0);

		videoAddress: out std_logic_vector(19 downto 0);
		videoOutput: in std_logic_vector(31 downto 0)
	);
end entity VgaController;

architecture vga of VgaController is
	signal r1, g1, b1: std_logic_vector(2 downto 0);
	signal hs1, vs1: std_logic;
	signal vector_x: std_logic_vector(9 downto 0) := (others => '0'); -- X coordinate
	signal vector_y: std_logic_vector(9 downto 0) := (others => '0'); -- Y coordinate
begin
	videoAddress <= "0" & ((vector_y & "000000000") + (vector_y & "0000000") + vector_x);

	process(clock, reset) -- X/Y coordinates
	begin
		if reset = '0' then
			vector_x <= (others => '0');
			vector_y <= (others => '0');
		elsif rising_edge(clock) then
			if vector_x = 799 then
				vector_x <= (others => '0');
				if vector_y = 524 then
					vector_y <= (others => '0');
				else
					vector_y <= vector_y + 1;
				end if;
			else
				vector_x <= vector_x + 1;
			end if;
		end if;
	end process;

	process(clock, reset) -- HS (640 + 16 + 96 + 48)
	begin
		if reset = '0' then
			hs1 <= '1';
		elsif rising_edge(clock) then
			if vector_x >= 656 and vector_x < 752 then
				hs1 <= '0';
			else
				hs1 <= '1';
			end if;
		end if;
	end process;

	process(clock, reset) -- VS (480 + 10 + 2 + 33)
	begin
		if reset = '0' then
			vs1 <= '1';
		elsif rising_edge(clock) then
			if vector_y >= 490 and vector_y < 492 then
				vs1 <= '0';
			else
				vs1 <= '1';
			end if;
		end if;
	end process;

	process(clock, reset) --HS output
	begin
		if reset = '0' then
			hs <= '0';
		elsif rising_edge(clock) then
			hs <= hs1;
		end if;
	end process;

	process(clock, reset) -- VS output
	begin
		if reset = '0' then
			vs <= '0';
		elsif rising_edge(clock) then
			vs <= vs1;
		end if;
	end process;

	process(reset, clock, vector_x, vector_y) -- output
	begin
		if reset = '0' then
			r1 <= "000";
			g1 <= "000";
			b1 <= "000";
		elsif rising_edge(clock) then
			if vector_x >= 640 or vector_y >= 480 then
				r1 <= "000";
				g1 <= "000";
				b1 <= "000";
			else
				r1 <= videoOutput(2 downto 0);
				g1 <= videoOutput(5 downto 3);
				b1 <= videoOutput(8 downto 6);
			end if;
		end if;
	end process;

	process(hs1, vs1, r1, g1, b1) -- color signal output
	begin
		if hs1 = '1' and vs1 = '1' then
			r <= r1;
			g <= g1;
			b <= b1;
		else
			r <= (others => '0');
			g <= (others => '0');
			b <= (others => '0');
		end if;
	end process;
end architecture vga;
