library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity JumpAgain is
	port(
		ps2Data, ps2Clock: in std_logic;
		clock, reset: in std_logic;

		keyUp, keyDown, keyLeft, keyRight: out std_logic;

		seg_1, seg_2: out std_logic_vector(6 downto 0);

		vgaHs, vgaVs: out std_logic;
		vgaR, vgaG, vgaB: out std_logic_vector(2 downto 0)
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

	component VgaController is
		port(
			reset: in std_logic;
			clk_0: in std_logic; -- 100 MHz clock input
			hs, vs: out std_logic; -- horizontal/vertical sync signal
			r, g, b: out std_logic_vector(2 downto 0);

			videoAddress: out std_logic_vector(16 downto 0);
			videoOutput: in std_logic_vector(8 downto 0);
			videoClock: out std_logic -- 25 MHz clock output
		);
	end component VgaController;

	component ram
		port(
			address_a: in std_logic_vector(16 downto 0);
			address_b: in std_logic_vector(16 downto 0);
			clock: in std_logic := '1';
			data_a: in std_logic_vector(8 downto 0);
			data_b: in std_logic_vector(8 downto 0);
			wren_a: in std_logic := '0';
			wren_b: in std_logic := '0';
			q_a: out std_logic_vector(8 downto 0);
			q_b: out std_logic_vector(8 downto 0)
		);
	end component;

	signal scancode: std_logic_vector(7 downto 0);

	signal videoAddress: std_logic_vector(16 downto 0);
	signal videoClock: std_logic;
	signal videoOutput: std_logic_vector(8 downto 0);
begin
	control: KeyboardControl port map(ps2Data, ps2Clock, clock, reset, keyUp, keyDown, keyLeft, keyRight, scancode);
	videoMemory: ram port map(videoAddress, (others => '0'), videoClock, (others => '0'), (others => '0'), '0', '0', videoOutput, open);
	vga: VgaController port map(reset, clock, vgaHs, vgaVs, vgaR, vgaG, vgaB, videoAddress, videoOutput, videoClock);
	led1: Led7 port map(scancode(3 downto 0), seg_1);
	led2: Led7 port map(scancode(7 downto 4), seg_2);
end architecture jump;
