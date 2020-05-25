library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Sensor is
	port(
		clock: in std_logic; -- 100 MHz clock input
		reset: in std_logic;
		rx: in std_logic;
		up, down, left, right: out std_logic
	);
end entity;

architecture Control of Sensor is
	component Uart is
		port(
			clock: in std_logic; -- 100 MHz clock input
			reset: in std_logic;
			rx: in std_logic;
			data: out std_logic_vector(7 downto 0) -- Byte read from RX
		);
	end component Uart;
	signal rxData: std_logic_vector(7 downto 0);
begin
	connect: Uart port map(clock, reset, rx, rxData);

	up <= rxData(3);
	down <= rxData(2);
	left <= rxData(1);
	right <= rxData(0);
end architecture Control;
