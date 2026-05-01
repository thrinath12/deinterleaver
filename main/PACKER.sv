module PACKER(
    input logic ap_clk,
    input logic ap_rst_n,

    input logic [127:0] inData_tdata,
    input logic  inData_tvalid,
    output logic inData_tready,
    input logic  inData_tlast,
    input logic [3:0] inData_tkeep,

    output logic [127:0] outData_tdata,
    input logic  outData_tready,
    output logic outData_tvalid,
    output logic  outData_tlast
);




   

    logic [119:0] storage;
    wire [127:0] storage_extended = {storage,8'b0};
    logic [3:0] storage_byte_count;
    logic spill;
    wire transaction = (inData_tvalid && inData_tready) | (!outData_tvalid);

    logic [127:0] p128;
    logic [127:0] storage_temp;

    always_comb begin
        p128 = storage_extended | (inData_tdata>>(storage_byte_count*8));  
        storage_temp = inData_tdata<<((16-storage_byte_count)*8);
    end

    always_ff@(posedge ap_clk)begin
        if(!ap_rst_n)begin
            storage_byte_count <=0;
        end
        else if(transaction) begin
            if(storage_byte_count+inData_tkeep+1 >=16)begin
                storage <= storage_temp[127:8];
                storage_byte_count <= storage_byte_count + inData_tkeep+1-5'd16;
                outData_tdata <=p128;
                outData_tvalid <=1;
                outData_tlast <= inData_tlast;
            end
            else begin
                storage_byte_count <= storage_byte_count+inData_tkeep+1;;
                storage <= p128[127:8];
                outData_tvalid <=0;
                outData_tlast <=0;

            end
        end
    end


endmodule
