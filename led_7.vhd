library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Led7 is
	port(
		value: in std_logic_vector(3 downto 0);
		segments: out std_logic_vector(6 downto 0) -- 6 to 0: a to g respectively
	);
end entity Led7;

architecture led of Led7 is
begin
	process (value)
	begin
		case value is
			when "0000" => segments <= "1111110";
			when "0001" => segments <= "1100000";
			when "0010" => segments <= "1011101";
			when "0011" => segments <= "1111001";
			when "0100" => segments <= "1100011";
			when "0101" => segments <= "0111011";
			when "0110" => segments <= "0111111"; -- 6 segments instead of 5, to prevent confusion between 6 and b
			when "0111" => segments <= "1101000";
			when "1000" => segments <= "1111111";
			when "1001" => segments <= "1111011";
			when "1010" => segments <= "1101111";
			when "1011" => segments <= "0110111";
			when "1100" => segments <= "0011110";
			when "1101" => segments <= "1110101";
			when "1110" => segments <= "0011111";
			when "1111" => segments <= "0001111";
			when others => segments <= "0000000";
		end case;
	end process;
end architecture led;
