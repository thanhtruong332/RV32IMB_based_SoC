`timescale 1ns / 1ps

module aes_axi_slave #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32
)(
    input wire  S_AXI_ACLK, S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input wire  S_AXI_AWVALID, output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input wire [3:0]  S_AXI_WSTRB, input wire  S_AXI_WVALID, output wire S_AXI_WREADY,
    output wire [1:0] S_AXI_BRESP, output reg S_AXI_BVALID, input wire S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input wire  S_AXI_ARVALID, output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0] S_AXI_RRESP, output reg S_AXI_RVALID, input wire S_AXI_RREADY
);

    reg aw_received, w_received, ar_received;
    reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_reg, araddr_reg;
    reg [C_S_AXI_DATA_WIDTH-1:0] wdata_reg;
    reg [3:0] wstrb_reg;

    // Accept a write address when the write channel is idle.
    assign S_AXI_AWREADY = ~aw_received;
    assign S_AXI_WREADY  = ~w_received;
    assign S_AXI_ARREADY = ~ar_received;
    assign S_AXI_BRESP   = 2'b00;
    assign S_AXI_RRESP   = 2'b00;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            aw_received <= 1'b0;
            awaddr_reg  <= 0;
        end else begin
            if (S_AXI_AWVALID && S_AXI_AWREADY) begin
                aw_received <= 1'b1;
                awaddr_reg  <= S_AXI_AWADDR;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                aw_received <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            w_received <= 1'b0;
            wdata_reg  <= 0;
            wstrb_reg  <= 0;
        end else begin
            if (S_AXI_WVALID && S_AXI_WREADY) begin
                w_received <= 1'b1;
                wdata_reg  <= S_AXI_WDATA;
                wstrb_reg  <= S_AXI_WSTRB;
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                w_received <= 1'b0;
            end
        end
    end

    reg write_pulse;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_BVALID <= 1'b0;
            write_pulse  <= 1'b0;
        end else begin

            if (aw_received && w_received && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b1;
                write_pulse  <= 1'b1;
            end else begin
                write_pulse <= 1'b0;
                if (S_AXI_BVALID && S_AXI_BREADY) begin
                    S_AXI_BVALID <= 1'b0;
                end
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            ar_received <= 1'b0;
            araddr_reg  <= 0;
        end else begin
            if (S_AXI_ARVALID && S_AXI_ARREADY) begin
                ar_received <= 1'b1;
                araddr_reg  <= S_AXI_ARADDR;
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                ar_received <= 1'b0;
            end
        end
    end

    reg read_pulse;
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_RVALID <= 1'b0;
            read_pulse   <= 1'b0;
        end else begin
            if (ar_received && !S_AXI_RVALID) begin
                S_AXI_RVALID <= 1'b1;
                read_pulse   <= 1'b1;
            end else begin
                read_pulse <= 1'b0;
                if (S_AXI_RVALID && S_AXI_RREADY) begin
                    S_AXI_RVALID <= 1'b0;
                end
            end
        end
    end

    wire [31:0] wrapper_addr = write_pulse ? awaddr_reg : (read_pulse ? araddr_reg : 32'h0);
    wire [31:0] wrapper_wdata = wdata_reg;
    wire [3:0]  wrapper_wstrb = wstrb_reg;

    aes_wrapper aes_inst (
        .clk(S_AXI_ACLK),
        .rst_n(S_AXI_ARESETN),
        .addr(wrapper_addr),
        .wdata(wrapper_wdata),
        .wstrb(wrapper_wstrb),
        .read_en(read_pulse),
        .write_en(write_pulse),
        .rdata(S_AXI_RDATA),
        .ready()
    );

endmodule
