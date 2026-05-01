#include "ap_int.h"
#include "hls_stream.h"
#include "ap_axi_sdata.h"
#include <cstdint>
#include <type_traits>



typedef hls::axis<ap_uint<128>,0,0,0,AXIS_ENABLE_LAST> in_axi_type;
typedef hls::stream<in_axi_type> in_stream_type;

typedef hls::axis<ap_uint<132>,0,0,0,AXIS_ENABLE_LAST> bridge_axi_type;
typedef hls::stream<bridge_axi_type> bridge_stream_type;


typedef hls::axis<ap_uint<216>,0,0,0,AXIS_DISABLE_ALL> config_axi_type;
typedef hls::stream<config_axi_type> config_stream_type;




void De_interleaver(in_stream_type &inStream,config_stream_type &cnStream,bridge_stream_type &outStream){
    #pragma HLS INTERFACE axis port=inStream
    #pragma HLS INTERFACE axis port=cnStream
    #pragma HLS INTERFACE axis port=outStream
    #pragma HLS INTERFACE s_axilite port=return bundle=CTRL

    config_axi_type cnTemp = cnStream.read();

    ap_uint<16> E1 = cnTemp.data.range(138,123);
    ap_uint<16> E2 = cnTemp.data.range(154,139);
    ap_uint<6> C = cnTemp.data.range(34,27);
    ap_uint<6> Cr = cnTemp.data.range(121,114);
    ap_uint<4> Qm = cnTemp.data.range(26,23);

    
 

    ap_uint<16> E=E1;
    ap_uint<6> C_Counter=0;

    ap_uint<128> Ram[5][512];
    #pragma HLS ARRAY_PARTITION variable=Ram complete dim=1
    #pragma HLS BIND_STORAGE variable=Ram type=RAM_T2P impl=BRAM


    in_axi_type in_axi;
    ap_uint<128> in_data;
    ap_uint<8> input_bytes[16];
    #pragma HLS ARRAY_PARTITION variable=input_bytes complete dim=1

    int Ram_number=0;
    ap_uint<10> Address_global;
    ap_uint<2> pc=0;
    ap_uint<2> sc=0;

    ap_uint<64> temp_Q2;
    ap_uint<1> write_over;
    ap_uint<1> read_over;

    ap_uint<9> Address_Q4[2];
    #pragma HLS ARRAY_PARTITION variable=Address_Q4 complete dim=1

    Address_global =0;
    

    Address_Q4[0] = 107;
    Address_Q4[1] = 214;

    ap_uint<128> row0;
    
    bridge_axi_type out_axi;
    ap_uint<11> output_count;

    ap_uint<11> wfm_counter;
    ap_uint<9> wfm_address;
    ap_uint<3> wfm_row_counter;


    ap_uint<15> llr_per_row ;

    if(Qm ==4) llr_per_row  = E.range(15,2);
    else if(Qm==2) llr_per_row = E.range(15,1);
    else llr_per_row = E/6;

    ap_uint<4> llr_last_word;
    if(llr_per_row.range(3,0) ==0) llr_last_word =15;
    else llr_last_word = llr_per_row.range(3,0)-1;
    






    for(int i=0;i<C;i++){  
        #pragma HLS LOOP_TRIPCOUNT min=1 max=40
        read_over =0;      
        write_over=0;       
            
        while(read_over!=1){
            #pragma HLS PIPELINE II=1
            in_axi = inStream.read();
            in_data = in_axi.data;

            for(int k=0;k<16;k++) {
                #pragma HLS UNROLL
                input_bytes[k] = in_data.range(127-16*k,112-16*k);
            }

            if(Qm ==6){
                if(pc ==0){
                                     row0.range(127-64*sc[0],104-64*sc[0])                    =(input_bytes[0],input_bytes[6],input_bytes[12]);
                    Ram[0][Address_global.range(8,0)].range(127-64*sc[0],104-64*sc[0]) = (input_bytes[1],input_bytes[7],input_bytes[13]);
                    Ram[1][Address_global.range(8,0)].range(127-64*sc[0],104-64*sc[0]) = (input_bytes[2],input_bytes[8],input_bytes[14]);
                    Ram[2][Address_global.range(8,0)].range(127-64*sc[0],104-64*sc[0]) = (input_bytes[3],input_bytes[9],input_bytes[15]);
                    Ram[3][Address_global.range(8,0)].range(127-64*sc[0],112-64*sc[0]) = (input_bytes[4],input_bytes[10]);
                    Ram[4][Address_global.range(8,0)].range(127-64*sc[0],112-64*sc[0]) = (input_bytes[5],input_bytes[11]);               
                }

                else if(pc ==1){
                                                        row0.range(103-64*sc[0],80-64*sc[0]) =                 (input_bytes[2],input_bytes[8],input_bytes[14]);
                    Ram[0][Address_global.range(8,0)].range(103-64*sc[0],80-64*sc[0]) =                 (input_bytes[3],input_bytes[9],input_bytes[15]);
                    Ram[1][Address_global.range(8,0)].range(103-64*sc[0],88-64*sc[0]) =                 (input_bytes[4],input_bytes[10]);
                    Ram[2][Address_global.range(8,0)].range(103-64*sc[0],88-64*sc[0]) =                 (input_bytes[5],input_bytes[11]);
                    Ram[3][Address_global.range(8,0)].range(111-64*sc[0],88-64*sc[0]) = (input_bytes[0],input_bytes[6],input_bytes[12]);
                    Ram[4][Address_global.range(8,0)].range(111-64*sc[0],88-64*sc[0]) = (input_bytes[1],input_bytes[7],input_bytes[13]);   
                }

                else{
                                                        row0.range(79-64*sc[0],64-64*sc[0]) =                 (input_bytes[4],input_bytes[10]);
                    Ram[0][Address_global.range(8,0)].range(79-64*sc[0],64-64*sc[0]) =                 (input_bytes[5],input_bytes[11]);
                    Ram[1][Address_global.range(8,0)].range(87-64*sc[0],64-64*sc[0]) = (input_bytes[0],input_bytes[6],input_bytes[12]);
                    Ram[2][Address_global.range(8,0)].range(87-64*sc[0],64-64*sc[0]) = (input_bytes[1],input_bytes[7],input_bytes[13]);
                    Ram[3][Address_global.range(8,0)].range(87-64*sc[0],64-64*sc[0]) = (input_bytes[2],input_bytes[8],input_bytes[14]);
                    Ram[4][Address_global.range(8,0)].range(87-64*sc[0],64-64*sc[0]) = (input_bytes[3],input_bytes[9],input_bytes[15]);            
                }

                                
            

                if(in_axi.last==1) {
                    out_axi.data.range(131,4) = row0;
                    out_axi.last =0;
                    out_axi.data.range(3,0) = llr_last_word;
                    outStream.write(out_axi);                     
                }       
                else if(pc==2){
                    if(sc[0]==1) {
                        out_axi.data.range(131,4) = row0;
                        out_axi.last =0;
                        out_axi.data.range(3,0) = 0;
                        outStream.write(out_axi);                    
                        output_count = output_count +1;
                        Address_global = Address_global+1;
                    }
                    pc=0;
                    sc[0] = !sc[0];
                }
                else pc = pc+1; 


            }

            else if(Qm ==2){
                row0.range(127-64*sc[0],64-64*sc[0]) = (input_bytes[0],input_bytes[2],input_bytes[4],input_bytes[6],input_bytes[8],input_bytes[10],input_bytes[12],input_bytes[14]);
                temp_Q2 = (input_bytes[1],input_bytes[3],input_bytes[5],input_bytes[7],input_bytes[9],input_bytes[11],input_bytes[13],input_bytes[15]);
                if(Ram_number==0)      Ram[0][Address_global.range(8,0)].range(127-64*sc[0],64-64*sc[0]) = temp_Q2;  
                else if(Ram_number==1) Ram[1][Address_global.range(8,0)].range(127-64*sc[0],64-64*sc[0]) = temp_Q2;
                else                   Ram[2][Address_global.range(8,0)].range(127-64*sc[0],64-64*sc[0]) = temp_Q2; 
                
                if(in_axi.last==1) {
                    out_axi.data.range(131,4) = row0;
                    out_axi.last =0;
                    out_axi.data.range(3,0) = llr_last_word;
                    outStream.write(out_axi); 
                }   
                else if(sc[0]==1)  {   
                    if(Address_global.range(8,0)==511) Ram_number=Ram_number+1;
                    out_axi.data.range(131,4) = row0;
                    out_axi.last =0;
                    out_axi.data.range(3,0)= 0;
                    outStream.write(out_axi);  
                    output_count = output_count +1;                  
                    Address_global = Address_global+1;
                }
                sc[0] = !sc[0];
            }

            else {
                if(pc!=3) Ram[0][Address_global.range(8,0)].range(127-32*sc,96-32*sc)= (input_bytes[1],input_bytes[5],input_bytes[9],input_bytes[13]);
                if(pc!=0) Ram[3][Address_Q4[1]].range(127-32*sc,96-32*sc) = (input_bytes[3],input_bytes[7],input_bytes[11],input_bytes[15]);

                if(pc==3){
                    Ram[1][Address_global.range(8,0)].range(127-32*sc,96-32*sc) = (input_bytes[1],input_bytes[5],input_bytes[9],input_bytes[13]);
                    Ram[2][Address_Q4[0]].range(127-32*sc,96-32*sc) = (input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14]);
                }
                else if(pc==2){
                    Ram[2][Address_Q4[0]].range(127-32*sc,96-32*sc) = (input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14]);
                }
                else if(pc==1){
                    Ram[1][Address_Q4[0]].range(127-32*sc,96-32*sc) = (input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14]);
                }
                else {
                    Ram[1][Address_Q4[0]].range(127-32*sc,96-32*sc) = (input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14]);
                    Ram[2][Address_Q4[1]].range(127-32*sc,96-32*sc) = (input_bytes[3],input_bytes[7],input_bytes[11],input_bytes[15]);                
                }

                row0.range(127-32*sc,96-32*sc) = (input_bytes[0],input_bytes[4],input_bytes[8],input_bytes[12]);               
            

                if(in_axi.last==1) {
                    out_axi.data.range(131,4) = row0;
                    out_axi.last =0;
                    out_axi.data.range(3,0) = llr_last_word;
                    outStream.write(out_axi); 
                } 
                else if(sc==3) {
                    if(Address_global==297)Address_Q4[1] = 0;  
                    else Address_Q4[1] = Address_Q4[1]+1 ;

                    if(Address_global==404) Address_Q4[0] =0;
                    else Address_Q4[0] =Address_Q4[0]+1;

                    if(Address_global==511 | Address_global ==404 | Address_global ==297 ) pc = pc+1;
                    out_axi.data.range(131,4) = row0;
                    out_axi.last =0;
                    out_axi.data.range(3,0) = 0;
                    outStream.write(out_axi);
                    output_count = output_count +1;
                    Address_global = Address_global +1;
                }
                                        
                sc=sc+1;
            }


            if(in_axi.last==1) read_over=1;
        }


        wfm_address=0;
        Ram_number =0;
        wfm_row_counter=0;

        while(write_over!=1){
            #pragma HLS PIPELINE II=1
            row0 = Ram[Ram_number][wfm_address];
            out_axi.data.range(131,4)  = row0;
            out_axi.data.range(3,0) =0;
            outStream.write(out_axi);

            if(Qm==6){

                if(wfm_counter ==output_count) 
                {   
                    if(wfm_row_counter == 4) {out_axi.last=1 ;write_over =1;}
                    wfm_address =0; 
                    Ram_number=Ram_number+1;
                    wfm_row_counter = wfm_row_counter+1;
                    wfm_counter = 0;
                }
                else wfm_address = wfm_address+1;
            
            }
            else if(Qm==2){
                if(wfm_counter==output_count) {out_axi.last=1 ;  write_over=1;}           
                else if(wfm_address==511) {wfm_address=0;Ram_number=Ram_number+1;}
                else wfm_address=wfm_address+1;
            }
            else {
                if(wfm_counter==output_count){
                    
                    if(wfm_row_counter==0) {wfm_address= 107; Ram_number=1; wfm_row_counter=1;}
                    else if(wfm_row_counter==1) {wfm_address=214; Ram_number=2;wfm_row_counter =2;}
                    else if(wfm_row_counter==2) {out_axi.last =1; write_over=1;}
                    else wfm_address=wfm_address+1;
                    wfm_counter=0;
                } 
                else if(wfm_address==511){ wfm_address=0; Ram_number = Ram_number+1;}
                else wfm_address = wfm_address+1;
                
            }

        }                
            if(C_Counter ==Cr-1)  E = E2;       
            C_Counter =C_Counter+1;
           



    }

}