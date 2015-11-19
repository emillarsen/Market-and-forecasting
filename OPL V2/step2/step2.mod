/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Emil
 * Creation Date: Feb 26, 2014 at 2:14:09 PM
 * Modified: Apr 30, 2014 at 12:11:00 PM
 *********************************************/
 
/*********************************************
This is the true EcoGrid market model, where 
where forecast load, flexibility and balancing power
is inputed to create optimal prices.

It should be run every 30 minutes during the operating
hour, with enough time to ensure it can be sent out on
every half hour. I.e. 8:58 (sent 8:59, valid 9:00), 9:28, 9:58 etc.
*********************************************/
 
 // sets
 int Ngen = ...;
 int Ntime = ...;
 int Nload = ...;
 int min_on = ...;
 
 // ranges
 range generators = 1..Ngen;
 range time = 1..Ntime;
 range load = 1..Nload;
 
 // parameters
 float p_sch[generators][time] = ...; //set point of generators
 float q_max[generators] = ...; //maximum setpoint for generators
 float quant_up[g in generators][t in time] = q_max[g] - p_sch[g][t]; //quantity of up regulation available
 float quant_do[g in generators][t in time] = p_sch[g][t]; //quantity of down regulation available
 float spot_price[time] = ...; //day ahead price
 float cost_wind_spill = ...; //wind shedding cost
 float cost_load_shed = ...; //load shedding cost
 float cost_frequency_control = ...; //frequency control cost
 float flex_load[load] = ...; //bus information about loads
 float p_da_wind[time] = ...; //wind production bid
 float bid_percent = ...; //minimum percentage of bid to be accepted - relaxed to improve feasibility
 float balance[time] = ...; //balance signal
 float p_ur_initial[generators] = ...; //initialisation of up regulating state
 float p_dr_initial[generators] = ...; //initialisation of down regulating state

 // direct import parameters from sintef
 float p_ref_raw[load][time] = ...; //two loads - first fixed second flexible, reference load!
 float p_load_max_raw[load][time] = ...; //what is max flexibility in MW
 float p_load_min_raw[load][time] = ...; //what is min flexibility in MW
 float alpha[load][time] = ...; //price elasticity of load
 
 float scaling_factor = ...; //may change with real data
 // parameters from Sintef scaled for simulated power market
 float p_ref[l in load][t in time] = p_ref_raw[l][t]*scaling_factor;
 float p_load_max[l in load][t in time] = p_load_max_raw[l][t]*scaling_factor; //what is max flexibility in MW
 float p_load_min[l in load][t in time] = p_load_min_raw[l][t]*scaling_factor; //what is min flexibility in MW

 // generator bids
 float price_up[generators][time]; //price for up regulation
 float price_do[generators][time]; //price for down regulation 
 float max_price[t in time] = abs(spot_price[t])*1.5; //maximum price for up regulation
 float price_step[t in time] = (max_price[t] - spot_price[t])/Ngen; //difference in prices for generator bids
 
 // Creates bid prices dynamically
execute {
	for(var t in time) {
		for(var g in generators){
			if (g == 1){
			price_up[g][t] = spot_price[t] + price_step[t];
			price_do[g][t] = spot_price[t] - price_step[t];
			} else {
			price_up[g][t] = price_up[g-1][t]  + price_step[t];
			price_do[g][t] = price_do[g-1][t]  - price_step[t];
			}
 		}
	}
}

 float bin[time]; //behaviour of generators
 // Creates generator behaviour dynamically
execute {
	for(var t in time) {
		if (t%3 == 1){
		bin[t] = 1; //every 3rd time period allow change in setpoint
		} else {
		bin[t] = 0;
		}
	}
	for(var t in time) {
		if (t%6 == 1){
		bin[t+3] = 2; //every 6th time period, plateu must be observed
		}
	}
}
 
 // decision variables
 dvar float+ p_ur[generators][time]; //up regulation provided per generator
 dvar float+ p_dr[generators][time]; //down regulation provided  per generator
 dvar float+ p_load_shed[load][time]; //load shedding
 dvar float+ p_wind_spill[time]; //wind spill
 dvar float+ p_g[generators][time]; //production total (day ahead bid + regulation)
 dvar float+ p_l[load][time]; //total load (inflexible + flexible)
 dvar float+ p_w[time]; //total wind power injected
 dvar float+ price_rt_forecast[load][time]; //real-time price for price-elastic consumers
 
 dvar boolean x[generators][time]; //up regulation delivered
 dvar boolean z[generators][time]; //down regulation delivered
 dvar boolean k[time]; //up regulation global for t
 dvar boolean y[time]; //down regulation global for t
 dvar boolean q[generators][time]; //start up of up regulation
 dvar boolean n[generators][time]; //start up of down regulation
 
 dvar float gencost[generators][time]; //cost of conventional generation
 dvar float changel[load][time]; //change in load
 dvar float gradient_up[generators][time]; //fixed gradient for generators (up reg)
 dvar float gradient_do[generators][time]; //fixed gradient for generators (down reg)
 
 // Objective value = social cost over forecast horizon
dexpr float cost =
  sum(g in generators, t in time) gencost[g][t]
  	+ sum(l in load, t in time) cost_load_shed*p_load_shed[l][t]
  	+ sum(t in time) cost_wind_spill*p_wind_spill[t]
  	+ sum(l in load, t in time) (-spot_price[t]*changel[l][t] + 0.5*alpha[l][t]*changel[l][t]*changel[l][t]);

// MODEL
minimize cost;

subject to {
  forall (g in generators, t in time){
	// Total regulating cost
    con1: gencost[g][t] == price_up[g][t]*p_ur[g][t] - price_do[g][t]*p_dr[g][t] + cost_frequency_control*(p_ur[g][t]+p_dr[g][t]);
    
    // Total conventional generation
    con2: p_g[g][t] == p_sch[g][t] + p_ur[g][t] - p_dr[g][t];
	}
	
  forall (l in load, t in time)
    // Load consumed
    con3: p_l[l][t] == p_ref[l][t] - p_load_shed[l][t] + changel[l][t];
    
  forall (t in time){
	// Total wind injected
    con4: p_w[t] == p_da_wind[t] - p_wind_spill[t];
    
    // Balance constraint
    con5: sum(g in generators) p_g[g][t] + p_w[t] - balance[t] == sum(l in load) p_l[l][t];
  }
  
  forall (g in generators, t in 2..Ntime:(bin[t] == 1)){
	// Up gradient
    con6: gradient_up[g][t] == p_ur[g][t] - p_ur[g][t-1];
	
	// Down gradient
    con7: gradient_do[g][t] == p_dr[g][t] - p_dr[g][t-1];    
  }
  
    forall (g in generators, t in 2..Ntime:(bin[t] == 0)){
	// Up gradient
    con8: gradient_up[g][t] == gradient_up[g][t-1];
	
	// Down gradient
    con9: gradient_do[g][t] == gradient_do[g][t-1];    
  }
  
    forall (g in generators, t in 2..Ntime:(bin[t] == 2)){
	// Up gradient
    con10: gradient_up[g][t] == 0;
	
	// Down gradient
    con11: gradient_do[g][t] == 0;    
  }
  
    forall (g in generators, t in 2..Ntime){
	// Up regulation with ramp
    con12: p_ur[g][t] == p_ur[g][t-1] + gradient_up[g][t];
	
	// Down regulation with ramp
    con13: p_dr[g][t] == p_dr[g][t-1] + gradient_do[g][t];    
  }
  
    forall (g in generators){
	// Up regulation with ramp t0
    con14: p_ur[g][1] == p_ur_initial[g] + gradient_up[g][1];
	
	// Down regulation with ramp t0
    con15: p_dr[g][1] == p_dr_initial[g] + gradient_do[g][1];
  }
  
  forall (g in generators, t in time){
    // Maximum up regulation
    con16: p_ur[g][t] <= x[g][t]*quant_up[g][t];
    
    // Maximum down regulation
    con17: p_dr[g][t] <= z[g][t]*quant_do[g][t];
  }
  
  forall (g in generators, t in time:(bin[t] == 2)){
    // Minimum up regulation
    con18: p_ur[g][t] >= x[g][t]*bid_percent*quant_up[g][t];
    
    // Minimum down regulation
    con19: p_ur[g][t] >= z[g][t]*bid_percent*quant_do[g][t];
  }
  
  forall (g in generators, t in time:(quant_up[g][t] == 0)){
    // Cannot be on if up bid is zero
    con20: x[g][t] == 0;
  }    
  
  forall (g in generators, t in time:(quant_do[g][t] == 0)){
    // Cannot be on if down bid is zero
    con21: z[g][t] == 0;
  }   

  forall (g in generators, t in 2..Ntime){
	// Defines wheather up regulation has started
    con22: q[g][t] >= x[g][t] - x[g][t-1];
    
    // Defines wheather down regulation has started
    con23: n[g][t] >= z[g][t] - z[g][t-1];   
  }

// Minimum on times  
  forall (g in generators, t in min_on..Ntime){
    con24: sum(tt in t-min_on+1..t) q[g][tt] <= x[g][t];
    
    con25: sum(tt in t-min_on+1..t) n[g][tt] <= z[g][t];
  }
  
  forall (g in generators, t in time){
	// Limits search range when optimising con 21
    con26: p_ur[g][t] <= k[t]*quant_up[g][t];
    
    // Limits search range when optimising con 21
    con27: p_dr[g][t] <= y[t]*quant_do[g][t];  
  }
  
  forall (t in time)
    // Up and down regulation cannot be activated simulaneously
    con28: k[t] + y[t] <= 1;
    
  forall (l in load:(flex_load[l] == 1), t in time)
    // Determines real-time price for consumers
    con29: -alpha[l][t]*changel[l][t] == price_rt_forecast[l][t]-spot_price[t];
    
  forall (l in load, t in time){
	// Maximum load consumption
    con30: p_l[l][t] <= p_load_max[l][t];
    
    // Minimum load consumption
    con31: p_l[l][t] >= p_load_min[l][t];
  }
  
  forall (l in load)
    // Accounts for load shifting
    con32: sum(t in time) changel[l][t] == 0;
    }
    
/*********************************************
Important outputs

To send as the real-time price forecast:
price_rt_forecast

As input to step 2 next iteration:
p_ur_initial <- p_ur[g][6]
p_dr_initial <- p_dr[g][6]

For use in step 3:
changel
Nload
price_rt_forecast

For evaluating the market offline:
p_ur
p_dr
quant_up
quant_do
x
z
*********************************************/