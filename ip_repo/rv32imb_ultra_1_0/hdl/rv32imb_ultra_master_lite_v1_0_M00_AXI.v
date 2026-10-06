`timescale 1 ns / 1 ps
//  rv32imb_ultra_master_lite_v1_0_M00_AXI - BAN SUA DAY DU
//  Bug cu: phat AW (IDLE) roi W (WADDR) → 2 kenh LECH pha → qua
//          interconnect + slave decoupled → WDATA ghep nham (=0) o 0x44.
//  Sua: phat AWVALID + WVALID DONG THOI tu IDLE; ha tung kenh khi
//       kenh do bat tay xong; vao WRESP khi CA hai xong.
//  Chi sua khoi WRITE FSM; doc + instruction giu nguyen.
module rv32imb_ultra_master_lite_v1_0_M00_AXI #
(
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32
)
(
    input wire  INIT_AXI_TXN,
    output wire  ERROR,
    output wire  TXN_DONE,
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output wire [2 : 0] M_AXI_AWPROT,
    output wire  M_AXI_AWVALID,
    input wire  M_AXI_AWREADY,
    output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
    output wire  M_AXI_WVALID,
    input wire  M_AXI_WREADY,
    input wire [1 : 0] M_AXI_BRESP,
    input wire  M_AXI_BVALID,
    output wire  M_AXI_BREADY,
    output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
    output wire [2 : 0] M_AXI_ARPROT,
    output wire  M_AXI_ARVALID,
    input wire  M_AXI_ARREADY,
    input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
    input wire [1 : 0] M_AXI_RRESP,
    input wire  M_AXI_RVALID,
    output wire  M_AXI_RREADY,
    output wire [31:0] INST_ADDR,
    input  wire [31:0] INST_DATA
);
    assign ERROR = 1'b0;
    assign TXN_DONE = 1'b0;

    wire [31:0] cpu_mem_addr;
    wire [31:0] cpu_mem_wdata;
    wire [31:0] cpu_mem_rdata;
    wire        cpu_mem_write;
    wire        cpu_mem_read;
    reg         cpu_mem_ready;

    rv32i_top cpu_core_inst (
        .clk(M_AXI_ACLK),
        .rst_n(M_AXI_ARESETN),
        .MEM_RDATA(cpu_mem_rdata),
        .MEM_READY(cpu_mem_ready),
        .CPU_DATA(),
        .CPU_PRIVILEGED(),
        .HPROT(),
        .MEM_ADDR(cpu_mem_addr),
        .MEM_WDATA(cpu_mem_wdata),
        .MEM_WRITE(cpu_mem_write),
        .MEM_READ(cpu_mem_read),
        .INST_ADDR(INST_ADDR),
        .INST_DATA(INST_DATA)
    );

    // FSM: IDLE -> WRITE (AW+W dong thoi) -> WRESP -> IDLE
    //      IDLE -> RADDR -> RDATA -> IDLE
    localparam IDLE   = 3'd0;
    localparam WRITE  = 3'd1;
    localparam WRESP  = 3'd3;
    localparam RADDR  = 3'd4;
    localparam RDATA  = 3'd5;

    reg [2:0] state, next_state;

    reg [31:0] axi_awaddr;
    reg axi_awvalid;
    reg [31:0] axi_wdata;
    reg axi_wvalid;
    reg axi_bready;
    reg [31:0] axi_araddr;
    reg axi_arvalid;
    reg axi_rready;
    reg [31:0] rdata_reg;

    // Co theo doi tung kenh write da bat tay xong chua
    reg aw_done_n, w_done_n;

    assign M_AXI_AWADDR  = axi_awaddr;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_AWVALID = axi_awvalid;
    assign M_AXI_WDATA   = axi_wdata;
    assign M_AXI_WSTRB   = 4'b1111;
    assign M_AXI_WVALID  = axi_wvalid;
    assign M_AXI_BREADY  = axi_bready;
    assign M_AXI_ARADDR  = axi_araddr;
    assign M_AXI_ARPROT  = 3'b000;
    assign M_AXI_ARVALID = axi_arvalid;
    assign M_AXI_RREADY  = axi_rready;
    assign cpu_mem_rdata = rdata_reg;

    // 1. State register
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 2. Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (cpu_mem_write && !cpu_mem_ready)
                    next_state = WRITE;
                else if (cpu_mem_read && !cpu_mem_ready)
                    next_state = RADDR;
            end
            // Roi WRITE khi CA hai kenh AW va W da bat tay
            WRITE: if ((aw_done_n || (M_AXI_AWREADY && axi_awvalid)) &&
                       (w_done_n  || (M_AXI_WREADY  && axi_wvalid)))
                       next_state = WRESP;
            WRESP: if (M_AXI_BVALID && axi_bready) next_state = IDLE;
            RADDR: if (M_AXI_ARREADY && axi_arvalid) next_state = RDATA;
            RDATA: if (M_AXI_RVALID && axi_rready)   next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // 3. Output logic
    always @(posedge M_AXI_ACLK) begin
        if (!M_AXI_ARESETN) begin
            axi_awvalid <= 0; axi_wvalid <= 0; axi_bready <= 0;
            axi_arvalid <= 0; axi_rready <= 0; cpu_mem_ready <= 0;
            axi_awaddr <= 0;  axi_wdata <= 0;  axi_araddr <= 0;
            aw_done_n <= 0;   w_done_n <= 0;
        end else begin
            cpu_mem_ready <= 0;

            case (state)
                IDLE: begin
                    axi_awvalid <= 0; axi_wvalid <= 0; axi_bready <= 0;
                    axi_arvalid <= 0; axi_rready <= 0;
                    aw_done_n <= 0;   w_done_n <= 0;

                    if (cpu_mem_write && !cpu_mem_ready) begin
                        axi_awaddr  <= cpu_mem_addr;
                        axi_wdata   <= cpu_mem_wdata;
                        axi_awvalid <= 1;          // PHAT CA HAI CUNG LUC
                        axi_wvalid  <= 1;          // (ban cu chi co awvalid)
                    end else if (cpu_mem_read && !cpu_mem_ready) begin
                        axi_araddr  <= cpu_mem_addr;
                        axi_arvalid <= 1;
                    end
                end

                WRITE: begin
                    // Ha valid tung kenh ngay khi kenh do bat tay (doc lap)
                    if (M_AXI_AWREADY && axi_awvalid) begin
                        axi_awvalid <= 0;
                        aw_done_n   <= 1;
                    end
                    if (M_AXI_WREADY && axi_wvalid) begin
                        axi_wvalid <= 0;
                        w_done_n   <= 1;
                    end
                    // Khi CA hai kenh xong → mo BREADY don BVALID
                    if ((aw_done_n || (M_AXI_AWREADY && axi_awvalid)) &&
                        (w_done_n  || (M_AXI_WREADY  && axi_wvalid))) begin
                        axi_bready <= 1;
                    end
                end

                WRESP: begin
                    if (M_AXI_BVALID && axi_bready) begin
                        axi_bready    <= 0;
                        cpu_mem_ready <= 1;
                        aw_done_n     <= 0;
                        w_done_n      <= 0;
                    end
                end

                RADDR: begin
                    if (M_AXI_ARREADY && axi_arvalid) begin
                        axi_arvalid <= 0;
                        axi_rready  <= 1;
                    end
                end

                RDATA: begin
                    if (M_AXI_RVALID && axi_rready) begin
                        rdata_reg     <= M_AXI_RDATA;
                        axi_rready    <= 0;
                        cpu_mem_ready <= 1;
                    end
                end
            endcase
        end
    end

endmodule
