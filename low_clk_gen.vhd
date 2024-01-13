library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity low_clk_gen is
		port(
        	clk_in	: in 	std_logic;
			clk_out : out 	std_logic
        );
end;

architecture mixed of low_clk_gen is
	signal	halved_crystal	: std_logic;
	signal	low_clk 		: std_logic;
	signal 	clock_count		: std_logic_vector ( 23 downto 0 );

begin
	clock_divider : process ( clk_in ) is
	begin
		if clk_in 'event and clk_in = '1' then
			if halved_crystal = '1' then
				halved_crystal <= '0';
			else
				halved_crystal <= '1';
			end if;
		end if;
	end process clock_divider;

	clock_counter: process ( halved_crystal) is
	begin
		if halved_crystal'event and halved_crystal= '1' then
			if clock_count = x"FFFFFF" then
				if low_clk = '1' then
					low_clk <= '0';
				else
					low_clk <= '1';
				end if;
				clock_count <= x"3FEE13";
			else 
			   clock_count <= clock_count + x"000001";
			end if;
		end if;	
	end process clock_counter;

	clk_out <= low_clk;
end mixed;


