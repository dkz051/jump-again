library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Keyboard is -- PS/2 键盘模块
	port (
		datain, clkin: in std_logic; -- PS/2 数据、时钟信号输入
		fclk: in std_logic; -- 滤除毛刺用的时钟（100M 时钟）
		rst: in std_logic; -- 复位信号
		scancode: out std_logic_vector(7 downto 0); -- 扫描码输出（供 KeyboardController 使用）
		ready: buffer std_logic -- 扫描码识别完毕时置 1，表示可以被后续处理流程读取
	);
end entity Keyboard;

architecture rtl of Keyboard is
	type state_type is (delay, start, d0, d1, d2, d3, d4, d5, d6, d7, parity, stop, finish); -- PS/2 键盘状态机
	signal data, clk, clk1, clk2, odd: std_logic; -- PS/2 数据位；clk, clk1, clk2 为滤波信号；odd: 校验位信号
	signal code: std_logic_vector(7 downto 0); -- 保存扫描码已被识别的部分
	signal state: state_type; -- 状态机当前状态
begin
	-- 滤波
	clk1 <= clkin when rising_edge(fclk);
	clk2 <= clk1 when rising_edge(fclk);
	clk <= (not clk1) and clk2;
	-- 读入数据
	data <= datain when rising_edge(fclk);
	-- 校验位生成
	odd <= code(0) xor code(1) xor code(2) xor code(3) xor code(4) xor code(5) xor code(6) xor code(7);

	process(rst, fclk) -- 扫描码输入
	begin
		if rst = '0' then
			state <= delay;
			code <= (others => '0');
			ready <= '0';
		elsif rising_edge(fclk) then
			ready <= '0';
			case state is
				when delay => -- 启动
					state <= start;
				when start => -- 激活进入扫描码状态
					if clk = '1' then
						if data = '0' then
							state <= d0;
						else
							state <= delay;
						end if;
					end if;
				when d0 => -- 读取第 1 位
					if clk = '1' then
						code(0) <= data;
						state <= d1;
					end if;
				when d1 => -- 读取第 2 位
					if clk = '1' then
						code(1) <= data;
						state <= d2;
					end if;
				when d2 => -- 读取第 3 位
					if clk = '1' then
						code(2) <= data;
						state <= d3;
					end if;
				when d3 => -- 读取第 4 位
					if clk = '1' then
						code(3) <= data;
						state <= d4;
					end if;
				when d4 => -- 读取第 5 位
					if clk = '1' then
						code(4) <= data;
						state <= d5;
					end if;
				when d5 => -- 读取第 6 位
					if clk = '1' then
						code(5) <= data;
						state <= d6;
					end if;
				when d6 => -- 读取第 7 位
					if clk = '1' then
						code(6) <= data;
						state <= d7;
					end if;
				when d7 => -- 读取第 8 位，然后进入校验状态
					if clk = '1' then
						code(7) <= data;
						state <= parity;
					end if;
				when parity => -- 奇偶校验
					if clk = '1' then
						if (data xor odd) = '1' then
							state <= stop;
						else
							state <= delay;
						end if;
					end if;
				when stop => -- 终止
					if clk = '1' then
						if data = '1' then
							state <= finish;
						else
							state <= delay;
						end if;
					end if;
				when finish => -- 完成一个周期
					state <= delay;
					ready <= '1'; -- 扫描码已可供读取
					scancode <= code; -- 输出扫描码
				when others =>
					state <= delay;
			end case;
		end if;
	end process;
end architecture rtl;
