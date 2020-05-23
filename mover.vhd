library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; 
entity mover is
	-- mover don't care about grid crash 
	-- mover cares about "keyboard" input and "gravity" 
	-- y speed is variable, x speed is not variable
	port(
		-- x_t, y_t, s_t are all integer types
		-- x_t, y_t for coordinate, s_t for speed
		-- should we use higher resolution than 640*480 in computing?
		-- not much overhead if x is 0 to 64000, y is 0 to 48000 when physics simulation?	
		-- mover consider deltaX, deltaY (0 or 1), not absolute X, Y
		clk, rst: in std_logic; -- clk is very important for this component
		keyLeft, keyUp, keyRight, crash_Y: in std_logic; -- delta_Y is ignored, consider equalY as '1', speed_Y set to 0
		
		equalX, equalY, plusX, plusY: buffer std_logic  -- equalX: X+=0 plusX: X+=1(move right) plusY: Y+=1(move down)
	    -- delta X, Y, need to be modified by crach checker
	    ); -- when rst, set speed_y to 0, then free falling
end entity;
architecture move of mover is 
signal counter_x: integer; -- 50 pixel / second
signal time_accumu_y: integer;
signal speed_y: integer;
signal product: integer;  -- speed_y * time_accumu_y
signal last_keyUp: std_logic;
begin
	process(clk,rst) is  -- 500Hz
	begin
		if rst = '0' then
			counter_x <= 0;
			time_accumu_y <= 0;
			speed_y <= 0;
			product <= 0;
		elsif rising_edge(clk) then
			if last_keyUp = '0' and keyUp = '1' then
				speed_y <= 128;
				product <= to_integer(shift_left(to_signed(time_accumu_y, 31), 7));
			end if;
			if counter_x = 9 then
				counter_x <= 0;
				if keyLeft = '1' and keyRight = '0' then
					equalX <= '0';
					plusX <= '0';
				elsif keyLeft = '0' and keyRight = '1' then
					equalX <= '0';
					plusX <= '1';
				else 
					equalX <= '1';
				end if;
				speed_y  <= speed_y - 5;
				product <= product - time_accumu_y - to_integer(shift_left(to_signed(time_accumu_y, 31), 2));
			else
				equalX <= '1';
				counter_x <= counter_x + 1;
			end if;
			if crash_Y = '1' then
				speed_y <= 0;
				product <= 0;
				time_accumu_y <= 0;
				plusY <= not plusY;
			end if;
			if product > 500 or product < -500 then
				equalY <= '0';
				time_accumu_y <= 0;
				product <= 0;
				
				if product > 500 then -- positive speed, move up
					plusY <= '0';
				else
					plusY <= '1';
				end if;
				
			else
				equalY <= '1';
				time_accumu_y <= time_accumu_y + 1;
				product <= product + speed_y;
			end if;
			last_keyUp <= keyUp;
		end if;
	end process;
end architecture move;
