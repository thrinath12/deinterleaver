`timescale 1ns / 1ps




module testbench();

    reg [127:0] inData_tdata; 
    reg inData_tvalid;
    wire inData_tready;
    reg inData_tlast;


    reg [215:0]cnData_tdata ;                    //Interleaver
    reg cnData_tvalid;
    wire cnData_tready;


    wire outData_tvalid;
    reg outData_tready;
    wire [127:0]outData_tdata;
    wire outData_tlast;

    reg clk =0;
    reg rst =0;

    always #5 clk<=~clk;

    initial begin
    rst =0;
    #10000 $finish;
    end

    integer i,j;
    logic [31:0] in_count;
    reg [127:0] err_tdata_out;
    integer err_count_tdata_out;





    reg [127:0] in_data  [0:8000];
    reg [127:0] out_data [0:8000];
    reg [215:0] config_data[0:0] ;



    Deinterleaver deinterleaver(

        .ap_rst_n(rst),
        .ap_clk(clk),

        .cnData_tdata(cnData_tdata),
        .cnData_tready(cnData_tready),
        .cnData_tvalid(cnData_tvalid),

        .inData_tdata(inData_tdata),
        .inData_tvalid(inData_tvalid),
        .inData_tready(inData_tready),
        .inData_tlast(inData_tlast),


        .outData_tdata(outData_tdata),
        .outData_tlast(outData_tlast),
        .outData_tvalid(outData_tvalid),
        .outData_tready(outData_tready)
    );


    

initial begin


    $readmemh("/home/thrinath/Documents/deinterleaver/DeInterleaver_test_vectors_IDE/test_case_1_in",in_data);
    $readmemh("/home/thrinath/Documents/deinterleaver/DeInterleaver_test_vectors_IDE/test_case_1_out",out_data);
    $readmemh("/home/thrinath/Documents/deinterleaver/PUSCH_RX_Config_test_vectors_R4/test_case_1_config_R4",config_data);
    
    inData_tdata = in_data[1];
    in_count = in_data[0][31:0];
    inData_tvalid = 1'b1;
    
    
    cnData_tdata = config_data[0];    //Interleaver
    cnData_tvalid = 1;  
    outData_tready = 1'b1;

    i=1; j=1;  
      
    err_count_tdata_out=0;
    err_tdata_out = 0;

    if(in_count==1) inData_tlast =1;
    else inData_tlast =0;
          

end

always@(posedge clk) begin      
    
    rst <=1;//Input data
    if (inData_tready==1'b1 && inData_tvalid==1'b1) begin
        #5
        i=(i+1);    
        if(i==in_count) inData_tlast =1;
        else inData_tlast =0;          
        inData_tdata=in_data[i];
    end
end
    

always@(posedge clk) begin  
    if (outData_tready==1'b1 && outData_tvalid==1'b1) begin                     
        err_tdata_out = out_data[j]^outData_tdata;   
        j=j+1;                                                                       
        if (err_tdata_out>0) err_count_tdata_out = err_count_tdata_out+1;
    end
end
endmodule
