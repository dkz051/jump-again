library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity SramController is
	port(
		reset, clock: in std_logic; -- 100 MHz clock

		sramClock: in std_logic; -- 50 MHz clock

		sramAddress: out std_logic_vector(19 downto 0);
		sramData: inout std_logic_vector(31 downto 0);

		sramNotWe: out std_logic; -- write enable
		sramNotOe: out std_logic; -- read enable
		sramNotCs: out std_logic; -- chip select

		vgaReadAddress: in std_logic_vector(19 downto 0);
		vgaReadResult: out std_logic_vector(31 downto 0);

		rendererWriteAddress: in std_logic_vector(19 downto 0);
		rendererWriteContent: in std_logic_vector(31 downto 0)
	);
end entity SramController;

architecture Sram of SramController is
	type memoryState is (SramIdle, SramRead, SramWrite, SramDone);
	signal state: memoryState;
	signal readAddress: std_logic_vector(19 downto 0);
	signal writeAddress: std_logic_vector(19 downto 0);
begin
	readAddress <= vgaReadAddress;
	writeAddress <= rendererWriteAddress;

	process(reset, sramClock, writeAddress, readAddress, sramData)
	begin
		if reset = '0' then
			state <= SramIdle;
			-- readAddress <= "00000000000000000000";
			-- writeAddress <= "00000000000000001000";
		elsif rising_edge(sramClock) then
			case state is
				when SramIdle =>
					state <= SramRead;
				when SramRead =>
					state <= SramWrite;
				when SramWrite =>
					state <= SramDone;
				when SramDone =>
					state <= SramIdle;
				when others =>
					state <= SramIdle;
			end case;
		end if;
	end process;

	process(reset, clock)
	begin
		if reset = '0' then
			sramNotCs <= '1';
			sramNotOe <= '1';
			sramNotWe <= '1';
		elsif rising_edge(clock) then
			case state is
				when SramIdle =>
					sramNotCs <= '1';
					sramNotOe <= '1';
					sramNotWe <= '1';
					sramAddress <= readAddress;
					--sramData<=(others=>'Z');
					--sramAddress<=(others=>'Z');
				when SramRead =>
					sramNotCs <= '0';
					sramNotOe <= '0';
					sramNotWe <= '1';
					vgaReadResult <= sramData;
				when SramWrite =>
					sramNotCs <= '0';
					sramNotOe <= '1';
					sramNotWe <= '0';
					sramAddress <= writeAddress;
					sramData <= rendererWriteContent;
				when SramDone =>
					sramNotCs <= '1';
					sramNotOe <= '1';
					sramNotWe <= '1';
					sramAddress <= (others => 'Z');
					sramData <= (others => 'Z');
				when others =>
					sramNotCs <= '1';
					sramNotOe <= '1';
					sramNotWe <= '1';
					sramAddress <= (others => 'Z');
					sramData <= (others => 'Z');
			end case;
		end if;
	end process;
end architecture Sram;
