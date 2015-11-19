package forecasting;

import java.io.BufferedReader;
import java.io.FileReader;
import java.util.Scanner;

public class ImportDisplay {
	// function to import csv files
	static double[][] setUpMyCSVArray(int x_dim, int y_dim, String xfileLocation) {
		double[][] locArray = new double[x_dim][y_dim];
		Scanner scanIn = null;
		int Rowc = 0;
		String InputLine = "";
		try {
			// setup a scanner
			scanIn = new Scanner(new BufferedReader(new FileReader(
					xfileLocation)));

			// while ((IntputLine = scanIn.nextLine()) != null)
			while (scanIn.hasNextLine()) {
				// Read line in from file
				InputLine = scanIn.nextLine();
				// split the Intputline into an array at the commas
				String[] InArray = InputLine.split(",");

				// copy the content of the inArray to the myArray
				for (int x = 0; x < InArray.length; x++) {
					locArray[Rowc][x] = Double.parseDouble(InArray[x]);
				}
				// Increment the row in the array
				Rowc++;
			}
		} catch (Exception e) {
			System.out.println(e);
		}
		return locArray;
	}

	// function to import csv files
	static double[] setUpMyCSVVector(int x_dim, String xfileLocation) {
		double[] locArray = new double[x_dim];
		Scanner scanIn = null;
		int Rowc = 0;
		String InputLine = "";
		try {
			// setup a scanner
			scanIn = new Scanner(new BufferedReader(new FileReader(
					xfileLocation)));

			// while ((IntputLine = scanIn.nextLine()) != null)
			while (scanIn.hasNextLine()) {
				// Read line in from file
				InputLine = scanIn.nextLine();

				// copy the content of the inArray to the myArray
				locArray[Rowc] = Double.parseDouble(InputLine);

				// Increment the row in the array
				Rowc++;
			}
		} catch (Exception e) {
			System.out.println(e);
		}
		return locArray;
	}

	// function to print output of an array
	static void printMyArray(int x_dim, int y_dim, double[][] myArray) {
		// print the array
		for (int Rowc = 0; Rowc < x_dim; Rowc++) {
			for (int Colc = 0; Colc < y_dim; Colc++) {
				System.out.print(myArray[Rowc][Colc] + " ");
			}
			System.out.println();
		}
		return;
	}

	// function to print output of a vector
	static void printMyVector(double[] myArray) {
		int x_dim = myArray.length;
		// print the array
		for (int Rowc = 0; Rowc < x_dim; Rowc++) {
			System.out.print(myArray[Rowc]);
			System.out.println();
		}
		return;
	}
	
	// function to print output of a vector
	static void printMyIntvec(int[] myArray) {
		int x_dim = myArray.length;
		// print the array
		for (int Rowc = 0; Rowc < x_dim; Rowc++) {
			System.out.print(myArray[Rowc]);
			System.out.println();
		}
		return;
	}

	// build an array sequance (integers)
	static int[] makeSequence(int begin, int end) {
		if (end < begin)
			return null;

		int[] ret = new int[++end - begin];
		for (int i = 0; begin < end;)
			ret[i++] = begin++;
		return ret;
	}
}
