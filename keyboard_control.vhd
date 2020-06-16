library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity KeyboardControl is -- PS/2 键盘控制器，按下 E/D/S/F 键时分别产生上、下、左、右信号
	port(
		datain, clkin: in std_logic; -- PS/2 数据、时钟输入
		fclk, rst: in std_logic; -- PS/2 滤波时钟信号、复位信号

		keyUp: out std_logic := '0'; -- 「上」信号（E 键）
		keyDown: out std_logic := '0'; -- 「下」信号（D 键）
		keyLeft: out std_logic := '0'; -- 「左」信号（S 键）
		keyRight: out std_logic := '0' -- 「右」信号（F 键）
	);
end entity KeyboardControl;

architecture control of KeyboardControl is
	type ControlState is (pending, keyReleased); -- 控制器状态机
	component Keyboard is
		port(
			datain, clkin: in std_logic;
			fclk, rst: in std_logic;
			scancode: out std_logic_vector(7 downto 0);
			ready: buffer std_logic
		);
	end component Keyboard;
	signal state: ControlState := pending; -- 状态机状态
	signal scancode: std_logic_vector(7 downto 0) := "00000000"; -- 扫描码
	signal ready: std_logic := '0'; -- PS/2 读取完毕信号
begin
	-- 接入 PS/2 键盘模块
	keys: Keyboard port map(datain, clkin, fclk, rst, scancode, ready);

	process(rst, ready) -- 当 ready = '1' 即 PS/2 处理完一组信号后进入控制进程
	begin
		if rst = '0' then -- 复位信号
			keyUp <= '0';
			keyDown <= '0';
			keyLeft <= '0';
			keyRight <= '0';
			state <= pending;
		elsif rising_edge(ready) then
			case state is
				when pending => -- 识别第一组扫描码
					case scancode is
						when "11110000" => -- break code（断码）
							state <= keyReleased; -- 准备识别第二组扫描码
						when "00100100" => -- E 键
							keyUp <= '1'; -- 注意字母键的扫描码只有一组，所以不用转移
						when "00011011" => -- S 键
							keyLeft <= '1';
						when "00100011" => -- D 键
							keyDown <= '1';
						when "00101011" => -- F 键
							keyRight <= '1';
						when others =>
					end case;
				when keyReleased => -- 识别第二组扫描码
					state <= pending; -- 无论按下了什么键都要回到初始状态
					case scancode is
						when "00100100" => -- E 键
							keyUp <= '0';
						when "00011011" => -- S 键
							keyLeft <= '0';
						when "00100011" => -- D 键
							keyDown <= '0';
						when "00101011" => -- F 键
							keyRight <= '0';
						when others =>
					end case;
			end case;
		end if;
	end process;
end architecture control;
