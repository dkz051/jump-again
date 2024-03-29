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
		-- mover consider deltaX, deltaY (0 or 1), not absolute X, Y
		clk, rst: in std_logic; 
		keyLeft, keyUp, keyRight, crash_Y, crash_down, reverse, reload_map: in std_logic; -- delta_Y is ignored, consider equalY as '1', speed_Y set to 0

		equalX, equalY, plusX, plusY,revG: out std_logic  -- equalX: X+=0 plusX: X+=1(move right) plusY: Y+=1(move down)
		
	    -- delta X, Y, need to be modified by crach checker
	    ); -- when rst, set speed_y to 0, then free falling
end entity;
architecture move of mover is
signal counter_x: integer; -- 50 pixel / second
signal time_accumu_y: integer; -- approximate integral v*dt
signal speed_y: integer; -- instant speed in y direction
signal product: integer;  -- speed_y * time_accumu_y
signal last_keyUp: std_logic; -- monitor the state of keyUp
signal buf_plusY: std_logic;
signal canjump1,canjump2: std_logic; -- flag for jump, reset when touch ground
signal reverse_g: std_logic; -- whether the gravity is reversed
signal buf_reverse: std_logic;
begin
	revG <= reverse_g;
	process(rst,reload_map, reverse) is
	begin
		if rst = '0' or reload_map = '1' then
			reverse_g <= '0';
		elsif rising_edge(reverse) then
			reverse_g <= not reverse_g;
		end if;
	end process;
	process(clk,rst, reload_map) is  -- 500Hz
	begin
		if rst = '0' or reload_map = '1' then
			counter_x <= 0;
			time_accumu_y <= 0;
			speed_y <= 0;
			product <= 0;
			canjump1 <= '1';
			canjump2 <= '1';
			last_keyUp <= '0';
			buf_reverse <= '0';
		elsif rising_edge(clk) then
			
			if last_keyUp = '0' and keyUp = '1' then -- keyUp is pressed
				if canjump2 = '1' then
					canjump2 <= canjump1;
					canjump1 <= '0';
					if reverse_g = '0' then -- check the direction of gravity
						speed_y <= 224; -- after jump, set speed_y to a big value
						product <= to_integer(shift_left(to_signed(time_accumu_y, 31), 7));

					else
						speed_y <= -224;
						product <= -to_integer(shift_left(to_signed(time_accumu_y, 31), 7));

					end if;
				end if;
			end if;
			if counter_x = 9 then -- use appropriate frequency to update X oordinate
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
				if reverse_g = '0' then -- speed_y change because of gravity
				speed_y  <= speed_y - 8;
				product <= product -  to_integer(shift_left(to_signed(time_accumu_y, 31), 3));
				else
				speed_y  <= speed_y + 8;
				product <= product +  to_integer(shift_left(to_signed(time_accumu_y, 31), 3));
				end if;
				
			else
				equalX <= '1';
				counter_x <= counter_x + 1;
			end if;
			if buf_reverse /= reverse_g then
				buf_reverse <= not buf_reverse;
				speed_y <= 0;
				product <= 0;
				time_accumu_y <= 0;
			end if;
			if product > 500 or product < -500 then -- check the integral of vdt in y direction, move 1 pixel if possible
				equalY <= '0';
				time_accumu_y <= 0;
				product <= 0;

				if product > 500 then -- positive speed, move up
					plusY <= '0';
					buf_plusY <= '0';
				else
					plusY <= '1';
					buf_plusY <= '1';
				end if;
			else
				equalY <= '1';
				time_accumu_y <= time_accumu_y + 1;
				product <= product + speed_y; -- update the integral
			end if;
			
			if crash_Y = '1' then -- this signal imply crashing into a block vertically, no move in y_direction
				speed_y <= 0;
				product <= 0;
				time_accumu_y <= 0;
				plusY <= not buf_plusY;
				buf_plusY <= not buf_plusY;
				if reverse_g /= crash_down then --reset jump state
					canjump1 <= '1';
					canjump2 <= '1';
				end if;
			end if;
			
			last_keyUp <= keyUp;
		end if;
	end process;
end architecture move;
