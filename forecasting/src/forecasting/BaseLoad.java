package forecasting;

import java.lang.Math;
import java.util.Arrays;

public class BaseLoad {

	static double[][] baseLoad(double[] time_index, int forecast_start_index){
		int Nfterms = 28; //number of fourier terms for daily load pattern
		int period = 288; //maximum period of oscillation
		double[][] base_load_var = new double[288*4][Nfterms*2]; //fourier terms (base load)
		
		for (int t = ((int)(time_index[1]) + forecast_start_index -2); t < 288*4; t++)
		{
			for (int f = 0; f < Nfterms; f++)
			{
				base_load_var[t-((int)(time_index[1]) + forecast_start_index-2)][(2*f)+1] = Math.cos(2*Math.PI*(f+1)*(t+1)/period);
				base_load_var[t-((int)(time_index[1]) + forecast_start_index-2)][2*f] = Math.sin(2*Math.PI*(f+1)*(t+1)/period);
			}
		}
		
		return base_load_var;
	}
}