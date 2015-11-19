/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Emil
 * Creation Date: Feb 26, 2014 at 1:08:15 PM
 * Modified: Apr 30, 2014 at 12:11:00 PM
 *********************************************/

/*********************************************
This is the day-ahead unit commitment model,
where forecast wind production and load should
be inputed to create feasible generator setpoints.

It should be run at 12:00 (noon) GMT, as soon as
NordPool reveals the day-ahead spot prices.
*********************************************/

 int Ntime = ...;
 int Ngen = ...;
 int Nfive = ...;
 
 range time = 1..Ntime;
 range generators = 1..Ngen;
 range five = 1..Nfive;
 
 // initialisation of max generator capacities
 float generator_total_capacity = ...; //related to the scaling factor and size of balancing signal
 float rand_max_sch[g in generators] = rand(Ngen); //create some random setpoints - problematic because rand doesn't work
 float sum_rand_max_sch = sum(g in generators) rand_max_sch[g]; //what is the maximum of these random setpoints?
 float multiplier = generator_total_capacity/sum_rand_max_sch; //scaling factor considering random setpoints
 float q_max[g in generators] = multiplier*rand_max_sch[g]; //scale generators to meet the total generator capacity

 // parameters
 float q_min[g in generators] = 0; //minimum setpoint of generators 
 float p_da_wind[time] = ...; //wind bid into market
 float cost_load_shed = ...; //cost of p_da_load shedding
 float cost_wind_spill = ...; //cost of wind spillage
 float gap = ...; //percentage gap between max bid in day-ahead market and max production
 float ramp = ...; //ramp limit for generators

 // day load forecasting (initialisation of day ahead load bid)
 float week_load[five] = ...; //p_da_load bid into market
 range forecast_length = 1..288; //may be tweaked when real data arrives
 float p_da_load_raw[time];

/*********************************************
This basic forecasting method takes the half
hour hour value for each hour a week ago and
uses it as the forecast day-ahead load
forecast (Øsktraft method)
*********************************************/
execute {
	var c = 1;
	for(var f in forecast_length) {
		if ((f%12)-6 == 1){
		p_da_load_raw[c] = week_load[f]
		c = c+1;
		}
	}
}

 //now scale the load
 float scaling_factor = ...;
 float p_da_load[t in time] = p_da_load_raw[t]*scaling_factor; //p_da_load bid into market
 
 // decision variables
 dvar float+ p_sch[generators][time]; //production level of generators
 dvar float+ p_da_load_shed[time]; //amount of p_da_load shedding
 dvar float+ p_wind_spill[time]; //amount of wind spillage
 dvar boolean u[generators][time]; //generator on or off
 
 // Objective value = cost over 24 hours
dexpr float cost = sum(t in time) cost_load_shed*p_da_load_shed[t]
  		+ sum(t in time) cost_wind_spill*p_wind_spill[t];

// MODEL
minimize cost;

subject to {
  // Balance constraint
  forall (t in time)
    balance: sum(g in generators) p_sch[g][t] + p_da_wind[t] - p_wind_spill[t] == p_da_load[t] - p_da_load_shed[t];
  
  forall (g in generators, t in time){
  	// minimum generation
  	min_gen: p_sch[g][t] >= u[g][t]*q_min[g];
  	
  	// maximum generation
  	max_gen: p_sch[g][t] <= u[g][t]*(q_max[g]-gap*q_max[g]);
 }
 
 forall (g in generators, t in 2..Ntime){  	
  	// ramp up limit
  	ramp_up: p_sch[g][t] - p_sch[g][t-1] <= ramp;
  	
  	// ramp down limit
  	ramp_do: p_sch[g][t-1] - p_sch[g][t] <= ramp;
  }
}

/*********************************************
Important outputs

For use in step 2:
p_sch
p_da_wind
q_max
Ngen
scaling_factor

For evaluating the market offline:
p_da_load_raw
p_da_load
*********************************************/