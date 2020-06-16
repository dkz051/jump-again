---------------------------------------------------------------------------------------------
-- 创建日期: 2020-05-11
-- 目标芯片: EP2C70F672C8
-- 时钟选择: 100 MHz
---------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity JumpAgain is -- 顶层 entity
	port(
		ps2Data, ps2Clock: in std_logic; -- 接 PS/2 数据、时钟信号
		clock, reset: in std_logic; -- 接 100M 时钟和 RST 按钮

		rx: in std_logic; -- 接 UART RX 信号

		vgaHs, vgaVs: out std_logic; -- VGA 行、场同步信号
		vgaR, vgaG, vgaB: out std_logic_vector(2 downto 0); -- VGA 红绿蓝分量 (0-7)

		-- 以下 12 个信号接到 LED 上（原则上可以接数码管 56 个信号中的任何一组），将上下左右四个信号显示出来（调试用）
		kUp, kDown, kLeft, kRight: out std_logic; -- 键盘上(E)下(D)左(S)右(F)键，注意不是 WASD 键位
		sUp, sDown, sLeft, sRight: out std_logic; -- 传感器输出的上下左右信号
		up, down, left, right: out std_logic -- 组合上下左右信号（键盘信号和传感器信号取「或」）
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

	component Sensor is
		port(
			clock: in std_logic;
			reset: in std_logic;
			rx: in std_logic;
			up, down, left, right: out std_logic
		);
	end component;

	component VgaController is
		port(
			reset: in std_logic;
			clock: in std_logic;
			hs, vs: out std_logic;
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
			signal num_of_map: in integer;
			signal reset: in std_logic;
			signal clock: in std_logic;

			signal heroX,enemyX: in std_logic_vector(9 downto 0);
			signal heroY,enemyY: in std_logic_vector(8 downto 0);
			signal enemy_exist, reverse_g: in std_logic;

			signal readAddress: out std_logic_vector(15 downto 0);
			signal readOutput: in std_logic_vector(8 downto 0);

			signal writeAddress: out std_logic_vector(13 downto 0);
			signal writeContent: out std_logic_vector(8 downto 0);

			signal imageReadAddress: out std_logic_vector(14 downto 0);
			signal imageColorOutput: in std_logic_vector(8 downto 0);

			signal heroReadAddress: out std_logic_vector(14 downto 0);
			signal heroColorOutput: in std_logic_vector(8 downto 0);

			signal directions: in std_LOGIC_VECTOR(2 downto 0);
			signal herox_20, heroy_20: in integer
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
			clk, rst: in std_logic;
			keyLeft, keyRight, keyUp: in std_logic;
			curX, enemyX: out std_logic_vector(9 downto 0);
			curY, enemyY: out std_logic_vector(8 downto 0);
			enemy_exist, reverse_g: out std_logic;
			num_of_map: out integer;
			mapReadAddress: out std_logic_vector(15 downto 0);
			mapReadReturn: in std_logic_vector(8 downto 0);
			move_direction: out std_logic_vector(2 downto 0);
			herox_20, heroy_20: out integer
	    );
	end component logicloop;

	component images
		port(
			address_a: in std_logic_vector(14 downto 0);
			address_b: in std_logic_vector(14 downto 0);
			clock: in std_logic := '1';
			q_a: out std_logic_vector(8 downto 0);
			q_b: out std_logic_vector(8 downto 0)
		);
	end component;

	signal heroX, enemyX: std_logic_vector(9 downto 0); -- 主角、敌人的 X 坐标
	signal heroY, enemyY: std_logic_vector(8 downto 0); -- 主角、敌人的 Y 坐标
	signal enemy_exist: std_logic; -- 敌人是否存在

	signal keyUp, keyDown, keyLeft, keyRight: std_logic; -- 键盘输入信号，从 [KeyboardController] 传来
	signal sensorUp, sensorDown, sensorLeft, sensorRight: std_logic; -- 传感器输入信号，从 [Sensor] 传来

	signal videoClock: std_logic; -- VGA 时钟（25 MHz）
	signal sramClock: std_logic; -- SRAM 时钟（未使用，废弃）
	signal renderClock: std_logic; -- Renderer 时钟（25 MHz）

	signal logicReadAddress: std_logic_vector(15 downto 0); -- ROM Logic: 读取地址（关卡数据）
	signal logicReadReturn: std_logic_vector(8 downto 0); -- ROM Logic: 读取结果

	signal rendererReadAddress: std_logic_vector(15 downto 0); -- ROM Renderer: 读取地址（关卡数据）
	signal rendererReadReturn: std_logic_vector(8 downto 0); -- ROM Renderer: 读取结果

	signal videoReadAddress: std_logic_vector(13 downto 0); -- VGA 从显存中读取的地址
	signal videoColorOutput: std_logic_vector(8 downto 0); -- VGA 读取显存结果

	signal videoWriteAddress: std_logic_vector(13 downto 0); -- [Renderer] 向显存写入的地址
	signal videoWriteContent: std_logic_vector(8 downto 0); -- [Renderer] 向显存写入的数据

	-- 注意：主角和砖块素材图案均在同一块 ROM 中，但通过两个通道操作（方便编写代码）
	signal imageReadAddress: std_logic_vector(14 downto 0); -- [Renderer] 读取砖块素材地址
	signal imageColorOutput: std_logic_vector(8 downto 0); -- [Renderer] 读取的砖块素材颜色值

	signal heroReadAddress: std_logic_vector(14 downto 0); -- [Renderer] 读取主角素材地址
	signal heroColorOutput: std_logic_vector(8 downto 0); -- [Renderer] 读取的主角素材颜色值

	signal directions: std_logic_vector(2 downto 0); -- 由 [Renderer] 返回，决定选择哪一块主角素材进行绘制

	signal num_of_map: integer; -- 地图数量
	signal reverseG: std_logic; -- 是否重力反向

	signal herox_20, heroy_20: integer; -- 主角坐标对 20 取模，决定对应主角素材中的具体位置
begin
	-- 连接 PS/2 键盘
	keyboard: KeyboardControl port map(ps2Data, ps2Clock, clock, reset, keyUp, keyDown, keyLeft, keyRight);

	-- 连接传感器（Arduino）
	arduino: Sensor port map(clock, reset, rx, sensorUp, sensorDown, sensorLeft, sensorRight);

	-- 将实际的上下左右信号显示在 LED 上
	up <= keyUp or sensorUp;
	down <= keyDown or sensorDown;
	left <= keyLeft or sensorLeft;
	right <= keyRight or sensorRight;

	-- 将键盘输入显示在 LED 上
	kUp <= keyUp;
	kDown <= keyDown;
	kLeft <= keyLeft;
	kRight <= keyRight;

	-- 将传感器输入显示在 LED 上
	sUp <= sensorUp;
	sDown <= sensorDown;
	sLeft <= sensorLeft;
	sRight <= sensorRight;

	-- 锁相环 (PLL)，产生 VGA 和 SRAM 所用时钟（其中 VGA 时钟频率为 25 MHz，SRAM 时钟弃用）
	pllClock: pll port map(not reset, clock, videoClock, sramClock, open);

	renderClock <= videoClock; -- [Renderer] 和 VGA 采用同步信号

	-- 连接 VGA 模块
	vga: VgaController port map(reset, videoClock, vgaHs, vgaVs, vgaR, vgaG, vgaB, videoReadAddress, videoColorOutput);

	-- 连接 Renderer
	render: Renderer port map(
		num_of_map, -- 地图数量
		reset, -- RST 复位信号
		renderClock, -- 渲染器所用时钟
		heroX, enemyX, heroY, enemyY, enemy_exist, -- 主角 X/敌人 X/主角 Y/敌人 Y/敌人是否存在
		reverseG, -- 重力反向标志
		rendererReadAddress, rendererReadReturn, -- 连接关卡数据 ROM
		videoWriteAddress, videoWriteContent, -- 连接显存
		imageReadAddress, imageColorOutput, -- 连接砖块素材 ROM
		heroReadAddress, heroColorOutput, -- 连接主角图像素材 ROM（和砖块素材在同一块 ROM 里）
		directions, -- 主角朝向（左/右）、运行状态（静止/向上/向下）
		herox_20, heroy_20 -- 主角坐标对 20 取模（决定绘制素材中的哪个点）
	);

	-- 连接砖块素材 ROM
	image: images port map(imageReadAddress, heroReadAddress, clock, imageColorOutput, heroColorOutput);

	-- [Logic] 逻辑模块
	logic: logicloop port map(
		-- 逻辑运算时钟/复位信号/向左/向右/向上信号
		clock, reset, keyLeft or sensorLeft, keyRight or sensorRight, keyUp or sensorUp,
		-- 主角 X/敌人 X/主角 Y/敌人 Y/敌人是否存在/重力反向标志
		heroX, enemyX, heroY, enemyY, enemy_exist, reverseG,
		-- 地图数量/读关卡数据的哪个地址/读出来的相应关卡数据
		num_of_map, logicReadAddress, logicReadReturn,
		-- 朝向方向信息/主角坐标对 20 取模的结果
		directions, herox_20, heroy_20
	);

	-- 连接显存
	videoMemory: video_memory port map(videoReadAddress, videoWriteAddress, clock, (others => '0'), videoWriteContent, '0', '1', videoColorOutput, open);

	-- 连接关卡数据 ROM
	dataMemory: data port map(rendererReadAddress, logicReadAddress, clock, (others => '0'), (others => '0'), '0', '0', rendererReadReturn, logicReadReturn);
end architecture jump;
