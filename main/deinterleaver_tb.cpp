#include "header.h"

int main() {
	inStream inDataFIFO;
	cnStream cnDataFIFO;
	outStream outDataFIFO;

	datau216b PHY_MAC_input;

	data_axi inData;
	data_axi outData;

	// C,Cr,E1,E2,Qm
	int par[19][10] = {
			{1,1,168,168,2},
			{1,1,168,168,2},
			{1,1,24,24,2},
			{1,1,24,24,2},
			{7,1,12884,12886,2},
			{7,1,12884,12886,2},
			{16,4,11272,11276,4},
			{16,4,11272,11276,4},
			{29,24,9330,9336,6},
			{29,24,9330,9336,6},
			{2,2,11400,11400,4},
			{1,1,21252,21252,2},
			{3,3,14628,14628,2},
			{7,2,14428,14432,4},
			{9,6,17358,17364,6},
			{21,18,10326,10332,6},
			{13,10,8958,8964,6},
			{1,1,1056,1056,2},
			{1,1,1080,1080,2}
	};


	const int tests = 19;
	for(int test=19; test <= tests; test++) {
		const int TEST_CASES = 20;
		int count = TEST_CASES;

		int C = par[test-1][0];
//		int C=1;
		int Cr = par[test-1][1];
		int E1 = par[test-1][2];
		int E2 = par[test-1][3];
		int Qm= par[test-1][4];


		PHY_MAC_input.range(34,27) = C;
		PHY_MAC_input.range(121,114) = Cr;
		PHY_MAC_input.range(138,123) = E1;
		PHY_MAC_input.range(154,139) = E2;
		PHY_MAC_input.range(26,23)=	Qm;

		string inFileName = "test_case_"+to_string(test)+"_in";

		ifstream inputFile(inFileName);


		datau128b dataTemp;
		string s;

		// taking input from file and appending it to inDataFIFO stream
		while(count > 0) {
			for(int codeblock=0; codeblock<C; codeblock++) {
				int E;
				if(codeblock<=Cr-1) E=E1;
				else E=E2;

				int burst=(E+15)/16;
				for(int cb=0;cb<burst;cb++){

					char buffer_data[32],trailing[1];

					inputFile.read(buffer_data,32);

					s = "0x";
					for(int j=0; j<32; j++) {
						s += buffer_data[j];
					}
//					cout<<s<<endl;
					istringstream iss(s);
					iss >> hex >> dataTemp;
					inData.data = dataTemp.read();
					inputFile.read(trailing, 1);
					inDataFIFO.write(inData);
				}
				}
			count--;
		}

		inputFile.close();
//		count=TEST_CASES;
		while(!inDataFIFO.empty()){
			cnDataFIFO.write(PHY_MAC_input);
			DeInterleaver(inDataFIFO,cnDataFIFO,outDataFIFO);
//			cout<<count<<endl;
//			count--;
		}
//		cout<<"HEllo"<<endl;
		ofstream outputFile("output.txt");
		count = TEST_CASES;
		datau128b outTemp;
		datau32b readTemp;

		// writing the data to output file
		while(count) {
			for(int j=0; j<C; j++) {
				int E;
				if(j<=Cr-1) E=E1;
				else E=E2;
				int burst=(E+15)/16;
				for(int i=0;i<burst;i++){
					outDataFIFO >> outData;
					outTemp = outData.data.read();
					string s = "";
					stringstream ss;
					for(int j=4; j>0; j--) {
						int l = 32*j-1, r = 32*(j-1);
						readTemp = outTemp.read().range(l, r);
						unsigned int u = readTemp.read();
						ss << setfill('0') << setw(8) << hex << uppercase << u;
					}

					s += ss.str();
//					cout<<s<<endl;
					outputFile << s;

					outputFile << endl;
				}
			}
			count--;
		}

		outputFile.close();
		while(!cnDataFIFO.empty()) {
			cnDataFIFO.read();
		}

		cout << "\nComparing with MATLAB results....\n";
		string outFileName = "test_case_" + to_string(test) + "_out";
		cout << outFileName << "\n";
		string cmd = "diff -w output.txt " + outFileName;
		cout<<"Testing case "<<test<<endl;
		if (system(cmd.c_str())){
			printf("Test %s failed !!!\nOutput data does not match", test);
			return 1;
		}else {
			cout<<"Test "<<test<<" passed !\n";
		}
	}
	return 0;
}
