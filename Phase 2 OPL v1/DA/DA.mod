/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Emil
 * Creation Date: Feb 26, 2014 at 1:08:15 PM
 *********************************************/

/*********************************************
This is the day-ahead unit commitment model,
where forecast wind production and load should
be inputed to create feasible generator setpoints.

It should be run at 12:00 (noon) GMT, as soon as
NordPool reveals the day-ahead spot prices.

The important output is p_sch.
 *********************************************/
 
 // sets
 int Ngen = ...;
 int Ntime = ...;
 
 range generators = 1..Ngen;
 range time = 1..Ntime;
 
 // parameters
 float q_max[generators] = ...; //max setpoint of generators
 float q_min[generators] = ...; //minimum setpoint of generators
 float cost_gen[generators] = ...; //bid cost of each generator - this could be randomised for each run
 float p_da_wind[time] = ...; //wind bid into market
 float p_da_load[time] = ...; //p_da_load bid into market
 float cost_load_shed = ...; //cost of p_da_load shedding
 float cost_wind_spill = ...; //cost of wind spillage
 float bid_ceiling = ...; //gap between max bid in day-ahead market and max production
 
 // decision variables
 dvar float+ p_sch[generators][time]; //production level of generators
 dvar float+ p_da_load_shed[time]; //amount of p_da_load shedding
 dvar float+ p_wind_spill[time]; //amount of wind spillage
 
 // Objective value = cost over 24 hours
dexpr float cost =
  sum(g in generators, t in time) cost_gen[g]*p_sch[g][t]
  	+ sum(t in time) cost_load_shed*p_da_load_shed[t]
  	+ sum(t in time) cost_wind_spill*p_wind_spill[t];

// MODEL
minimize cost;

subject to {
  // Balance constraint
  forall (t in time)
    balance: sum(g in generators) p_sch[g][t] + p_da_wind[t] - p_wind_spill[t] + p_da_load_shed[t] == p_da_load[t];
  
  forall (g in generators, t in time){
  	// minimum generation
  	min_gen: p_sch[g][t] >= q_min[g];
  	// maximum generation
  	max_gen: p_sch[g][t] <= q_max[g]-bid_ceiling;  
  }
}