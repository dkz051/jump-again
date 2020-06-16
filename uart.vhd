library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Uart is
	port(
		clock: in std_logic; -- 100 MHz 时钟输入
		reset: in std_logic; -- 复位信号
		rx: in std_logic; -- 串口 RX 接收信号（JumpAgain 用不到 TX 发出信号）
		data: out std_logic_vector(7 downto 0) -- RX 接收到的字节 (8-bit)
	);
end entity Uart;

architecture Transact of Uart is
	signal uartCount: integer range 0 to 10416 := 0; -- 波特率分频时钟
	signal uartClock: std_logic; -- 波特率输出时钟
	signal rx8bit: std_logic_vector(7 downto 0); -- 暂存串口接收到的字节 (8-bit)，只有在整个字节读取完毕时才会输出
	signal state: integer range 0 to 9; -- 状态机（用整数实现）
begin
	-- 波特率发生器
	process(reset, clock)
	begin
		if reset = '0' then -- 复位
			uartCount <= 0;
			uartClock <= '0';
		elsif rising_edge(clock) then -- 时钟计数器
			if uartCount = 10416 then -- 9600 波特率，100M / 9600 = 10416.6666667
				uartCount <= 0;
				uartClock <= '1'; --波特率高电平
			else
				uartCount <= uartCount + 1;
				uartClock <= '0'; --波特率低电平
			end if;
		end if;
	end process;

	-- RX 状态机
	process(reset, clock)
	begin
		if reset = '0' then
			rx8bit <= (others => '1');
		elsif rising_edge(uartClock) then
			case state is
				when 0 => -- 识别起始位 '0'
					if rx = '0' then
						state <= state + 1;
					end if;
				when 1 => -- 识别第 1 个数据位
					rx8bit(0) <= rx;
					state <= state + 1;
				when 2 => -- 识别第 2 个数据位
					rx8bit(1) <= rx;
					state <= state + 1;
				when 3 => -- 识别第 3 个数据位
					rx8bit(2) <= rx;
					state <= state + 1;
				when 4 => -- 识别第 4 个数据位
					rx8bit(3) <= rx;
					state <= state + 1;
				when 5 => -- 识别第 5 个数据位
					rx8bit(4) <= rx;
					state <= state + 1;
				when 6 => -- 识别第 6 个数据位
					rx8bit(5) <= rx;
					state <= state + 1;
				when 7 => -- 识别第 7 个数据位
					rx8bit(6) <= rx;
					state <= state + 1;
				when 8 => -- 识别第 8 个数据位
					rx8bit(7) <= rx;
					state <= state + 1;
				when 9 => -- 识别终止位 '1'
					if rx = '1' then
						data <= rx8bit; -- 输出字节数据
					end if;
					state <= 0;
				when others =>
					state <= 0;
			end case;
		end if;
	end process;
end architecture Transact;
