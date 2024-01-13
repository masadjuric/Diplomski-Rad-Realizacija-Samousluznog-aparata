library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity proba is
 port (
  i_refound					  : in  std_logic;
  i_clk                       : in  std_logic;
  i_rstb                      : in  std_logic;
  i_refund_request            : in  std_logic;  -- 1 clock pulse
  i_milk		              : in  std_logic;
  i_chocolate		          : in  std_logic;
  i_sugar		              : in  std_logic_vector(1 downto 0);
  i_sugar_valid				  : in  std_logic;
  i_coffe		              : in  std_logic;
  i_water		              : in  std_logic;
  i_tea 		              : in  std_logic;
  -- from product selector-----------------------------------------------------------
  i_product_sel               : in  std_logic_vector(3 downto 0);  -- '0'=> product 1, '1'=> product 2, dodati vektor
  -- from money check
  i_money_value               : in  std_logic_vector(2 downto 0);  -- '0' => 1 dollar; '1' => five dollars, ovo isto osmisliti koliko ce biti
  i_money_value_valid         : in  std_logic;  -- 1 clock pulse , potvrda unosa novca
  -- to product delivery
  o_product_delivery_sel      : out std_logic_vector(3 downto 0);  -- '0'=> product 1, '1'=> product 2 dodati vektor
  o_product_delivery_sel_ena  : out std_logic;  -- 1 clock pulse potvrda isporuke proizvoda
  -- to delivery refund
  
  o_money_refund_value        : out std_logic_vector(7 downto 0); -- refund value, up to 15 dollars = (2^4)-1 izmeniti skroz
  o_money_refund_value_ena    : out std_logic);  -- 1 clock pulse potvrda kusura
end proba;
architecture rtl of proba is
constant C_PRICE_PRODUCT_1       : integer := 40;
constant C_PRICE_PRODUCT_2       : integer := 50;
constant C_PRICE_PRODUCT_3       : integer := 60;
type t_money_table is array(0 to 6) of integer range 5 to 200; -- is array(0 to 5) of integer range 5 to 200;
constant money_table : t_money_table := (5, 10 , 20 , 50 , 100 , 200 , 1000); -- ovako bi trebalo uz neke izmene (5, 10 , 20 , 50 , 100 , 200)
type t_control_logic_fsm is ( -- stanja promeni nazive
                          ST_RESET                ,
                          ST_CHECK_CREDIT         ,
                          ST_PROVIDE_PRODUCT      ,
                          ST_PROVIDE_TOTAL_REFUND ,
                          ST_ERROR				  );			
signal r_price_product             : integer range -1 to 60; -- cene
signal r_price_product_counter     : integer range 0 to 200;-- cene brojac nmp sta je ovo
signal r_refund                    : integer range 0 to 200;-- kusur
signal r_st_present                : t_control_logic_fsm;
signal w_st_next                   : t_control_logic_fsm;

begin
-- convert input money selector to current money value
-- u zavisnosti od vrednosti signala upisujes kolicinu novca
--------------------------------------------------------------------
-- FSM
p_state : process(i_clk,i_rstb)
begin
  if(i_rstb='0') then
    r_st_present            <= ST_RESET;
  elsif(rising_edge(i_clk)) then
    r_st_present            <= w_st_next;
  end if; 
end process p_state;
p_comb : process(
                 r_st_present                       ,
                 i_product_sel						,
                 i_refund_request                   ,
                 r_price_product_counter            ,
                 i_milk		              			,
				 i_chocolate		          		,
				 i_sugar		              		,
				 i_sugar_valid				  		,
				 i_coffe		              		,
				 i_water		              		,
				 i_tea 								,
                 r_price_product                    ,
                 i_refound							,
                 i_money_value_valid				,
                 i_money_value						
                 )
begin
  case r_st_present is
    when ST_CHECK_CREDIT     =>
	  if(i_refound ='1')then
		w_st_next  <= ST_ERROR;
	  elsif(i_refund_request = '1' and r_price_product_counter /= 0) then
		w_st_next  <= ST_PROVIDE_TOTAL_REFUND;
	  elsif(i_coffe = '0' and (i_product_sel /= "0001" and i_product_sel /= "0011" and i_product_sel /= "1000" )) then
        w_st_next  <= ST_CHECK_CREDIT;
      elsif(i_chocolate = '0' and( i_product_sel > "0110" and i_product_sel < "1011")) then
        w_st_next  <= ST_CHECK_CREDIT;
      elsif(i_water = '0' and (i_product_sel /= "0001" and i_product_sel/= "1000")) then
        w_st_next  <= ST_CHECK_CREDIT;
      elsif(i_milk = '0' and (i_product_sel /= "0010" and i_product_sel /= "0011" and i_product_sel /= "0100" and i_product_sel /= "0111")) then
        w_st_next  <= ST_CHECK_CREDIT;
      elsif(i_tea = '0' and i_product_sel = "0011") then
        w_st_next  <= ST_CHECK_CREDIT;
      elsif(i_sugar /= "00" and i_sugar_valid = '0')then
			w_st_next  <= ST_CHECK_CREDIT;
	  else
		if(i_product_sel = "0000" or i_product_sel > "1011")then 
			w_st_next  <= ST_CHECK_CREDIT;
		else
			if (r_price_product_counter>=r_price_product and r_price_product /= 0) then  -- provera parica
				w_st_next  <= ST_PROVIDE_PRODUCT;
			else
				w_st_next  <= ST_CHECK_CREDIT;
			end if;
		end if;
	  end if;
    when ST_PROVIDE_PRODUCT  =>
	  w_st_next  <= ST_CHECK_CREDIT; -- predji u povratak kusura
    when ST_PROVIDE_TOTAL_REFUND   => -- na pocetak
      w_st_next  <= ST_RESET;
      
	when ST_RESET           => -- ST_RESET            => 
        w_st_next  <= ST_CHECK_CREDIT;
        
    when others             =>
		if(i_refound = '0')then
			w_st_next  <= ST_CHECK_CREDIT;
		else
			w_st_next  <= ST_ERROR;
		end if;
  end case;
end process p_comb;
p_state_out : process(i_clk,i_rstb)
begin
  if(i_rstb='0') then -- restart
    r_refund                   <= 0;
    o_money_refund_value_ena   <= '0';
    o_product_delivery_sel     <= "0000";
    o_product_delivery_sel_ena <= '0';
  elsif(rising_edge(i_clk)) then
    case r_st_present is
      when ST_CHECK_CREDIT           =>
		o_product_delivery_sel_ena <= '0';
        if(i_money_value_valid = '1')then
			if(i_money_value < "110")then
				r_price_product_counter   <= r_price_product_counter + money_table(to_integer(unsigned(i_money_value)));
			end if;
        end if; -- w_money value poslednji ubacen novac
        if(i_product_sel /= "0000" and i_product_sel < "1011") then
			if(i_product_sel < "0011" and i_product_sel > "0000" ) then -- ovo treba izmeniti za sve nase proizvode
				r_price_product            <= 40;
			elsif(i_product_sel < "1001" and i_product_sel > "0010") then
				r_price_product            <= 50;
			elsif(i_product_sel < "1011" and i_product_sel > "1000") then
				r_price_product            <= 60;
			else
				r_price_product            <= 41;
			end if;
			o_money_refund_value_ena   <= '0';
			o_product_delivery_sel     <= i_product_sel;
			
        end if;
        
      when ST_PROVIDE_PRODUCT        =>
		r_price_product_counter    <= r_price_product_counter - r_price_product;
        o_product_delivery_sel_ena <= '1';
        o_money_refund_value_ena   <= '0';
        r_price_product 		   <=  0;
      
      when ST_PROVIDE_TOTAL_REFUND   =>
        r_refund                   <= r_price_product_counter;
        o_product_delivery_sel_ena <= '0';
        o_money_refund_value_ena   <= '1';
        
      when ST_RESET  =>  -- ST_RESET            =>
        r_price_product_counter    <= 0;
        r_refund                   <= 0;
        o_product_delivery_sel_ena <= '0';
        o_money_refund_value_ena   <= '0';
      when others   =>
        r_refund                   <= r_price_product_counter;
        r_price_product_counter    <= 0;
    end case;
  end if;
end process p_state_out;
o_money_refund_value      <= std_logic_vector(to_unsigned(r_refund,8));
end rtl;