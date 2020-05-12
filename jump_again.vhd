library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity JumpAgain is
	port(
		ps2Data, ps2Clock: in std_logic;
		clock, reset: in std_logic;

		keyUp, keyDown, keyLeft, keyRight: out std_logic;

		seg_1, seg_2: out std_logic_vector(6 downto 0)
	);
end entity JumpAgain;

architecture jump of JumpAgain is
	component KeyboardControl is
		port(
			datain, clkin: in std_logic;
			fclk, rst: in std_logic;

			keyUp: out std_logic := '0';
			keyDown: out std_logic := '0';
			keyLeft: out std_logic := '0';
			keyRight: out std_logic := '0';

			scancodes: out std_logic_vector(7 downto 0)
		);
	end component KeyboardControl;

	component Led7 is
		port(
			value: in std_logic_vector(3 downto 0);
			segments: out std_logic_vector(6 downto 0)
		);
	end component Led7;

	signal scancode: std_logic_vector(7 downto 0);
begin
	control: KeyboardControl port map(ps2Data, ps2Clock, clock, reset, keyUp, keyDown, keyLeft, keyRight, scancode);
	led1: Led7 port map(scancode(3 downto 0), seg_1);
	led2: Led7 port map(scancode(7 downto 4), seg_2);
end architecture jump;
