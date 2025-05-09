module MappedSPIRAM(
    input wire        clk,          // system clock
    input wire        rstrb,        // read strobe
    input wire        wstrb,        // write strobe
    input wire [19:0] word_address, // address of the word to be accessed
    input wire [31:0] wdata,        // data to write
    output wire [31:0] rdata,       // data read
    output wire       rbusy,        // busy signal for read
    output wire       wbusy,        // busy signal for write

    // SPI RAM pins
    output wire       CLK,  // clock
    output reg        CS_N, // chip select negated (active low)
    output wire       MOSI, // master out slave in (data to be sent to RAM)
    input  wire       MISO  // master in slave out (data received from RAM)
);

    reg [5:0]  snd_bitcount;
    reg [31:0] cmd_addr;
    reg [31:0] rcv_data;
    reg [31:0] write_data;
    reg [5:0]  rcv_bitcount;
    wire       sending   = (snd_bitcount != 0);
    wire       receiving = (rcv_bitcount != 0);
    wire       busy = sending | receiving;
    assign     rbusy = !CS_N && receiving;
    assign     wbusy = !CS_N && sending;

    assign MOSI = cmd_addr[31];
    initial CS_N = 1'b1;
    assign CLK = !CS_N && !clk;

    assign rdata = {rcv_data[7:0], rcv_data[15:8], rcv_data[23:16], rcv_data[31:24]};

    always @(posedge clk) begin
        if (rstrb) begin
            CS_N <= 1'b0;
            cmd_addr <= {8'h03, 2'b00, word_address[19:0], 2'b00}; // Read command
            snd_bitcount <= 6'd32;
        end else if (wstrb) begin
            CS_N <= 1'b0;
            cmd_addr <= {8'h02, 2'b00, word_address[19:0], 2'b00}; // Write command
            write_data <= wdata;
            snd_bitcount <= 6'd32;
        end else begin
            if (sending) begin
                if (snd_bitcount == 1) begin
                    if (cmd_addr[31:24] == 8'h03) // Read command
                        rcv_bitcount <= 6'd32;
                end
                snd_bitcount <= snd_bitcount - 6'd1;
                cmd_addr <= {cmd_addr[30:0], 1'b1};
            end
            if (receiving) begin
                rcv_bitcount <= rcv_bitcount - 6'd1;
                rcv_data <= {rcv_data[30:0], MISO};
            end
            if (!busy) begin
                CS_N <= 1'b1;
            end
        end
    end
endmodule