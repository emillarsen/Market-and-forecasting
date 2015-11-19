package forecasting;

public class LagMethod {

	static double[][] lagMethod(int start_index, int lag, int offset, double[] variable) {

		int observations_interested = variable.length - start_index;
		
		Forecast.observations_interested = observations_interested;
		
		double[][] lagged_variable = new double[observations_interested][lag];
		
		for (int t = 0; t < observations_interested; t++)
		{
			for (int l = 0; l < lag; l++)
			{
				if (start_index + t - l + offset > variable.length-1){
					lagged_variable[t][l] = Double.NaN;
				} else {
					lagged_variable[t][l] = variable[start_index + t - l + offset];
				}
			}
		}

		return lagged_variable;
	}
}
