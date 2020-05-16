library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity JumpAgain is
	port(
		ps2Data, ps2Clock: in std_logic;
		clock, reset: in std_logic;

		vgaHs, vgaVs: out std_logic;
		vgaR, vgaG, vgaB: out std_logic_vector(2 downto 0);

		sramAddress: out std_logic_vector(19 downto 0);
		sramData: inout std_logic_vector(31 downto 0);
		sramNotWe, sramNotOe, sramNotCs: out std_logic
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
			keyRight: out std_logic := '0'
		);
	end component KeyboardControl;

	component VgaController is
		port(
			reset: in std_logic;
			clock: in std_logic; -- 100 MHz clock input
			hs, vs: out std_logic; -- horizontal/vertical sync signal
			r, g, b: out std_logic_vector(2 downto 0);

			videoAddress: out std_logic_vector(19 downto 0);
			videoOutput: in std_logic_vector(31 downto 0)
		);
	end component VgaController;

	component data
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

	component Renderer is
		port(
			signal reset: in std_logic;
			signal clock: in std_logic; -- 25 MHz clock

			-- signal heroX: in std_logic_vector(9 downto 0);
			-- signal heroY: in std_logic_vector(8 downto 0);

			signal readAddress: out std_logic_vector(16 downto 0);
			signal readOutput: in std_logic_vector(8 downto 0);

			signal writeAddress: out std_logic_vector(19 downto 0);
			signal writeContent: out std_logic_vector(31 downto 0)
		);
	end component Renderer;

	component SramController is
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
	end component SramController;

	component pll
		port(
			areset: in std_logic := '0';
			inclk0: in std_logic := '0';
			c0: out std_logic;
			c1: out std_logic;
			locked: out std_logic
		);
	end component;

	-- signal heroX: std_logic_vector(9 downto 0);
	-- signal heroY: std_logic_vector(8 downto 0);

	signal videoClock: std_logic;
	signal sramClock: std_logic;
	signal renderClock: std_logic;

	-- signal logicReadAddress: std_logic_vector(16 downto 0);
	-- signal logicReadReturn: std_logic_vector(8 downto 0);

	signal rendererReadAddress: std_logic_vector(16 downto 0);
	signal rendererReadReturn: std_logic_vector(8 downto 0);

	signal videoReadAddress: std_logic_vector(19 downto 0);
	signal videoColorOutput: std_logic_vector(31 downto 0);

	signal videoWriteAddress: std_logic_vector(19 downto 0);
	signal videoWriteContent: std_logic_vector(31 downto 0);
begin
	-- control: KeyboardControl port map(ps2Data, ps2Clock, clock, reset, keyUp, keyDown, keyLeft, keyRight);

	pllClock: pll port map(not reset, clock, videoClock, sramClock, open);

	-- sramClock <= clock;
	renderClock <= videoClock;

	vga: VgaController port map(reset, videoClock, vgaHs, vgaVs, vgaR, vgaG, vgaB, videoReadAddress, videoColorOutput);

	render: Renderer port map(
		reset, renderClock,
		-- heroX, heroY,
		rendererReadAddress, rendererReadReturn,
		videoWriteAddress, videoWriteContent
	);

	videoMemory: SramController port map(reset, clock, sramClock, sramAddress, sramData, sramNotWe, sramNotOe, sramNotCs, videoReadAddress, videoColorOutput, videoWriteAddress, videoWriteContent);

	dataMemory: data port map(rendererReadAddress, (others => '0'), clock, (others => '0'), (others => '0'), '0', '0', rendererReadReturn, open);
end architecture jump;
