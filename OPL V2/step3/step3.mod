/*********************************************
 * OPL 12.6.0.0 Model
 * Author: Emil
 * Creation Date: May 7, 2014 at 12:20:46 PM
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
 float price_rt_forecast[load] = ...;
 float changel[load] = ...;
 float balance = ...;
 float spot_price = ...;
 
 // direct import parameters from sintef
 float p_load_max_raw[load] = ...; //what is max flexibility in MW
 float p_load_min_raw[load] = ...; //what is min flexibility in MW
 float alpha[load] = ...; //price elasticity of load

 float scaling_factor = ...; //may change with real data 
 // parameters from Sintef scaled for simulated power market
 
 // the following two are not used, but may be used in phase 3 of demonstration, so important to keep them
 float p_load_max[l in load] = p_load_max_raw[l]*scaling_factor; //what is max flexibility in MW
 float p_load_min[l in load] = p_load_min_raw[l]*scaling_factor; //what is min flexibility in MW
 
 // decision variables
 dvar float price_rt[load];
 
 // Objective value = social cost over forecast horizon
dexpr float difference = sum(l in load) ((price_rt_forecast[l] - price_rt[l])*(price_rt_forecast[l] - price_rt[l]));

// MODEL
minimize difference;

subject to {    
  forall (l in load)
    // Determines real-time price for consumers
    con1: price_rt[l] == -alpha[l]*(changel[l] + balance) + spot_price;
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