library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity KeyboardControl is
	port(
		datain, clkin: in std_logic;
		fclk, rst: in std_logic;

		keyUp: out std_logic := '0'; -- key E
		keyDown: out std_logic := '0'; -- key D
		keyLeft: out std_logic := '0'; -- key S
		keyRight: out std_logic := '0' -- key F
	);
end entity KeyboardControl;

architecture control of KeyboardControl is
	type ControlState is (pending, keyReleased);
	component Keyboard is
		port(
			datain, clkin: in std_logic;
			fclk, rst: in std_logic;
			scancode: out std_logic_vector(7 downto 0);
			ready: buffer std_logic
		);
	end component Keyboard;
	signal state: ControlState := pending;
	signal scancode: std_logic_vector(7 downto 0) := "00000000";
	signal ready: std_logic := '0';
begin
	keys: Keyboard port map(datain, clkin, fclk, rst, scancode, ready);

	process(rst, ready)
	begin
		if rst = '0' then
			keyUp <= '0';
			keyDown <= '0';
			keyLeft <= '0';
			keyRight <= '0';
			state <= pending;
		elsif rising_edge(ready) then
			case state is
				when pending =>
					case scancode is
						when "11110000" => -- break code
							state <= keyReleased;
						when "00100100" => -- key E
							keyUp <= '1';
						when "00011011" => -- key S
							keyLeft <= '1';
						when "00100011" => -- key D
							keyDown <= '1';
						when "00101011" => -- key F
							keyRight <= '1';
						when others => -- unused branch
					end case;
				when keyReleased =>
					state <= pending;
					case scancode is
						when "00100100" => -- key E
							keyUp <= '0';
						when "00011011" => -- key S
							keyLeft <= '0';
						when "00100011" => -- key D
							keyDown <= '0';
						when "00101011" => -- key F
							keyRight <= '0';
						when others => -- unused branch
					end case;
			end case;
		end if;
	end process;
end architecture control;
