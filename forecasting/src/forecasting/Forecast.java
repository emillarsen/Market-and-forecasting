package forecasting;

import java.lang.Math;
import java.util.Arrays;

public class Forecast {

	public static void main(String[] args) {
		
		// print to console commands
//		ImportDisplay.printMyArray(3,36,beta_2);
//		ImportDisplay.printMyVector(temperature_lagged_6);
//		System.out.print(forecast_start_index);
		
		// import variables
		real_time_price = ImportDisplay.setUpMyCSVVector(852, varFileLocation1);
		hour_ahead_price = ImportDisplay.setUpMyCSVVector(852, varFileLocation2);
		day_ahead_price = ImportDisplay.setUpMyCSVVector(852, varFileLocation3);
		pressure = ImportDisplay.setUpMyCSVVector(852, varFileLocation4);
		direct_solar = ImportDisplay.setUpMyCSVVector(852, varFileLocation5);
		indirect_solar = ImportDisplay.setUpMyCSVVector(852, varFileLocation6);
		humidity = ImportDisplay.setUpMyCSVVector(852, varFileLocation7);
		rainfall = ImportDisplay.setUpMyCSVVector(852, varFileLocation8);
		temperature = ImportDisplay.setUpMyCSVVector(852, varFileLocation9);
		wind = ImportDisplay.setUpMyCSVVector(852, varFileLocation10);
		load = ImportDisplay.setUpMyCSVVector(852, varFileLocation11);
		weekday = ImportDisplay.setUpMyCSVVector(852, varFileLocation12);
		time_index = ImportDisplay.setUpMyCSVVector(852, varFileLocation13);
		
		// import parameters
		alpha = ImportDisplay.setUpMyCSVVector(3, parFileLocation1);
		alpha_2 = ImportDisplay.setUpMyCSVVector(3, parFileLocation2);
		beta = ImportDisplay.setUpMyCSVArray(3, 36, parFileLocation3);
		beta_2 = ImportDisplay.setUpMyCSVArray(3, 36, parFileLocation4);
		ar = ImportDisplay.setUpMyCSVVector(5, parFileLocation5);
		base_load = ImportDisplay.setUpMyCSVArray(7, 56, parFileLocation6);
		external = ImportDisplay.setUpMyCSVVector(212, parFileLocation7);
		
		// convert day ahead to mean day-ahead relative price
		//MeanPriceMethod.meanPriceMethod(day_ahead_price, newOptimzation, rowNow,time_index);
		
		// calculate relative prices
		RelativePriceMethod.relativePriceMethod(real_time_price,
				hour_ahead_price, day_ahead_price, newOptimzation, rowNow,
				time_index);
		//ImportDisplay.printMyVector(day_ahead_price);
		
		// when is the first missing consumption value, from which we forecast?
		for (int l = 0; l < load.length; l++)
		{
			if (!Double.isNaN(load[l])) forecast_start_index = l + 1;
		}
		
		// start load
		double start_load = load[forecast_start_index-1];

		// calculate differenced variables
		real_time_price = Difference.differenceMethod(real_time_price);
		day_ahead_price = Difference.differenceMethod(day_ahead_price);
		pressure = Difference.differenceMethod(pressure);
		direct_solar = Difference.differenceMethod(direct_solar);
		indirect_solar = Difference.differenceMethod(indirect_solar);
		humidity = Difference.differenceMethod(humidity);
		rainfall = Difference.differenceMethod(rainfall);
		temperature = Difference.differenceMethod(temperature);
		wind = Difference.differenceMethod(wind);
		load = Difference.differenceMethod(load);
		
		// lagged variables
		day_ahead_price_lagged = LagMethod.lagMethod(forecast_start_index, lags[0], offsets[0], day_ahead_price);
		humidity_lagged = LagMethod.lagMethod(forecast_start_index, lags[1], offsets[1], humidity);
		temperature_lagged = LagMethod.lagMethod(forecast_start_index, lags[2], offsets[2], temperature);
		wind_lagged = LagMethod.lagMethod(forecast_start_index, lags[3], offsets[3], wind);
		direct_solar_lagged = LagMethod.lagMethod(forecast_start_index, lags[4], offsets[4], direct_solar);
		indirect_solar_lagged = LagMethod.lagMethod(forecast_start_index, lags[5], offsets[5], indirect_solar);
		rainfall_lagged = LagMethod.lagMethod(forecast_start_index, lags[6], offsets[6], rainfall);
		pressure_lagged = LagMethod.lagMethod(forecast_start_index, lags[7], offsets[7], pressure);
		load_lagged = LagMethod.lagMethod(forecast_start_index, lags[8], offsets[8], load);
		double[] load_lagged_subset = new double[lags[8]];
		for (int n = 0; n < lags[8]; n++){
			load_lagged_subset[n] = load_lagged[0][n];
		}
		real_time_price_lagged = LagMethod.lagMethod(forecast_start_index, lags[9], offsets[9], real_time_price);
		
		// base load
		base_load_var = BaseLoad.baseLoad(time_index,forecast_start_index);
		
		// interactions
		// temperature for interactions
		double[] temperature_lagged_6 = new double[temperature_lagged.length];
		for (int t = 0; t < temperature_lagged.length; t++){
			temperature_lagged_6[t] = temperature_lagged[t][5];
		}
		// temperature rtp interaction
		double[][] alpha_2_adjusted = new double[temperature_lagged_6.length][3];
		
		for (int h = 0; h < 3; h++){
			for (int t = 0; t < temperature_lagged_6.length; t++){
				alpha_2_adjusted[t][h] = alpha_2[h]*temperature_lagged_6[t];
			}
		}

		double[][] beta_2_adjusted_a = new double[temperature_lagged_6.length][36];
		double[][] beta_2_adjusted_b = new double[temperature_lagged_6.length][36];
		double[][] beta_2_adjusted_c = new double[temperature_lagged_6.length][36];
		
		for (int j = 0; j < 36; j++)
		{
			for (int t = 0; t < temperature_lagged_6.length; t++)
			{
				beta_2_adjusted_a[t][j] = beta_2[0][j]*temperature_lagged_6[t];
				beta_2_adjusted_b[t][j] = beta_2[1][j]*temperature_lagged_6[t];
				beta_2_adjusted_c[t][j] = beta_2[2][j]*temperature_lagged_6[t];
			}
		}
		// temperature day-ahead price interaction
		double[][] day_ahead_price_temp = new double[temperature_lagged_6.length][36];
		for (int j = 0; j < 36; j++)
		{
			for (int t = 0; t < temperature_lagged_6.length; t++)
			{
				day_ahead_price_temp[t][j] = day_ahead_price_lagged[t][j]*temperature_lagged_6[t];
			}
		}
		// temperature base-load interaction
		double[][] base_load_temp_var = new double[temperature_lagged_6.length][56];
		for (int j = 0; j < 56; j++)
		{
			for (int t = 0; t < temperature_lagged_6.length; t++)
			{
				base_load_temp_var[t][j] = base_load_var[t][j]*temperature_lagged_6[t];
			}
		}
		
		// modify weekday and time_index to accomodate start index
		double[] weekday_cut = new double[temperature_lagged_6.length];
		double[] time_index_cut = new double[temperature_lagged_6.length];
		for (int t = 0; t < weekday_cut.length; t++)
		{
			weekday_cut[t] = weekday[t + forecast_start_index];
			time_index_cut[t] = time_index[t + forecast_start_index];
		}
		
//		ForecastingLoop
int forecast_horizon = (12*24) + (12*12) + (rowNow-forecast_start_index-1);
		
		//actual forecasting loop
		double[] base_load_component = new double[forecast_horizon];
		double[] day_ahead_price_component = new double[forecast_horizon];
		double[] humidity_component = new double[forecast_horizon];
		double[] temperature_component = new double[forecast_horizon];
		double[] wind_component = new double[forecast_horizon];
		double[] direct_solar_component = new double[forecast_horizon];
		double[] indirect_solar_component = new double[forecast_horizon];
		double[] rainfall_component = new double[forecast_horizon];
		double[] pressure_component = new double[forecast_horizon];
		double[] temperature_dap_interaction_component = new double[forecast_horizon];
		double[] temperature_base_load_interaction_component = new double[forecast_horizon];
		double[] all_external_components = new double[forecast_horizon];
		double[] load_due_to_price = new double[forecast_horizon];
		double[] ar_component = new double[forecast_horizon];
		double[] consumption_forecast = new double[forecast_horizon];
		double[] alpha_forecast = new double[forecast_horizon];
		double[] boundries = new double[forecast_horizon];
		double[] reference_consumption_forecast = new double[forecast_horizon];
		double[] a = new double[forecast_horizon];
		double[] b = new double[forecast_horizon];
		double[] c = new double[forecast_horizon];
		double[] d = new double[forecast_horizon];
		
		// split external up into individual components
		double[] par_dap = Arrays.copyOfRange(external, 0, 36);
		double[] par_humidity = Arrays.copyOfRange(external, 36, 48);
		double[] par_temperature = Arrays.copyOfRange(external, 48, 60);
		double[] par_wind = Arrays.copyOfRange(external, 60, 72);
		double[] par_direct_solar = Arrays.copyOfRange(external, 72, 84);
		double[] par_indirect_solar = Arrays.copyOfRange(external, 84, 96);
		double[] par_rainfall = Arrays.copyOfRange(external, 96, 108);
		double[] par_pressure = Arrays.copyOfRange(external, 108, 120);
		double[] par_temp_dap = Arrays.copyOfRange(external, 120, 156);
		double[] par_temp_base = Arrays.copyOfRange(external, 156, 212);
		
		int h = -1;
		
		for (int t = 0; t < forecast_horizon; t++)
		{
			// base load consumption
			int day = (int)(weekday_cut[t]);
			for (int j = 0; j < 56; j++)
			{
				base_load_component[t] = base_load_component[t] + base_load[day][j]*base_load_var[t][j];
				temperature_base_load_interaction_component[t] = temperature_base_load_interaction_component[t] + base_load_temp_var[t][j]*par_temp_base[j];
			}
			
			// day-ahead price consumption
			for (int j = 0; j < 36; j++)
			{
				day_ahead_price_component[t] = day_ahead_price_component[t] + day_ahead_price_lagged[t][j]*par_dap[j];
				temperature_dap_interaction_component[t] = temperature_dap_interaction_component[t] + day_ahead_price_temp[t][j]*par_temp_dap[j];
			}
			
			// weather-based consumption
			for (int j = 0; j < 12; j++)
			{
				humidity_component[t] = humidity_component[t] + humidity_lagged[t][j]*par_humidity[j];
				temperature_component[t] = temperature_component[t] + temperature_lagged[t][j]*par_temperature[j];
				wind_component[t] = wind_component[t] + wind_lagged[t][j]*par_wind[j];
				direct_solar_component[t] = direct_solar_component[t] + direct_solar_lagged[t][j]*par_direct_solar[j];
				indirect_solar_component[t] = indirect_solar_component[t] + indirect_solar_lagged[t][j]*par_indirect_solar[j];
				rainfall_component[t] = rainfall_component[t] + rainfall_lagged[t][j]*par_rainfall[j];
				pressure_component[t] = pressure_component[t] + pressure_lagged[t][j]*par_pressure[j];
			}
			
			// external variables consumption
			all_external_components[t] = base_load_component[t] + 
					temperature_base_load_interaction_component[t] + 
					day_ahead_price_component[t] + 
					temperature_dap_interaction_component[t] + 
					humidity_component[t] + 
					temperature_component[t] + 
					wind_component[t] + 
					direct_solar_component[t] + 
					indirect_solar_component[t] + 
					rainfall_component[t] +
					pressure_component[t];
			
			// real-time price consumption
			if (time_index_cut[t] >= 1 && time_index_cut[t]  < 97)
				{
					h = 0;
					c[t] = -alpha_2_adjusted[t][h]/2 + (alpha_2_adjusted[t][h]/(1 + Math.exp(-real_time_price_lagged[t][0]*beta_2_adjusted_a[t][0])));
					for (int j = 1; j < 36; j++)
					{
						d[t] =  d[t] + real_time_price_lagged[t][j]*beta_2_adjusted_a[t][j];
					}
					alpha_forecast[t] = 0.25*(alpha[h]*beta[h][0] + alpha_2_adjusted[t][h]*beta_2_adjusted_a[t][0])/scalingFactor;
				}
			if (time_index_cut[t] >= 97 & time_index_cut[t] < 193)
				{
					h = 1;
					c[t] = -alpha_2_adjusted[t][h]/2 + (alpha_2_adjusted[t][h]/(1 + Math.exp(-real_time_price_lagged[t][0]*beta_2_adjusted_b[t][0])));
					for (int j = 1; j < 36; j++)
					{
						d[t] =  d[t] + real_time_price_lagged[t][j]*beta_2_adjusted_b[t][j];
					}
					alpha_forecast[t] = 0.25*(alpha[h]*beta[h][0] + alpha_2_adjusted[t][h]*beta_2_adjusted_b[t][0])/scalingFactor;
				}
			if (time_index_cut[t] >= 193 & time_index_cut[t] < 289)
				{
					h = 2;
					c[t] = -alpha_2_adjusted[t][h]/2 + (alpha_2_adjusted[t][h]/(1 + Math.exp(-real_time_price_lagged[t][0]*beta_2_adjusted_c[t][0])));
					for (int j = 1; j < 36; j++)
					{
						d[t] =  d[t] + real_time_price_lagged[t][j]*beta_2_adjusted_c[t][j];
					}
					alpha_forecast[t] = 0.25*(alpha[h]*beta[h][0] + alpha_2_adjusted[t][h]*beta_2_adjusted_c[t][0])/scalingFactor;
				}
			
			a[t] = -alpha[h]/2 + (alpha[h]/(1 + Math.exp(-real_time_price_lagged[t][0]*beta[h][0])));
//			if (t == 0) System.out.print(beta[h][0]);
			
			for (int j = 1; j < 36; j++)
			{
				b[t] =  b[t] + real_time_price_lagged[t][j]*beta[h][j];
			}  
					  
			load_due_to_price[t] = a[t] + b[t] + c[t] + d[t];
			
			// auto-regressive consumption
			for (int j = 0; j < 5; j++)
			{
				ar_component[t] = ar_component[t] + ar[j]*load_lagged_subset[j];
			}
			
			// total forecast
			consumption_forecast[t] = all_external_components[t] + load_due_to_price[t] + ar_component[t];
			
			boundries[t] = (Math.abs(alpha[h]) + Math.abs(alpha_2_adjusted[t][h]))/2;
			
			double[] load_lagged_subset_temp = Arrays.copyOfRange(load_lagged_subset, 0, 4); 

			for (int n = 1; n < 5; n++)
			{
				load_lagged_subset[n] = load_lagged_subset_temp[n-1];
			}
			load_lagged_subset[0] = consumption_forecast[t];

			
			if (t == 0)
			{
				reference_consumption_forecast[t] = consumption_forecast[t] + start_load;
			} else {
				reference_consumption_forecast[t] = consumption_forecast[t] + reference_consumption_forecast[t-1];
			}
		}
		ImportDisplay.printMyVector(boundries);
		
	}

	// create variable names etc.
	// parameters (imported)
	static double[] alpha;
	static double[] alpha_2;
	static double[][] beta;
	static double[][] beta_2;
	static double[] ar;
	static double[][] base_load;
	static double[] external;
	static String parFileLocation1 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\alpha.csv";
	static String parFileLocation2 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\alpha_2.csv";
	static String parFileLocation3 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\beta.csv";
	static String parFileLocation4 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\beta_2.csv";
	static String parFileLocation5 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\ar.csv";
	static String parFileLocation6 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\base_load.csv";
	static String parFileLocation7 = "c:\\Users\\Emil\\Desktop\\java_program\\vf_march_09\\external.csv";

	// variables (imported)
	static double[] real_time_price;
	static double[] hour_ahead_price;
	static double[] day_ahead_price;
	static double[] pressure;
	static double[] direct_solar;
	static double[] indirect_solar;
	static double[] humidity;
	static double[] rainfall;
	static double[] temperature;
	static double[] wind;
	static double[] load;
	static double[] weekday;
	static double[] time_index;
	static String varFileLocation1 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\price_real_time.csv";
	static String varFileLocation2 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\price_hour_ahead.csv";
	static String varFileLocation3 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\price_day_ahead.csv";
	static String varFileLocation4 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_atmospheric_pressure.csv";
	static String varFileLocation5 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_direct_solar_irradiance.csv";
	static String varFileLocation6 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_indirect_solar_irradiance.csv";
	static String varFileLocation7 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_humidity.csv";
	static String varFileLocation8 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_rainfall.csv";
	static String varFileLocation9 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_temperature.csv";
	static String varFileLocation10 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\dmi_wind_speed.csv";
	static String varFileLocation11 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\load.csv";
	static String varFileLocation12 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\weekday_index.csv";
	static String varFileLocation13 = "c:\\Users\\Emil\\Desktop\\java_program\\variables\\time_index.csv";

	// variables
	static double[] relative_prices;
	static double[] newOptimzation = { 277, 171 }; // when to do a new optimization
	static int rowNow = 289; // there are 288 historical values for all columns of variables
	static int[] lags = {36,12,12,12,12,12,12,12,5,36};  // lags
	static int[] offsets = {24,6,6,6,6,6,6,0,-1,0};  // offsets
	static double scalingFactor = 0.025; // for scaling alpha to the correct market size
	
	static int forecast_start_index;
	static double[][] day_ahead_price_lagged;
	static double[][] humidity_lagged;
	static double[][] temperature_lagged;
	static double[][] wind_lagged;
	static double[][] direct_solar_lagged;
	static double[][] indirect_solar_lagged;
	static double[][] rainfall_lagged;
	static double[][] pressure_lagged;
	static double[][] load_lagged;
	static double[][] real_time_price_lagged;
	
	static int observations_interested;
	
	static double[][] base_load_var;
}