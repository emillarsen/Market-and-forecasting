/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Emil
 * Creation Date: Feb 26, 2014 at 2:14:09 PM
 *********************************************/
 
/*********************************************
This is the true EcoGrid market model, where 
where forecast load, flexibility and balancing power
is inputed to create optimal prices.

It should be run every 30 minutes during the operating
hour, 15 minutes before the hour, i.e. 8:45, 9:15, 9:45 etc.

The important output is price_rt, but all the decision
variables and inputs should be logged, so the market
can be evaluated during and after operation.
*********************************************/
 
 // sets
 int Ngen = ...;
 int Ntime = ...;
 int Nload = ...;
 int min_on = ...;
 
 range generators = 1..Ngen;
 range time = 1..Ntime;
 range load = 1..Nload;
 
 // parameters
 float p_max[generators] = ...; //pmax of generators
 float p_sch[generators][time] = ...; //set point of generators
 float price_up[generators][time] = ...; //price for up regulation
 float quant_up[generators][time] = ...; //quantity of up regulation available
 float price_do[generators][time] = ...; //price for down regulation
 float quant_do[generators][time] = ...; //quantity of down regulation available
 float ramp[generators] = ...; //ramping of generators
 float alpha[time] = ...; //price elasticity of load
 float spot_price[time] = ...; //day ahead price
 float cost_wind_spill = ...; //wind shedding cost
 float cost_load_shed = ...; //load shedding cost
 float cost_frequency_control = ...; //frequency control cost
 float plreal[load][time] = ...; //two loads - first fixed second flexible
 float flex_load[load] = ...; //bus information about loads
 float p_wind[time] = ...; //wind production (wind expected)
 float flex_pen[load] = ...; //how much load is flexible
 float r = ...; //minimum proportion of bid to be accepted

 float p_load_max[l in load][t in time] = (1+(flex_pen[l]/100))*plreal[l][t]; //what is max flexibility in MW
 float p_load_min[l in load][t in time] = (1-(flex_pen[l]/100))*plreal[l][t]; //what is min flexibility in MW
 
 // decision variables
 dvar float+ p_ur[generators][time]; //up regulation provided per generator
 dvar float+ p_dr[generators][time]; //down regulation provided  per generator
 dvar float+ p_load_shed[load][time]; //load shedding
 dvar float+ p_wind_spill[time]; //wind spill
 dvar float+ p_g[generators][time]; //production total (day ahead bid + regulation)
 dvar float+ p_l[load][time]; //total load (inflexible + flexible)
 dvar float+ p_w[time]; //total wind power injected
 dvar float+ price_rt[time]; //real-time price for price-elastic consumers
 
 dvar boolean x[generators][time]; //up regulation delivered
 dvar boolean z[generators][time]; //down regulation delivered
 dvar boolean k[time]; //up regulation global for t
 dvar boolean y[time]; //down regulation global for t
 dvar boolean q[generators][time]; //start up of up regulation
 dvar boolean n[generators][time]; //start up of down regulation
 
 dvar float gencost[generators][time]; //cost of conventional generation
 dvar float changel[load][time]; //change in load
 
 // Objective value = social cost over forecast horizon
dexpr float cost =
  sum(g in generators, t in time) gencost[g][t]
  	+ sum(l in load, t in time) cost_load_shed*p_load_shed[l][t]
  	+ sum(t in time) cost_wind_spill*p_wind_spill[t]
  	+ sum(l in load, t in time) (-spot_price[t]*changel[l][t] + 0.5*alpha[t]*changel[l][t]*changel[l][t]);

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
    con3: p_l[l][t] == plreal[l][t] - p_load_shed[l][t] + changel[l][t];
    
  forall (t in time){
	// Total wind injected
    con4: p_w[t] == p_wind[t] - p_wind_spill[t];
    
    // Balance constraint
    con5: sum(g in generators) p_g[g][t] + p_w[t] == sum(l in load) p_l[l][t];
  }
  
  forall (g in generators, t in time){
	// Maximum generated power
    con6: p_g[g][t] <= p_max[g];
    
    // Maximum up regulation
    con7: p_ur[g][t] <= x[g][t]*quant_up[g][t];
    
    // Maximum down regulation
    con8: p_dr[g][t] <= z[g][t]*quant_do[g][t];
    
    // Minimum up regulation
    con9: p_ur[g][t] >= x[g][t]*r*quant_up[g][t];
    
    // Minimum down regulation
    con10: p_ur[g][t] >= z[g][t]*r*quant_do[g][t];
  }
  
  forall (g in generators)
    // Ramp up constraint in first time period
    con11: p_g[g][1] <= p_sch[g][1] + ramp[g];
    
  forall (g in generators, t in 2..Ntime)
    // Ramp up constraint
    con12: p_g[g][t] <= p_g[g][t-1] + ramp[g];
    
  forall (g in generators)
    // Ramp down constraint in first time period
    con13: p_g[g][1] >= p_sch[g][1] - ramp[g];
    
  forall (g in generators, t in 2..Ntime)
    // Ramp down constraint
    con14: p_g[g][t] >= p_g[g][t-1] - ramp[g];
    
  forall (g in generators, t in 2..Ntime){
	// Defines wheather up regulation is in progress
    con15: q[g][t] >= x[g][t] - x[g][t-1];
    
    // Defines wheather down regulation is in progress
    con16: n[g][t] >= z[g][t] - z[g][t-1];   
  }

// Minimum on times  
  forall (g in generators, t in min_on..Ntime){
    con17: sum(tt in t-min_on+1..t) q[g][tt] <= x[g][t];
    
    con18: sum(tt in t-min_on+1..t) n[g][tt] <= z[g][t];
  }
  
  forall (g in generators, t in time){
	// Limits search range when optimising con 21
    con19: p_ur[g][t] <= k[t]*quant_up[g][t];
    
    // Limits search range when optimising con 21
    con20: p_dr[g][t] <= y[t]*quant_do[g][t];  
  }
  
  forall (t in time)
    // Up and down regulation cannot be activated simulaneously
    con21: k[t] + y[t] <= 1;
    
  forall (l in load:(flex_load[l] == 1), t in time)
    // Determines real-time price for consumers
    con22: -alpha[t]*changel[l][t] == price_rt[t]-spot_price[t];
    
  forall (l in load, t in time){
	// Maximum load consumption
    con23: p_l[l][t] <= p_load_max[l][t];
    
    // Minimum load consumption
    con24: p_l[l][t] >= p_load_min[l][t];
  }
  
  forall (l in load)
    // Accounts for load shifting
    con25: sum(t in time) changel[l][t] == 0;
  	
}