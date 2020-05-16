library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity Renderer is
	port(
		signal reset: in std_logic;
		signal clock: in std_logic; -- 25 MHz clock

		-- signal heroX: in std_logic_vector(9 downto 0);
		-- signal heroY: in std_logic_vector(8 downto 0);

		signal readAddress: out std_logic_vector(16 downto 0);
		signal readOutput: in std_logic_vector(8 downto 0);

		signal writeAddress: out std_logic_vector(13 downto 0);
		signal writeContent: out std_logic_vector(8 downto 0)
	);
end entity Renderer;

architecture Render of Renderer is
	constant ramLines: integer := 12;

	signal x: std_logic_vector(9 downto 0) := (others => '0');
	signal y: std_logic_vector(9 downto 0) := (others => '0');

	signal readFrom: std_logic_vector(16 downto 0) := (others => '0');
	signal writeTo: std_logic_vector(13 downto 0) := (others => '0');
	signal writeData: std_logic_vector(8 downto 0) := (others => '0');
begin
	readAddress <= readFrom;
	writeAddress <= writeTo;
	writeContent <= writeData;

	process(reset, clock)
	begin
		if reset = '0' then
			x <= (others => '0');
			y <= (others => '0');
			readFrom <= (others => '0');
			writeTo <= (others => '0');
		elsif rising_edge(clock) then
			if x < 409 and y < 185 then
				if x = 408 and y = 184 then
					readFrom <= (others => '0');
				else
					readFrom <= readFrom + 1;
				end if;
			end if;

			if writeTo = ramLines * 800 - 1 then
				writeTo <= (others => '0');
			else
				writeTo <= writeTo + 1;
			end if;

			if x = 799 then
				x <= (others => '0');
				if y = 524 then
					y <= (others => '0');
				else
					y <= y + 1;
				end if;
			else
				x <= x + 1;
			end if;
		end if;
	end process;

	process(reset, x, y, readFrom, writeTo, readOutput)
	begin
		if reset = '0' then
			writeData <= (others => '0');
		else
			if x < 409 and y < 185 then
				writeData <= readOutput;
			else
				writeData <= (others => '0');
			end if;
		end if;
	end process;
end architecture Render;
