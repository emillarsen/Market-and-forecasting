package forecasting;

import java.util.Arrays;

public class MeanPriceMethod {
	
	// function to find relative prices
		public static void meanPriceMethod(double[] day_ahead_price,
				double[] newOptimzation, int rowNow, double[] time_index) {
			
			int start_index = 0; // vector of day ahead price indices
			int end_index = -1;
			double[] relative_dap = day_ahead_price.clone();
			double[] relative_dap_mean_adjusted = day_ahead_price.clone();
			double[] mean_dap_int = day_ahead_price.clone();

			if (time_index[0] >= newOptimzation[1]
					&& time_index[0] < newOptimzation[0]) {
				for (int i = 0; i < time_index.length; i++) {
					if (time_index[i] == newOptimzation[1]) {
						end_index = i;
						break;
					}
				}
			} else {
				for (int i = 0; i <= time_index.length; i++) {
					if (time_index[i] == newOptimzation[0]+1) {
						end_index = i;
						break;
					}
				}
			}
						
			for (int t = 0; t < day_ahead_price.length; t++) // go through all prices in input data
			{
				for (int i = 0; i <= newOptimzation.length; i++)
				{
					// when a new optimization period starts
					if (time_index[t] == newOptimzation[0] || time_index[t] == newOptimzation[1])
					{
						start_index = t;
						end_index = t+287;
					}
				}
				
				// get the mean day-ahead price
				double[] mean_dap = Arrays.copyOfRange(relative_dap_mean_adjusted, start_index, end_index);

				double sum = 0;
				for (int z = 0; z < mean_dap.length; z++)
				{
				    sum += mean_dap[z];
				    if (t == 15){
				    System.out.print(mean_dap[z]);
				    System.out.print("---\n###");
				    }
				}
			    if (t == 15){
			    //ImportDisplay.printMyVector(mean_dap);
			    }
			    
				mean_dap_int[t] = sum/(mean_dap.length);
				
				relative_dap_mean_adjusted[t] = day_ahead_price[t] - mean_dap_int[t];
			}
			//ImportDisplay.printMyVector(mean_dap_int);
			Forecast.day_ahead_price = relative_dap.clone();
		}
}
