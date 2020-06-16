library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity Sensor is -- 传感器模块
	port(
		clock: in std_logic; -- 100 MHz 时钟输入
		reset: in std_logic; -- 复位信号输入
		rx: in std_logic; -- UART 串口接收信号
		up, down, left, right: out std_logic -- 上下左右信号输出
	);
end entity;

architecture Control of Sensor is
	component Uart is
		port(
			clock: in std_logic;
			reset: in std_logic;
			rx: in std_logic;
			data: out std_logic_vector(7 downto 0)
		);
	end component Uart;
	signal rxData: std_logic_vector(7 downto 0);
begin
	connect: Uart port map(clock, reset, rx, rxData); -- 连接串口控制器
	-- 接收到的字节的高 4 位不使用，低 4 位从高到低分别为上下左右信号
	up <= rxData(3);
	down <= rxData(2);
	left <= rxData(1);
	right <= rxData(0);
end architecture Control;
