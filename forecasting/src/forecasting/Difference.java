package forecasting;

public class Difference {

	static double[] differenceMethod(double[] myArray) {
		
		double[] differenced_ts = myArray.clone();
		
		for (int n = 0; n < myArray.length; n++)
		{
			if (n == 0){
				differenced_ts[n] = 0;
			} else {
				differenced_ts[n] = myArray[n] - myArray[n-1];
			}
		}
		
		return differenced_ts;
	}
}
