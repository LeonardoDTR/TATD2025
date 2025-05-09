/*
 *  Simple SPI RAM simulation model
 *
 *  Este módulo simula una memoria RAM SPI con soporte para comandos básicos
 *  de lectura y escritura.
 */

`timescale 1 ns / 1 ps

module spiram (
    input csb,       // Chip select (activo bajo)
    input clk,       // Reloj SPI
    inout io0,       // MOSI
    inout io1,       // MISO
    inout io2,       // Opcional (para modos QSPI)
    inout io3        // Opcional (para modos QSPI)
);
    localparam verbose = 0;

    reg [7:0] buffer;
    integer bitcount = 0;
    integer bytecount = 0;

    reg [7:0] spi_cmd;
    reg [23:0] spi_addr;

    reg [7:0] spi_in;
    reg [7:0] spi_out;
    reg spi_io_vld;

    reg io0_oe = 0;
    reg io1_oe = 0;
    reg io2_oe = 0;
    reg io3_oe = 0;

    reg io0_dout = 0;
    reg io1_dout = 0;
    reg io2_dout = 0;
    reg io3_dout = 0;

    assign #1 io0 = io0_oe ? io0_dout : 1'bz;
    assign #1 io1 = io1_oe ? io1_dout : 1'bz;
    assign #1 io2 = io2_oe ? io2_dout : 1'bz;
    assign #1 io3 = io3_oe ? io3_dout : 1'bz;

    wire io0_delayed;
    wire io1_delayed;
    wire io2_delayed;
    wire io3_delayed;

    assign #1 io0_delayed = io0;
    assign #1 io1_delayed = io1;
    assign #1 io2_delayed = io2;
    assign #1 io3_delayed = io3;

    // 16 KB RAM
    reg [7:0] memory [0:16*1024-1];

    task spi_action;
        begin
            spi_in = buffer;

            if (bytecount == 1) begin
                spi_cmd = buffer;
            end

            if (spi_cmd == 8'h03) begin // Comando de lectura
                if (bytecount == 2)
                    spi_addr[23:16] = buffer;
                if (bytecount == 3)
                    spi_addr[15:8] = buffer;
                if (bytecount == 4)
                    spi_addr[7:0] = buffer;
                if (bytecount >= 4) begin
                    buffer = memory[spi_addr];
                    spi_addr = spi_addr + 1;
                end
            end

            if (spi_cmd == 8'h02) begin // Comando de escritura
                if (bytecount == 2)
                    spi_addr[23:16] = buffer;
                if (bytecount == 3)
                    spi_addr[15:8] = buffer;
                if (bytecount == 4)
                    spi_addr[7:0] = buffer;
                if (bytecount >= 4) begin
                    memory[spi_addr] = buffer;
                    spi_addr = spi_addr + 1;
                end
            end

            spi_out = buffer;
            spi_io_vld = 1;

            if (verbose) begin
                if (bytecount == 1)
                    $write("<SPI-START>");
                $write("<SPI:%02x:%02x>", spi_in, spi_out);
            end
        end
    endtask

    always @(posedge clk or posedge csb) begin
        if (csb) begin
            buffer = 0;
            bitcount = 0;
            bytecount = 0;
            io0_oe = 0;
            io1_oe = 0;
            io2_oe = 0;
            io3_oe = 0;
        end else begin
            buffer = {buffer[6:0], io0_delayed};
            bitcount = bitcount + 1;
            if (bitcount == 8) begin
                bitcount = 0;
                bytecount = bytecount + 1;
                spi_action;
            end
        end
    end
endmodule