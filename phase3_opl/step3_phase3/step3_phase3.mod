/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Emil
 * Creation Date: Oct 10, 2014 at 12:11:00 PM
 *********************************************/

/*********************************************
This is the five minute imbalance model that 
fixes the real-time price for the next five
minutes. If step 2 was run less than five
minutes ago, then this model is not run (i.e.
price_rt = price_rt_forecast(t)).

Otherwise, this model should be run every five
minutes, so that the real-time price can be
sent to customers 1 minute before the settlement
period (i.e. 4:59, 5:04, 5:09 etc.)
*********************************************/

 // sets
 int Nload = ...;
 
 // ranges
 range load = 1..Nload;
 
 // parameters
 float cost_load_shed = ...; //load shedding cost
 float scaling_factor = ...; //may change with real data
 float price_rt_forecast[load] = ...;
 float changel[load] = ...;
 float balance = ...;
 float spot_price = ...;
 
  // direct import parameters from sintef
 float consumption_split_ratio[load] = ...; //how is the load split for phase 3?
 float p_ref_raw[load] = ...; //two loads - first fixed second flexible, reference load!
 float alpha_raw[load] = ...; //price elasticity of load
 float eur_to_dkk = 7.444; //convert alpha from Euro to DKK
 float alpha[l in load] = eur_to_dkk*alpha_raw[l]/consumption_split_ratio[l]; // readjust alpha for different loads
 float p_ref[l in load] = p_ref_raw[l]*scaling_factor;
 
  // values from WP6 until Sintef provides them
 float changel_max_raw[l in load] = p_ref_raw[l]*0.1; //what is max flexibility in MW
 float changel_min_raw[l in load] = -p_ref_raw[l]*0.1; //what is min flexibility in MW
 
 float flex_load[load] = ...; //bus information about loads
 
 // parameters from Sintef scaled for simulated power market
 float changel_max[l in load] = changel_max_raw[l]*flex_load[l]*scaling_factor; //what is max flexibility in MW
 float changel_min[l in load] = changel_min_raw[l]*flex_load[l]*scaling_factor; //what is min flexibility in MW

 // phase 3 adjustment
 float p_l_measured_raw[load] = ...; //last aggregated load measurements in kW
 float p_l_max_raw[load] = ...; //maximum load for virtual feeders in kW
 float threshold_percent[load] = ...; //what is the threshold beyond which prices should start rising?

 float p_l_measured[l in load] = p_l_measured_raw[l]*scaling_factor; // scaled to synthetic market size
 float p_l_max[l in load] = p_l_max_raw[l]*scaling_factor; // " scaled up
 float threshold[l in load] = p_l_max[l]*threshold_percent[l]; // " scaled up
 float phase_3_adjustment[load];
 
 execute {
  for(var l in load){
	  if(p_l_measured[1]>threshold[1]){
	  	  phase_3_adjustment[1] = (p_l_measured[1]-threshold[1])/2; // how much is load over threshold by?
  	  	  phase_3_adjustment[2] = -phase_3_adjustment[1]; // shift some flexible demand to non-congested load
      }else{
 	  	  phase_3_adjustment[l] = 0;
	  }
   }
 }

 // decision variables
 dvar float price_rt[load];
 dvar float+ p_load_shed[load];
 dvar float new_change_l[load];
 
 // Multi-objective function is to reduce the load shedding and difference in prices
dexpr float difference = sum(l in load) (p_load_shed[l]*cost_load_shed + ((price_rt_forecast[l] - price_rt[l])*(price_rt_forecast[l] - price_rt[l])));

// MODEL
minimize difference;

subject to {    
  forall (l in load){

    // System balance constraint
    con1: (sum(l in load) (new_change_l[l] - p_load_shed[l] - changel[l])) == - balance;

	// Maximum flexible load consumption
    con2: new_change_l[l] <= changel_max[l];
    
    // Minimum flexible load consumption
    con3: new_change_l[l] >= changel_min[l];
    
    // Maximum load for virtual feeders
    con4: p_ref[l] - p_load_shed[l] + new_change_l[l] + phase_3_adjustment[l] <= p_l_max[l];
    
    // Determines real-time price for consumers
    con5: price_rt[l] == -alpha[l]*new_change_l[l] + spot_price;
    
    // Only shed load if there is load to shed
    con6: p_load_shed[l] <= p_ref[l];
    
  }
}

/*********************************************
Important outputs

To send as the real-time price:
price_rt

For evaluating the market offline:
p_load_max
p_load_min
alpha
changel
*********************************************/