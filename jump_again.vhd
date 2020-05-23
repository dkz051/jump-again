library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity JumpAgain is -- top entity
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

			videoAddress: out std_logic_vector(13 downto 0);
			videoOutput: in std_logic_vector(8 downto 0)
		);
	end component VgaController;

	component data
		port(
			address_a: in std_logic_vector(15 downto 0);
			address_b: in std_logic_vector(15 downto 0);
			clock: in std_logic := '1';
			data_a: in std_logic_vector(8 downto 0);
			data_b: in std_logic_vector(8 downto 0);
			wren_a: in std_logic := '0';
			wren_b: in std_logic := '0';
			q_a: out std_logic_vector(8 downto 0);
			q_b: out std_logic_vector(8 downto 0)
		);
	end component;

	component video_memory
		port(
			address_a: in std_logic_vector(13 downto 0);
			address_b: in std_logic_vector(13 downto 0);
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
    --		crash_block: in std_logic_vector(2 downto 0);
			signal num_of_map: in integer;
			signal reset: in std_logic;
			signal clock: in std_logic; -- 25 MHz clock

			signal heroX: in std_logic_vector(9 downto 0);
		   signal heroY: in std_logic_vector(8 downto 0);

			signal readAddress: out std_logic_vector(15 downto 0);
			signal readOutput: in std_logic_vector(8 downto 0);

			signal writeAddress: out std_logic_vector(13 downto 0);
			signal writeContent: out std_logic_vector(8 downto 0)
		);
	end component Renderer;

	component pll
		port(
			areset: in std_logic := '0';
			inclk0: in std_logic := '0';
			c0: out std_logic;
			c1: out std_logic;
			locked: out std_logic
		);
	end component;
	
	component logicloop is
		port(
		--crash_block: out std_logic_vector(2 downto 0);
		clk,rst: in std_logic; -- we need clock
		keyLeft,keyRight,keyUp: in std_logic; -- "keyboard input"
		curX: out std_logic_vector(9 downto 0);
		curY: out std_logic_vector(8 downto 0); -- place of hero
		num_of_map: out integer; -- which map?
		mapReadAddress: out std_logic_vector(15 downto 0);
		mapReadReturn: in std_logic_vector(8 downto 0)

		-- if there's no moving parts other than hero, if the status of grid won't change, then,
		-- (X,Y) of hero and number of map, is enough to send to VGA control module
	    );
	end component logicloop;
	signal heroX: std_logic_vector(9 downto 0); -- hardcode
	signal heroY: std_logic_vector(8 downto 0);  -- connect logic and renderer
	signal keyUp, keyDown, keyLeft, keyRight: std_logic;
	signal videoClock: std_logic;
	signal sramClock: std_logic;
	signal renderClock: std_logic;

	signal logicReadAddress: std_logic_vector(15 downto 0);
	signal logicReadReturn: std_logic_vector(8 downto 0);

	signal rendererReadAddress: std_logic_vector(15 downto 0);
	signal rendererReadReturn: std_logic_vector(8 downto 0);

	signal videoReadAddress: std_logic_vector(13 downto 0);
	signal videoColorOutput: std_logic_vector(8 downto 0);

	signal videoWriteAddress: std_logic_vector(13 downto 0);
	signal videoWriteContent: std_logic_vector(8 downto 0);
	
	signal num_of_map: integer;
	--signal crash_block: std_logic_vector(2 downto 0);
begin
	control: KeyboardControl port map(ps2Data, ps2Clock, clock, reset, keyUp, keyDown, keyLeft, keyRight);

	pllClock: pll port map(not reset, clock, videoClock, sramClock, open);

	-- sramClock <= clock;
	renderClock <= videoClock;

	vga: VgaController port map(reset, videoClock, vgaHs, vgaVs, vgaR, vgaG, vgaB, videoReadAddress, videoColorOutput);

	render: Renderer port map(
	--	crash_block,
		num_of_map,
		reset, renderClock,
		heroX, heroY,--"0000111111", "000111000", --hardcode heroX, heroY
		rendererReadAddress, rendererReadReturn,
		videoWriteAddress, videoWriteContent
	);
	logic: logicloop port map(clock, reset, keyLeft, keyRight, keyUp, heroX, heroY, num_of_map, logicReadAddress, logicReadReturn);
	videoMemory: video_memory port map(videoReadAddress, videoWriteAddress, clock, (others => '0'), videoWriteContent, '0', '1', videoColorOutput, open);

	dataMemory: data port map(rendererReadAddress, logicReadAddress, clock, (others => '0'), (others => '0'), '0', '0', rendererReadReturn, logicReadReturn);
end architecture jump;
