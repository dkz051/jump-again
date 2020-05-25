library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Uart is
	port(
		clock: in std_logic; -- 100 MHz clock input
		reset: in std_logic;
		rx: in std_logic;
		data: out std_logic_vector(7 downto 0) -- Byte read from RX
	);
end entity Uart;

architecture Transact of Uart is
	signal uartCount: integer range 0 to 10416 := 0;
	signal uartClock: std_logic;
	signal rx8bit: std_logic_vector(7 downto 0);
	signal state: integer range 0 to 9;
begin
	-- Baud generator
	process(reset, clock)
	begin
		if reset = '0' then
			uartCount <= 0;
			uartClock <= '0';
		elsif rising_edge(clock) then -- 时钟计数器
			if uartCount = 10416 then
				uartCount <= 0;
				uartClock <= '1'; --波特率高电平
			else
				uartCount <= uartCount + 1;
				uartClock <= '0'; --波特率低电平
			end if;
		end if;
	end process;

	-- State machine for RX pin
	process(reset, clock)
	begin
		if reset = '0' then
			rx8bit <= (others => '1');
		elsif rising_edge(uartClock) then
			case state is
				when 0 =>
					if rx = '0' then
						state <= state + 1;
					end if;
				when 1 =>
					rx8bit(0) <= rx;
					state <= state + 1;
				when 2 =>
					rx8bit(1) <= rx;
					state <= state + 1;
				when 3 =>
					rx8bit(2) <= rx;
					state <= state + 1;
				when 4 =>
					rx8bit(3) <= rx;
					state <= state + 1;
				when 5 =>
					rx8bit(4) <= rx;
					state <= state + 1;
				when 6 =>
					rx8bit(5) <= rx;
					state <= state + 1;
				when 7 =>
					rx8bit(6) <= rx;
					state <= state + 1;
				when 8 =>
					rx8bit(7) <= rx;
					state <= state + 1;
				when 9 =>
					if rx = '1' then
						data <= rx8bit;
					end if;
					state <= 0;
				when others =>
					state <= 0;
			end case;
		end if;
	end process;
end architecture Transact;
