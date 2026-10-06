module rv32i_top(
    input   wire            clk,
    input   wire            rst_n,
    input   wire    [31:0]  MEM_RDATA,
    input   wire            MEM_READY,

    output  wire            CPU_DATA,
    output  wire            CPU_PRIVILEGED,
    output  wire    [3:0]   HPROT,
    output  wire    [31:0]  MEM_ADDR,
    output  wire    [31:0]  MEM_WDATA,
    output  wire            MEM_WRITE,
    output  wire            MEM_READ,

    output  wire    [31:0]  INST_ADDR,
    input   wire    [31:0]  INST_DATA
);
    wire    [31:0]  Instruction;
    wire            RegWrite, MemRead, MemToReg, MemWrite, Branch, Jump, ALUSrc1, ALUSrc2, LUI, Pcsrc, ZERO;
    wire    [6:0]   opcode;
    wire    [2:0]   ALUOp;
    wire    [3:0]   ALUControl;
    wire    [31:0]  immediate_raw, immediate;
    wire    [31:0]  ALU_result;
    wire    [31:0]  operand_1, operand_2;
    wire            Branch_taken;
    wire    [31:0]  pc;
    wire            Stall, Flush;
    wire    [31:0]  ALU_B, ALU_A;
    wire    [2:0]   funct3;
    wire    [31:0]  write_data;
    wire    [31:0]  mem_data;
    wire    [31:0]  pc_plus4;
    wire    [2:0]   imm_type;
    wire    [1:0]   ForwardA, ForwardB;
    wire            bus_stall;

    assign INST_ADDR = pc;
    assign Instruction = INST_DATA;

    wire            ID_Flush;
    (* DONT_TOUCH = "yes" *) reg     [31:0]  IF_ID_pc;
    (* DONT_TOUCH = "yes" *) reg     [31:0]  IF_ID_Instruction;

    (* DONT_TOUCH = "yes" *) reg             ID_EX_RegWrite;
    (* DONT_TOUCH = "yes" *) reg     [4:0]   ID_EX_rd;
    (* DONT_TOUCH = "yes" *) reg     [31:0]  ID_EX_pc;
    reg     [4:0]   ID_EX_rs1;
    reg     [4:0]   ID_EX_rs2;
    reg     [31:0]  ID_EX_rv1;
    reg     [31:0]  ID_EX_rv2;
    reg     [31:0]  ID_EX_imm;
    reg     [6:0]   ID_EX_funct7;
    reg     [6:0]   ID_EX_opcode;   // THEM: luu opcode de chong aliasing M/B
    reg     [2:0]   ID_EX_funct3, ID_EX_ALUOp;
    reg             ID_EX_Mem_Read, ID_EX_Mem_Write, ID_EX_Mem_To_Reg, ID_EX_Branch, ID_EX_Jump, ID_EX_ALUSrc1, ID_EX_ALUSrc2, ID_EX_LUI, ID_EX_Pcsrc;

    reg     [31:0]  EX_MEM_imm;
    reg     [31:0]  EX_MEM_pc_plus;
    reg             EX_MEM_Jump, EX_MEM_LUI;
    (* DONT_TOUCH = "yes" *) reg             EX_MEM_RegWrite;
    (* DONT_TOUCH = "yes" *) reg     [4:0]   EX_MEM_rd;
    reg             EX_MEM_Mem_Read, EX_MEM_Mem_Write, EX_MEM_Mem_To_Reg;
    reg     [2:0]   EX_MEM_funct3;
    reg     [31:0]  EX_MEM_rv2;
    (* DONT_TOUCH = "yes" *) reg     [31:0]  EX_MEM_ALU_result;

    reg     [31:0]  MEM_WB_imm;
    reg     [31:0]  MEM_WB_pc_plus;
    reg             MEM_WB_Jump, MEM_WB_LUI;
    (* DONT_TOUCH = "yes" *) reg             MEM_WB_RegWrite;
    (* DONT_TOUCH = "yes" *) reg     [4:0]   MEM_WB_rd;
    reg             MEM_WB_Mem_To_Reg;
    reg     [31:0]  MEM_WB_mem_data;
    (* DONT_TOUCH = "yes" *) reg     [31:0]  MEM_WB_ALU_result;

    wire    [31:0]  forwardA_data, forwardB_data;
    wire            is_data_access, hazard_stall;

    assign  is_data_access  =   (EX_MEM_Mem_Read || EX_MEM_Mem_Write);
    assign  HPROT           =   {2'b00, 1'b1, is_data_access};

    assign  Flush           =   (ID_EX_Branch && Branch_taken) || ID_EX_Jump;

    wire [31:0] ex_mem_forward_data;
    assign ex_mem_forward_data = (EX_MEM_Jump) ? EX_MEM_pc_plus :
                                 (EX_MEM_LUI)  ? EX_MEM_imm :
                                                 EX_MEM_ALU_result;

    assign  forwardA_data   =   (ForwardA == 2'b00) ? ID_EX_rv1 :
                                (ForwardA == 2'b10) ? ex_mem_forward_data :
                                (ForwardA == 2'b01) ? write_data : ID_EX_rv1;

    assign  forwardB_data   =   (ForwardB == 2'b00) ? ID_EX_rv2 :
                                (ForwardB == 2'b10) ? ex_mem_forward_data :
                                (ForwardB == 2'b01) ? write_data : ID_EX_rv2;

    assign  pc_plus4        =   ID_EX_pc + 32'd4;
    assign  write_data      =   (MEM_WB_Mem_To_Reg) ? MEM_WB_mem_data :
                                (MEM_WB_Jump)       ? MEM_WB_pc_plus  :
                                (MEM_WB_LUI)        ? MEM_WB_imm      : MEM_WB_ALU_result;

    assign  ALU_A           =   (ID_EX_ALUSrc1)     ? ID_EX_pc : forwardA_data;
    assign  ALU_B           =   (ID_EX_ALUSrc2)     ? ID_EX_imm : forwardB_data;
    assign  opcode          =   IF_ID_Instruction[6:0];
    assign  funct3          =   IF_ID_Instruction[14:12];
    assign  CPU_PRIVILEGED  =   1'b1;
    assign  MEM_ADDR        =   EX_MEM_ALU_result;
    assign  MEM_WDATA       =   EX_MEM_rv2;
    assign  MEM_WRITE       =   EX_MEM_Mem_Write;
    assign  MEM_READ        =   EX_MEM_Mem_Read;
    assign  CPU_DATA        =   is_data_access;
    assign  mem_data        =   MEM_RDATA;
    assign  bus_stall       =   (MEM_READ || MEM_WRITE) && !MEM_READY;
    assign  Stall           =   hazard_stall | bus_stall;

    // SUA BUG ALIASING: M/B-ext la R-type (opcode 0110011).
    // Cu chi check ALUOp+funct7 → addi (I-type) co imm[11:5]=funct7 bi nham.
    // Them check opcode == R-type.
    wire is_R_type = (ID_EX_opcode == 7'b0110011);
    wire is_M_ext = is_R_type && (ID_EX_funct7 == 7'b0000001);
    wire is_B_ext = is_R_type && (ID_EX_funct7 == 7'b0110000);

    wire [1:0] b_op_sel = (ID_EX_funct3 == 3'b001) ? 2'b00 :
                          (ID_EX_funct3 == 3'b010) ? 2'b01 :
                          (ID_EX_funct3 == 3'b011) ? 2'b10 : 2'b11;

    wire [31:0] m_out;
    wire [31:0] b_out;
    wire [31:0] final_ex_result;

    assign final_ex_result = is_M_ext ? m_out :
                             is_B_ext ? b_out :
                                        ALU_result;

    //IF_ID register (giu nguyen - !Stall de giu khi stall, dung)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            IF_ID_pc            <= 32'h0;
            IF_ID_Instruction   <= 32'h0;
        end
        else if(Flush) begin
            IF_ID_pc            <= 32'h0;
            IF_ID_Instruction   <= 32'h0000_0013; // NOP
        end
        else if(!Stall) begin
            IF_ID_pc            <= pc;
            IF_ID_Instruction   <= Instruction;
        end
        // else (Stall): giu nguyen - dung
    end

    //ID_EX register - DA SUA
    //  Cu: else if(Stall || ID_Flush || Flush) → flush (Stall gom bus_stall → SAI)
    //  Moi: bus_stall → GIU NGUYEN; flush chi cho hazard/branch/jump
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ID_EX_rs1           <= 32'h0;
            ID_EX_rs2           <= 32'h0;
            ID_EX_pc            <= 32'h0;
            ID_EX_rv1           <= 32'h0;
            ID_EX_rv2           <= 32'h0;
            ID_EX_imm           <= 32'h0;
            ID_EX_funct3        <= 3'h0;
            ID_EX_ALUOp         <= 3'h0;
            ID_EX_ALUSrc1       <= 1'h0;
            ID_EX_Mem_Read      <= 1'h0;
            ID_EX_Mem_Write     <= 1'h0;
            ID_EX_Mem_To_Reg    <= 1'h0;
            ID_EX_Branch        <= 1'h0;
            ID_EX_Jump          <= 1'h0;
            ID_EX_ALUSrc2       <= 1'h0;
            ID_EX_LUI           <= 1'h0;
            ID_EX_Pcsrc         <= 1'h0;
            ID_EX_funct7        <= 7'h0;
            ID_EX_opcode        <= 7'h0;
            ID_EX_rd            <= 5'b0;
            ID_EX_RegWrite      <= 1'b0;
        end
        // === SUA: bus_stall → GIU NGUYEN (pipeline dung yen cho AXI) ===
        else if(bus_stall) begin
            // Khong lam gi: tat ca ID_EX_* giu gia tri cu
            // → lenh sw dang cho AXI KHONG bi mat rv2
        end
        // === Flush (bong bong) CHI cho hazard / branch / jump ===
        else if(hazard_stall || ID_Flush || Flush) begin
            ID_EX_RegWrite      <= 1'b0;
            ID_EX_Mem_Read      <= 1'b0;
            ID_EX_Mem_Write     <= 1'b0;
            ID_EX_Branch        <= 1'b0;
            ID_EX_Jump          <= 1'b0;
            ID_EX_ALUSrc1       <= 1'b0;
            ID_EX_ALUSrc2       <= 1'b0;
            ID_EX_LUI           <= 1'b0;
            ID_EX_Pcsrc         <= 1'b0;
            ID_EX_ALUOp         <= 3'b0;
            ID_EX_rs1           <= 5'b0;
            ID_EX_rs2           <= 5'b0;
            ID_EX_rd            <= 5'b0;
            ID_EX_rv1           <= 32'b0;
            ID_EX_rv2           <= 32'b0;
            ID_EX_imm           <= 32'b0;
            ID_EX_opcode        <= 7'b0;
        end
        else begin
            ID_EX_rs1           <= IF_ID_Instruction[19:15];
            ID_EX_rs2           <= IF_ID_Instruction[24:20];
            ID_EX_pc            <= IF_ID_pc;
            ID_EX_rv1           <= operand_1;
            ID_EX_rv2           <= operand_2;
            ID_EX_imm           <= immediate;
            ID_EX_funct3        <= funct3;
            ID_EX_ALUOp         <= ALUOp;
            ID_EX_ALUSrc1       <= ALUSrc1;
            ID_EX_Mem_Read      <= MemRead;
            ID_EX_Mem_Write     <= MemWrite;
            ID_EX_Mem_To_Reg    <= MemToReg;
            ID_EX_Branch        <= Branch;
            ID_EX_Jump          <= Jump;
            ID_EX_ALUSrc2       <= ALUSrc2;
            ID_EX_LUI           <= LUI;
            ID_EX_Pcsrc         <= Pcsrc;
            ID_EX_funct7        <= IF_ID_Instruction[31:25];
            ID_EX_opcode        <= IF_ID_Instruction[6:0];
            ID_EX_rd            <= IF_ID_Instruction[11:7];
            ID_EX_RegWrite      <= RegWrite;
        end
    end

    //EX_MEM registers (giu nguyen - !bus_stall de giu, dung)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            EX_MEM_Mem_Read     <= 1'b0;
            EX_MEM_Mem_Write    <= 1'b0;
            EX_MEM_Mem_To_Reg   <= 1'b0;
            EX_MEM_funct3       <= 3'b0;
            EX_MEM_rv2          <= 32'b0;
            EX_MEM_ALU_result   <= 32'b0;
            EX_MEM_rd           <= 5'b0;
            EX_MEM_RegWrite     <= 1'b0;
            EX_MEM_Jump         <= 1'b0;
            EX_MEM_pc_plus      <= 32'b0;
            EX_MEM_imm          <= 32'b0;
            EX_MEM_LUI          <= 1'b0;
        end
        else if(!bus_stall) begin
            EX_MEM_Mem_Read     <= ID_EX_Mem_Read;
            EX_MEM_Mem_Write    <= ID_EX_Mem_Write;
            EX_MEM_Mem_To_Reg   <= ID_EX_Mem_To_Reg;
            EX_MEM_funct3       <= ID_EX_funct3;
            EX_MEM_rv2          <= forwardB_data;
            EX_MEM_ALU_result   <= final_ex_result;
            EX_MEM_rd           <= ID_EX_rd;
            EX_MEM_RegWrite     <= ID_EX_RegWrite;
            EX_MEM_Jump         <= ID_EX_Jump;
            EX_MEM_LUI          <= ID_EX_LUI;
            EX_MEM_pc_plus      <= pc_plus4;
            EX_MEM_imm          <= ID_EX_imm;
        end
    end

    //MEM_WB registers (giu nguyen)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            MEM_WB_Mem_To_Reg   <= 1'b0;
            MEM_WB_ALU_result   <= 32'b0;
            MEM_WB_mem_data     <= 32'b0;
            MEM_WB_rd           <= 5'b0;
            MEM_WB_RegWrite     <= 1'b0;
            MEM_WB_Jump         <= 1'b0;
            MEM_WB_pc_plus      <= 32'b0;
            MEM_WB_imm          <= 32'b0;
            MEM_WB_LUI          <= 1'b0;
        end
        else if(!bus_stall) begin
            MEM_WB_rd           <= EX_MEM_rd;
            MEM_WB_Mem_To_Reg   <= EX_MEM_Mem_To_Reg;
            MEM_WB_ALU_result   <= EX_MEM_ALU_result;
            MEM_WB_mem_data     <= mem_data;
            MEM_WB_RegWrite     <= EX_MEM_RegWrite;
            MEM_WB_Jump         <= EX_MEM_Jump;
            MEM_WB_LUI          <= EX_MEM_LUI;
            MEM_WB_pc_plus      <= EX_MEM_pc_plus;
            MEM_WB_imm          <= EX_MEM_imm;
        end
    end

    (* DONT_TOUCH = "yes" *) Register_file RF0 (.clk(clk), .rst_n(rst_n), .en(MEM_WB_RegWrite), .rs1(IF_ID_Instruction[19:15]), .rs2(IF_ID_Instruction[24:20]), .rd(MEM_WB_rd), .wd(write_data), .rv1(operand_1), .rv2(operand_2));
    (* DONT_TOUCH = "yes" *) ALU A0 (.A(ALU_A), .B(ALU_B), .ALUControl(ALUControl), .ALU_result(ALU_result), .ZERO(ZERO));
    (* DONT_TOUCH = "yes" *) M_Unit M0 (.clk(clk), .rs1(ALU_A), .rs2(ALU_B), .funct3(ID_EX_funct3), .m_result(m_out));
    (* DONT_TOUCH = "yes" *) B_Unit B0 (.rs1(ALU_A), .b_op(b_op_sel), .b_result(b_out));
    Immediate_generator IG0 (.Instruction(IF_ID_Instruction), .imm_type(imm_type), .immediate(immediate_raw));
    Sign_extend SE0 (.immediate(immediate_raw), .imm_type(imm_type), .extended_imm(immediate));
    (* DONT_TOUCH = "yes" *) Control_unit CU0 (.opcode(opcode), .ALUOp(ALUOp), .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite), .Branch(Branch), .Jump(Jump), .MemToReg(MemToReg), .ALUSrc1(ALUSrc1), .ALUSrc2(ALUSrc2), .LUI(LUI), .Pcsrc(Pcsrc), .imm_type(imm_type));
    ALU_control AC0 (.ALUOp(ID_EX_ALUOp), .funct3(ID_EX_funct3), .funct7(ID_EX_funct7), .ALU_control(ALUControl));
    (* DONT_TOUCH = "yes" *) PC PC0 (.clk(clk), .rst_n(rst_n), .Stall(Stall), .Branch(ID_EX_Branch), .Pcsrc(ID_EX_Pcsrc), .Jump(ID_EX_Jump), .Branch_taken(Branch_taken), .offset(ID_EX_imm), .rs1_data(forwardA_data), .pc_of_instruction(ID_EX_pc), .pc(pc));
    Branch_prediction BE0 (.funct3(ID_EX_funct3), .ALU_result(ALU_result), .ZERO(ZERO), .Branch_taken(Branch_taken));
    Forwarding_unit FU0 (.ID_EX_rs1(ID_EX_rs1), .ID_EX_rs2(ID_EX_rs2), .EX_MEM_rd(EX_MEM_rd), .EX_MEM_RegWrite(EX_MEM_RegWrite), .MEM_WB_rd(MEM_WB_rd), .MEM_WB_RegWrite(MEM_WB_RegWrite), .ForwardA(ForwardA), .ForwardB(ForwardB));
    Hazard_detection HD0 (.ID_EX_MemRead(ID_EX_Mem_Read), .ID_EX_rd(ID_EX_rd), .IF_ID_rs1(IF_ID_Instruction[19:15]), .IF_ID_rs2(IF_ID_Instruction[24:20]), .Stall(hazard_stall), .Flush(ID_Flush));

endmodule
