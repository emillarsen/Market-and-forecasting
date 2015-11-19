package forecasting;

import java.util.Arrays;

public class RelativePriceMethod {

	// function to find relative prices
		public static void relativePriceMethod(double[] real_time_price,
				double[] hour_ahead_price, double[] day_ahead_price,
				double[] newOptimzation, int rowNow, double[] time_index) {
			
			int start_index = 0; // vector of day ahead price indices
			int end_index = -1;;
			double[] relative_dap = day_ahead_price.clone();
			double[] relative_hap = hour_ahead_price.clone();
			double[] relative_rtp = real_time_price.clone();
			
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
				
				// get the maximum and minimum day ahead prices
				double[] sorted_dap = Arrays.copyOfRange(day_ahead_price, start_index, end_index);
				Arrays.sort(sorted_dap);
				double minimum_dap = sorted_dap[0];
				double maximum_dap = 0;
				for (int i = 0; i < sorted_dap.length; i++) {
					  if (!Double.isNaN(sorted_dap[i])) {
						  maximum_dap = sorted_dap[i];
					  }
				}
							
				relative_dap[t] = (day_ahead_price[t] - minimum_dap)/(maximum_dap - minimum_dap);
				relative_hap[t] = hour_ahead_price[t] - day_ahead_price[t];
				relative_rtp[t] = real_time_price[t] - day_ahead_price[t];
				
				if (Double.isNaN(relative_dap[t])) relative_dap[t] = 0.5;
				if (Double.isNaN(relative_hap[t])) relative_hap[t] = 0;
				if (Double.isNaN(relative_rtp[t])) relative_rtp[t] = 0;
			}
			Forecast.day_ahead_price = relative_dap.clone();
			Forecast.hour_ahead_price = relative_hap.clone();
			Forecast.real_time_price = relative_rtp.clone();
		}
}
