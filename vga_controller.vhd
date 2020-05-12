library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity VgaController is
	port(
		reset: in std_logic;
		clk_0: in std_logic; -- 100 MHz clock input
		hs, vs: out std_logic; -- horizontal/vertical sync signal
		r, g, b: out std_logic_vector(2 downto 0);

		videoAddress: out std_logic_vector(16 downto 0);
		videoOutput: in std_logic_vector(8 downto 0);
		videoClock: out std_logic -- 25 MHz clock output
	);
end entity VgaController;

architecture vga of VgaController is
	signal r1, g1, b1: std_logic_vector(2 downto 0);
	signal hs1, vs1: std_logic;
	signal vector_x: std_logic_vector(9 downto 0) := (others => '0'); -- X coordinate
	signal vector_y: std_logic_vector(8 downto 0) := (others => '0'); -- Y coordinate
	signal clk: std_logic;
	signal clk_2: std_logic;

	signal ramAddress: std_logic_vector(16 downto 0) := (others => '0');
begin
	videoClock <= clk;

	process(clk_0) begin -- 100 MHz -> 25 MHz
		if clk_0'event and clk_0 = '1' then
			clk_2 <= not clk_2;
		end if;
	end process;

	process(clk_2) begin
		if clk_2'event and clk_2 = '1' then
			clk <= not clk;
		end if;
	end process;

	process(clk, reset) begin -- horizontal
		if reset = '0' then
			vector_x <= (others => '0');
			ramAddress <= (others => '0');
		elsif clk'event and clk = '1' then
			if vector_x < 409 and vector_y < 185 then
				if vector_x = 408 and vector_y = 184 then
					ramAddress <= (others => '0');
				else
					ramAddress <= ramAddress + 1;
				end if;
			end if;
			if vector_x = 799 then
				vector_x <= (others => '0');
			else
				vector_x <= vector_x + 1;
			end if;
		end if;
	end process;

	process(clk, reset) begin -- vertical
		if reset = '0' then
			vector_y <= (others => '0');
		elsif clk'event and clk = '1' then
			if vector_x = 799 then
				if vector_y = 524 then
					vector_y <= (others => '0');
				else
					vector_y <= vector_y + 1;
				end if;
			end if;
		end if;
	end process;

	process(clk, reset) begin -- HS (640 + 16 + 96 + 48)
		if reset = '0' then
			hs1 <= '1';
		elsif clk'event and clk = '1' then
			if vector_x >= 656 and vector_x < 752 then
				hs1 <= '0';
			else
				hs1 <= '1';
			end if;
		end if;
	end process;

	process(clk, reset) begin -- VS (480 + 10 + 2 + 33)
		if reset = '0' then
			vs1 <= '1';
		elsif clk'event and clk = '1' then
			if vector_y >= 490 and vector_y < 492 then
				vs1 <= '0';
			else
				vs1 <= '1';
			end if;
		end if;
	end process;

	process(clk, reset) begin --HS output
		if reset = '0' then
			hs <= '0';
		elsif clk'event and clk = '1' then
			hs <= hs1;
		end if;
	end process;

	process(clk, reset) begin -- VS output
		if reset = '0' then
			vs <= '0';
		elsif clk'event and clk = '1' then
			vs <= vs1;
		end if;
	end process;

	process(reset, clk, vector_x, vector_y) begin -- X/Y coordinate, output
		if reset = '0' then
			r1 <= "000";
			g1 <= "000";
			b1 <= "000";
		elsif clk'event and clk = '1' then
			if vector_x >= 409 or vector_y >= 185 then
				r1 <= "000";
				g1 <= "000";
				b1 <= "000";
			else
				videoAddress <= ramAddress;
				r1 <= videoOutput(8 downto 6);
				g1 <= videoOutput(5 downto 3);
				b1 <= videoOutput(2 downto 0);
			end if;
		end if;
	end process;

	process(hs1, vs1, r1, g1, b1) begin -- color signal output
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
