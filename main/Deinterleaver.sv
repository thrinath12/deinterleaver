module Deinterleaver_1(

    input logic ap_clk,
    input logic ap_rst_n,

    input logic [215:0] cnData_tdata,
    input logic  cnData_tvalid,
    output logic cnData_tready,

    input logic [127:0] inData_tdata,
    input logic  inData_tvalid,
    output logic inData_tready,
    input logic  inData_tlast,

    output logic [127:0] outData_tdata,
    input logic  outData_tready,
    output logic outData_tvalid,
    output logic  outData_tlast,
    output logic [3:0] outData_tkeep
);

////////////////////////////////////////////// CONFIG AXI //////////////////////////////////////////////////////////////

    logic [15:0] E1,E2;
    logic [5:0] C,Cr;
    logic [2:0] Qm;

    logic [5:0] CB_Counter;
    logic [15:0] temp;
    logic config_over;

    assign config_over = (state==write_over) && (CB_Counter==C);
    wire [15:0] E = (CB_Counter<=Cr)?E1:E2;

    always_ff@(posedge ap_clk)begin
        if(!ap_rst_n)CB_Counter <=1;
        else if(state==write_over)begin
            if(CB_Counter ==C) CB_Counter <= 1;
            else CB_Counter <= CB_Counter +1;
        end        
    end

     

    logic config_axi_needed;
    logic config_valid_reg;
    logic config_valid;



    always@(posedge ap_clk)begin
        if(!ap_rst_n | config_over)config_axi_needed <=1;
        else config_axi_needed <=0;
    end

    assign cnData_tready = ap_rst_n && config_axi_needed;

    always@(posedge ap_clk) begin
        if(cnData_tready && cnData_tvalid) begin
            E1 <= cnData_tdata[138:123];
            E2 <= cnData_tdata[154:139];
            C  <= cnData_tdata[34:27];
            Cr <= cnData_tdata[121:114];
            Qm <= cnData_tdata[25:23];
        end

        if(!ap_rst_n | config_over) config_valid_reg <=0;
        else if(cnData_tready && cnData_tvalid) config_valid_reg <=1;

        config_valid <= config_valid_reg;    
    end



    logic [14:0] llrs_per_row;
    
    wire  [14:0] outputs_per_row_temp = llrs_per_row +15;
    wire [10:0] outputs_per_row = outputs_per_row_temp[14:4]; 

    wire [12:0] llrs_per_row_Q6 = E/6;
    wire [13:0] llrs_per_row_Q4 = E[15:2];
    wire [14:0] llrs_per_row_Q2 = E[15:1];
    

    always@(posedge ap_clk)begin
        if(Qm==6) llrs_per_row <= {2'b0,llrs_per_row_Q6};
        else if(Qm==4) llrs_per_row <= {1'b0,llrs_per_row_Q4};
        else llrs_per_row <= llrs_per_row_Q2; 
    end

    logic [3:0] tkeep_wire ;

    always_comb begin
        if(llrs_per_row[3:0]==0) tkeep_wire = 15;
        else tkeep_wire = llrs_per_row[3:0] -1;
    end

//////////////////////////////////////////////// INPUT AXI ////////////////////////////////////////////////////////////

    logic [127:0] inData_tdata_reg;
    logic  inData_tvalid_reg;
    logic  inData_tlast_reg;


    wire [1:0] reading=0;
    wire [1:0] read_over=1;
    wire [1:0] writing=2;
    wire [1:0] write_over=3;

    logic [1:0] state;

    always@(posedge ap_clk)begin
        if(!ap_rst_n) state <= reading;
        else if(state ==reading)begin
            if(inData_tlast && inData_tready  && inData_tvalid) state <= read_over;
        end
        else if(state==read_over) begin
            state <= writing;
        end 
        else if(state==writing) begin
            if(outData_tlast && outData_tvalid && outData_tvalid) state <= write_over;
        end    
        else if(state ==write_over)begin
            state <= reading;
        end  
    end


    assign inData_tready = ap_rst_n && (state==reading) && config_valid;  /////////// OUTPUT BLOCK NOT READY CASE.

    always@(posedge ap_clk)begin
        if(!ap_rst_n)begin
            inData_tvalid_reg <= 0;
            inData_tlast_reg  <= 0;
        end
        else if(inData_tready && inData_tvalid)begin
            inData_tdata_reg <= inData_tdata;
            inData_tvalid_reg <=1;
            inData_tlast_reg <= inData_tlast;
        end
        else begin
            inData_tvalid_reg <=0;
        end
    end

    
///////////////////////////////////////////////  RAM COMPONENTS /////////////////////////////////////////////////////////

    logic [9:0] Addresses[5][2][2];
    logic [3:0] Byte_Enables[5][2][2];
    logic EN[5][2][2];
    logic           We[5][2][2];
    logic   [31:0]  Din[5][2][2];
    logic [31:0]    Dout[5][2][2];

///////////////////// ROW 0 /////////////////////////////    

    BRAM bram_0_0(
    .clka(ap_clk),.ena(EN[0][0][0]),.wea(We[0][0][0]),.addra(Addresses[0][0][0]),.Ben_a(Byte_Enables[0][0][0]),.dia(Din[0][0][0]),.doa(Dout[0][0][0]),
    .clkb(ap_clk),.enb(EN[0][0][1]),.web(We[0][0][1]),.addrb(Addresses[0][0][1]),.Ben_b(Byte_Enables[0][0][1]),.dib(Din[0][0][1]),.dob(Dout[0][0][1])
    );
    BRAM bram_0_1(
    .clka(ap_clk),.ena(EN[0][1][0]),.wea(We[0][1][0]),.addra(Addresses[0][1][0]),.Ben_a(Byte_Enables[0][1][0]),.dia(Din[0][1][0]),.doa(Dout[0][1][0]),
    .clkb(ap_clk),.enb(EN[0][1][1]),.web(We[0][1][1]),.addrb(Addresses[0][1][1]),.Ben_b(Byte_Enables[0][1][1]),.dib(Din[0][1][1]),.dob(Dout[0][1][1])
    );
   

///////////////////// ROW 1 /////////////////////////////    

     BRAM bram_1_0(
    .clka(ap_clk),.ena(EN[1][0][0]),.wea(We[1][0][0]),.addra(Addresses[1][0][0]),.Ben_a(Byte_Enables[1][0][0]),.dia(Din[1][0][0]),.doa(Dout[1][0][0]),
    .clkb(ap_clk),.enb(EN[1][0][1]),.web(We[1][0][1]),.addrb(Addresses[1][0][1]),.Ben_b(Byte_Enables[1][0][1]),.dib(Din[1][0][1]),.dob(Dout[1][0][1])
    );
    BRAM bram_1_1(
    .clka(ap_clk),.ena(EN[1][1][0]),.wea(We[1][1][0]),.addra(Addresses[1][1][0]),.Ben_a(Byte_Enables[1][1][0]),.dia(Din[1][1][0]),.doa(Dout[1][1][0]),
    .clkb(ap_clk),.enb(EN[1][1][1]),.web(We[1][1][1]),.addrb(Addresses[1][1][1]),.Ben_b(Byte_Enables[1][1][1]),.dib(Din[1][1][1]),.dob(Dout[1][1][1])
    );


///////////////////// ROW 2 /////////////////////////////    

    BRAM bram_2_0(
    .clka(ap_clk),.ena(EN[2][0][0]),.wea(We[2][0][0]),.addra(Addresses[2][0][0]),.Ben_a(Byte_Enables[2][0][0]),.dia(Din[2][0][0]),.doa(Dout[2][0][0]),
    .clkb(ap_clk),.enb(EN[2][0][1]),.web(We[2][0][1]),.addrb(Addresses[2][0][1]),.Ben_b(Byte_Enables[2][0][1]),.dib(Din[2][0][1]),.dob(Dout[2][0][1])
    );
    BRAM bram_2_1(
    .clka(ap_clk),.ena(EN[2][1][0]),.wea(We[2][1][0]),.addra(Addresses[2][1][0]),.Ben_a(Byte_Enables[2][1][0]),.dia(Din[2][1][0]),.doa(Dout[2][1][0]),
    .clkb(ap_clk),.enb(EN[2][1][1]),.web(We[2][1][1]),.addrb(Addresses[2][1][1]),.Ben_b(Byte_Enables[2][1][1]),.dib(Din[2][1][1]),.dob(Dout[2][1][1])
    );


///////////////////// ROW 3 /////////////////////////////    

    BRAM bram_3_0(
    .clka(ap_clk),.ena(EN[3][0][0]),.wea(We[3][0][0]),.addra(Addresses[3][0][0]),.Ben_a(Byte_Enables[3][0][0]),.dia(Din[3][0][0]),.doa(Dout[3][0][0]),
    .clkb(ap_clk),.enb(EN[3][0][1]),.web(We[3][0][1]),.addrb(Addresses[3][0][1]),.Ben_b(Byte_Enables[3][0][1]),.dib(Din[3][0][1]),.dob(Dout[3][0][1])
    );
    BRAM bram_3_1(
    .clka(ap_clk),.ena(EN[3][1][0]),.wea(We[3][1][0]),.addra(Addresses[3][1][0]),.Ben_a(Byte_Enables[3][1][0]),.dia(Din[3][1][0]),.doa(Dout[3][1][0]),
    .clkb(ap_clk),.enb(EN[3][1][1]),.web(We[3][1][1]),.addrb(Addresses[3][1][1]),.Ben_b(Byte_Enables[3][1][1]),.dib(Din[3][1][1]),.dob(Dout[3][1][1])
    );


///////////////////// ROW 4 /////////////////////////////    

    BRAM bram_4_0(
    .clka(ap_clk),.ena(EN[4][0][0]),.wea(We[4][0][0]),.addra(Addresses[4][0][0]),.Ben_a(Byte_Enables[4][0][0]),.dia(Din[4][0][0]),.doa(Dout[4][0][0]),
    .clkb(ap_clk),.enb(EN[4][0][1]),.web(We[4][0][1]),.addrb(Addresses[4][0][1]),.Ben_b(Byte_Enables[4][0][1]),.dib(Din[4][0][1]),.dob(Dout[4][0][1])
    );
    BRAM bram_4_1(
    .clka(ap_clk),.ena(EN[4][1][0]),.wea(We[4][1][0]),.addra(Addresses[4][1][0]),.Ben_a(Byte_Enables[4][1][0]),.dia(Din[4][1][0]),.doa(Dout[4][1][0]),
    .clkb(ap_clk),.enb(EN[4][1][1]),.web(We[4][1][1]),.addrb(Addresses[4][1][1]),.Ben_b(Byte_Enables[4][1][1]),.dib(Din[4][1][1]),.dob(Dout[4][1][1])
    );


///////////////////////////////////////////////  RAM COMPONENTS END /////////////////////////////////////////////////////////


    

    logic [7:0] input_bytes[16];
    always_comb begin
        for(int i=0;i<16;i++) input_bytes[i] = inData_tdata_reg[127-8*i-:8];
    end


    logic [127:0] row0;
    logic [1:0] sc;
    logic [1:0] PC;

    logic [63:0] row_data_q2;
    logic [31:0] row_data_q4[0:2];

    logic Q4_switch;

    always_comb begin
        for(int i=0;i<8;i++)row_data_q2[i-:8] = input_bytes[2*i+1];
        for(int i=0;i<4;i++)begin
            for(int j=0;j<3;j++)begin
                row_data_q4[j][31-i*8-:8] = input_bytes[4*i+1+j];
            end
        end 
    end

    always_comb begin
        if(Qm==2)begin
            {Din[0][0][0],Din[0][1][0]}  = row_data_q2;
            {Din[1][0][0],Din[1][1][0]}  = row_data_q2;
            {Din[2][0][0],Din[2][1][0]}  = row_data_q2;
        end 

        else if(Qm==6)begin
            {Din[0][0][0],Din[0][1][0]}  = {input_bytes[1],input_bytes[7],input_bytes[13],input_bytes[3],input_bytes[9],input_bytes[15],input_bytes[5],input_bytes[11]};
            {Din[1][0][0],Din[1][1][0]}  = {input_bytes[2],input_bytes[8],input_bytes[14],input_bytes[4],input_bytes[10],input_bytes[0],input_bytes[6],input_bytes[12]};
            {Din[2][0][0],Din[2][1][0]}  = {input_bytes[3],input_bytes[9],input_bytes[15],input_bytes[5],input_bytes[11],input_bytes[1],input_bytes[7],input_bytes[13]};
            {Din[3][0][0],Din[3][1][0]}  = {input_bytes[4],input_bytes[10],input_bytes[0],input_bytes[6],input_bytes[12],input_bytes[2],input_bytes[8],input_bytes[14]};
            {Din[4][0][0],Din[4][1][0]}  = {input_bytes[5],input_bytes[11],input_bytes[1],input_bytes[7],input_bytes[13],input_bytes[3],input_bytes[9],input_bytes[15]};
        end
        else begin
            {Din[0][0][0],Din[0][1][0]}  = {input_bytes[1],input_bytes[5],input_bytes[9],input_bytes[13],input_bytes[1],input_bytes[5],input_bytes[9],input_bytes[13]};

            {Din[2][0][0],Din[2][1][0]}  = {input_bytes[3],input_bytes[7],input_bytes[11],input_bytes[15],input_bytes[3],input_bytes[7],input_bytes[11],input_bytes[15]};
            {Din[3][0][0],Din[3][1][0]}  = {input_bytes[3],input_bytes[7],input_bytes[11],input_bytes[15],input_bytes[3],input_bytes[7],input_bytes[11],input_bytes[15]};

            if(Q4_switch) {Din[1][0][0],Din[1][1][0]} = {input_bytes[1],input_bytes[5],input_bytes[9],input_bytes[13],input_bytes[1],input_bytes[5],input_bytes[9],input_bytes[13]};
            else          {Din[1][0][0],Din[1][1][0]} = {input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14],input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14]};
            
            {Din[4][0][0],Din[4][1][0]}  = {input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14],input_bytes[2],input_bytes[6],input_bytes[10],input_bytes[14]};

        end
    end


    logic [9:0] Address;

    


    always_ff@(posedge ap_clk)begin
        if(!ap_rst_n) begin
            sc <=0;
            PC <=0;
        end
        else if(inData_tvalid_reg) begin
            if(Qm==2) begin
                sc[0] <= !sc[0];
                row0[127-64*sc[0]-:64] <= {input_bytes[0],input_bytes[2],input_bytes[4],input_bytes[6],input_bytes[8],input_bytes[10],input_bytes[12],input_bytes[14]} ;
                if(Address ==1023) PC <= PC+1;
            end
        end  
    end

///////////////////////////////////////// ADDRESS HANDLING //////////////////////////////////////////

    always_ff@(posedge ap_clk)begin
        if(!ap_rst_n | (state==read_over) | (state==write_over)) Address <= 0;
        else if(state==reading )begin
            if(inData_tvalid_reg)begin
                if(Qm==2) Address <= Address +1;
                //else if(Qm==4) if(sc[0]==1) Address <= Address +1;
            end
        end
        else begin
            if(Qm==2)begin
                Address <= Address+2; 
            end
        end
    end



    always_comb begin

        if(Qm==2 | Qm==6)begin
            for(int i=0;i<5;i++)begin
                Addresses[i][0][0] = Address;
                Addresses[i][1][0] = Address;
            end
        end

         
    end

    always_comb begin
        for(int i=0;i<5;i++)begin
            Addresses[i][0][1] = {Address[9:1],1'b1};
            Addresses[i][1][1] = {Address[9:1],1'b1};           
        end
    end

////////////////////////////////////////////////////////////////
    logic [2:0] out_no;
    always_ff@(posedge ap_clk)begin
        if(!ap_rst_n ) out_no <= 0;
        else if(state==read_over) out_no <=1;
        else if(state == writing) begin
            if(Qm==2)begin
                if (Address ==1022) begin
                    out_no <= out_no+1;
                end
            end
        end
    end


///////////////////////////////////////// ADDRESS HANDLING  END//////////////////////////////////////////

   


    ///////////////////////////////////////////////// RAM_ENABLES AND WRITE ENABLES /////////////////////////////////////////////////////


    //////////////////////////////////   ENABLES //////////////////////////////////////////
    always_comb begin
        for(int i=0;i<5;i++)begin
            for(int j=0;j<2;j++)begin
                EN[i][j][0] =0;
                EN[i][j][1] =0;
            end
        end

        if(state==reading)begin
            if(Qm==2)begin
                if(PC==0) begin
                    EN[0][0][0] =1;
                    EN[0][1][0] =1;
                end
                else if(PC==1) begin
                    EN[1][0][0] =1;
                    EN[1][1][0] =1;
                end
                else if(PC==2) begin
                    EN[2][0][0] =1;
                    EN[2][1][0] =1;
                end
            end
        end
        else if(state==writing)begin
            if(Qm==2)begin
                if(out_no==1) begin
                    EN[0][0][0] =1;
                    EN[0][1][0] =1;
                    EN[0][0][1] =1;
                    EN[0][1][1] =1;
                end
                else if(out_no==2) begin
                    EN[1][0][0] =1;
                    EN[1][1][0] =1;
                    EN[1][0][1] =1;
                    EN[1][1][1] =1;
                end
                else if(out_no==3) begin
                    EN[2][0][0] =1;
                    EN[2][1][0] =1;
                    EN[2][0][1] =1;
                    EN[2][1][1] =1;
                end
            end
        end


    end



///////////////////////////  WRITE ENABLES ///////////////////////////////////////

    always_comb begin
        for(int i=0;i<5;i++)begin
            for(int j=0;j<2;j++)begin
                We[i][j][0] =0;
                We[i][j][1] =0;
            end
        end
        if(state==reading && inData_tvalid_reg)begin
            if(Qm==2)begin
                for(int i=0;i<5;i++)for(int j=0;j<2;j++) We[i][j][0] =0;   
            end
        end

    end

//////////////////////////////////////// BYTE ENABLES ///////////////////////////////

    always_comb begin
      
        if(Qm==2) begin
            for(int i=0;i<3;i++) begin
                for(int j=0;j<2;j++)begin
                    Byte_Enables[i][j][0] =4'b1111;
                end
            end
        end
    end

//////////////////////////////////////////////////

    

    logic [127:0] outData_tdata_wire;
    always_comb begin
        if(out_no==0) outData_tdata_wire = row0;
        else if(out_no==1) outData_tdata_wire = {Dout[0][0][0],Dout[0][1][0],Dout[0][0][1],Dout[0][1][1]};
        else if(out_no==2) outData_tdata_wire = {Dout[1][0][0],Dout[1][1][0],Dout[1][0][1],Dout[1][1][1]};
        else if(out_no==3) outData_tdata_wire = {Dout[2][0][0],Dout[2][1][0],Dout[2][0][1],Dout[2][1][1]};
        else if(out_no==4) outData_tdata_wire = {Dout[3][0][0],Dout[3][1][0],Dout[3][0][1],Dout[3][1][1]};
        else  outData_tdata_wire = {Dout[4][0][0],Dout[4][1][0],Dout[4][0][1],Dout[4][1][1]};       
                
    end

    wire output_update = (outData_tvalid && outData_tready) | (outData_tvalid==0);
    logic outData_tdata_wire_valid;

    always@(posedge ap_clk)begin
        if(!ap_rst_n | (state==write_over)) outData_tdata_wire_valid <=0;
        else if(state==reading && inData_tvalid_reg) begin
            if(Qm==2)begin
                outData_tdata_wire_valid <=sc[0];
            end
        end
        else if(state==writing | (state==read_over) )begin
            outData_tdata_wire_valid <=1;
        end
    end

    logic [10:0] row_out_counter;
    wire row_end = outputs_per_row == row_out_counter;
    wire [2:0] row_counter;

    always_ff@(posedge ap_clk)begin
        if(!ap_rst_n) begin
            outData_tvalid <= 0;
            row_out_counter <=0;
        end
        if(output_update)begin
            if(outData_tdata_wire_valid) begin
                outData_tdata <= outData_tdata_wire;
                outData_tvalid <= 1;

                if(row_end && (row_counter==(Qm-1'b1))) outData_tlast <=1;
                else outData_tlast <= 0;

                if(row_end) outData_tkeep <=tkeep_wire;
                else outData_tkeep <= 15;

                row_out_counter <= row_out_counter +1;


            end
            else begin
                outData_tvalid <= 0;
            end
        end
    end















endmodule


module BRAM(
    input               clka,
    input               ena,
    input               wea,
    input       [9:0]   addra,
    input       [3:0]   Ben_a,
    input       [31:0]  dia,
    output reg  [31:0]  doa,

    input               clkb,
    input               enb,
    input               web,
    input       [9:0]   addrb,
    input       [3:0]   Ben_b,
    input       [31:0]  dib,
    output reg  [31:0]  dob
);

    reg [31:0] ram [0:1023];

    // Port A
    always @(posedge clka) begin
        if (ena) begin
            if (wea) begin
                for(int i=0;i<4;i++)begin
                    if(Ben_a[i])ram[addra][31-8*i-:8] <= dia[31-8*i-:8];
                end
            end
            else doa <= ram[addra];   
        end
    end

    // Port B
    always @(posedge clkb) begin
        if (enb) begin
            if (web) begin
                for(int i=0;i<4;i++)begin
                    if(Ben_b[i])ram[addrb][31-8*i-:8] <= dib[31-8*i-:8];
                end
            end
            else dob <= ram[addrb];   
        end
    end

endmodule

module Deinterleaver(
    input logic ap_clk,
    input logic ap_rst_n,

    input logic [215:0] cnData_tdata,
    input logic  cnData_tvalid,
    output logic cnData_tready,

    input logic [127:0] inData_tdata,
    input logic  inData_tvalid,
    output logic inData_tready,
    input logic  inData_tlast,

    output logic [127:0] outData_tdata,
    input logic  outData_tready,
    output logic outData_tvalid,
    output logic  outData_tlast
);

    logic [127:0] BridgeData_tdata;
    logic BridgeData_tready;
    logic BridgeData_tvalid;
    logic BridgeData_tlast;
    logic [3:0] BridgeData_tkeep;

    Deinterleaver_1 deinterleaver(

        .ap_rst_n(ap_rst_n),
        .ap_clk(ap_clk),

        .cnData_tdata(cnData_tdata),
        .cnData_tready(cnData_tready),
        .cnData_tvalid(cnData_tvalid),

        .inData_tdata(inData_tdata),
        .inData_tvalid(inData_tvalid),
        .inData_tready(inData_tready),
        .inData_tlast(inData_tlast),


        .outData_tdata(BridgeData_tdata),
        .outData_tlast(BridgeData_tlast),
        .outData_tvalid(BridgeData_tvalid),
        .outData_tready(BridgeData_tready),
        .outData_tkeep(BridgeData_tkeep)
    );


    PACKER packer(
    .ap_rst_n(ap_rst_n),
    .ap_clk(ap_clk),

    .inData_tdata(BridgeData_tdata),
    .inData_tvalid(BridgeData_tvalid),
    .inData_tready(BridgeData_tready),
    .inData_tlast(BridgeData_tlast),
    .inData_tkeep(BridgeData_tkeep),

    .outData_tdata(outData_tdata),
    .outData_tlast(outData_tlast),
    .outData_tvalid(outData_tvalid),
    .outData_tready(outData_tready)
);




endmodule
