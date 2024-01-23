`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pennsylvania State University
// Engineer: Kane Flores
// 
// Create Date: 10/21/2023 05:28:16 PM 
// Module Name: src
// Project Name: First iteration: Lab 3: Stages 1 and 2 (Instruction Fetch, Instruction Decode)
// Second iteration: Lab 4: Stages 3 and 4 (Execution, Memory Access)
// Third iteration: Lab 5: Stage 5 (Writeback)
// Final iteration: Adding stalls to prevent data hazards
//////////////////////////////////////////////////////////////////////////////////

module dataPath( //connects all of modules together
    input clk,
    output [31:0] pc,
    output wire [31:0] dinstOut,
    output ewreg,
    output em2reg,
    output ewmem,
    output [3:0] ealuc,
    output ealuimm,
    output [4:0] edestReg,
    output [31:0] eqa,
    output [31:0] eqb,
    output [31:0] eimm32,
    output mwreg,
    output mm2reg,
    output mwmem,
    output [4:0] mdestReg,
    output [31:0] mr,
    output [31:0] mqb,
    output wwreg,
    output wm2reg,
    output [4:0] wdestReg,
    output [31:0] wr,
    output [31:0] wdo,
    //final project
    output [1:0] stall,
    output [31:0] wbData    
);        
        
        wire [31:0] nextPc;
        wire [31:0] instOut;
        wire wreg;
        wire m2reg;
        wire wmem;
        wire [3:0] aluc;
        wire aluimm;
        wire regrt;
        wire [4:0] destReg;
        wire [31:0] qa;
        wire [31:0] qb;
        wire [31:0] imm32;
        wire [31:0] b;
        wire [31:0] r;
        wire [31:0] mdo;
        
        
        
        // lab 3 datapath calls
        program_counter program_counter(clk, nextPc, stall, pc);
        pc_adder pc_adder(pc, nextPc);               
        im im(pc, instOut);                        
        reg_if_id reg_if_id(clk, instOut, stall, dinstOut);
        control_unit control_unit(dinstOut[31:26], dinstOut[5:0], wreg, m2reg, wmem, aluc, aluimm, regrt);
        regrt_mux  regrt_mux(dinstOut[20:16], dinstOut[15:11], regrt, destReg);
        imm_ext imm_ext (dinstOut[15:0], imm32);
        reg_file reg_file(clk, wwreg, wbData, wdestReg, dinstOut[25:21], dinstOut[20:16], qa, qb);
        id_exe_reg id_exe_reg(clk, wreg, m2reg, wmem, aluc, aluimm, destReg, qa, qb, imm32, ewreg, em2reg, ewmem, ealuc, ealuimm, edestReg, eqa, eqb, eimm32);
        
        // lab 4 datapath calls
        alu_mux alumux(eqb, eimm32, ealuimm, b);
        alu alu(eqa, b, ealuc, r);
        exemem_pipel_reg em_pipel_reg(clk, ewreg, em2reg, ewmem, edestReg, r, eqb, mwreg, mm2reg, mwmem, mdestReg, mr, mqb);
        data_mem dm(clk, mr, mqb, mwmem, mdo);
        memwb_pipel_reg mwb_pipel_reg(clk, mwreg, mm2reg, mdestReg, mr, mdo, wwreg, wm2reg, wdestReg, wr, wdo);
        
        // lab 5 datapath calls
        WbMux WBmux(wr, wdo, wm2reg,wbData);
        
        //additional module
        stall stall_m(dinstOut[20:16], dinstOut[25:21], edestReg, mdestReg, stall);
endmodule

module stall(
    input [4:0] rt, 
    input [4:0] rs,
    input [4:0] edestReg,
    input [4:0] mdestReg,
    output reg [1:0] stall
);
    initial begin
        stall =0;
    end
    always @(*) begin
        if(rt == edestReg | rt == mdestReg | rs == edestReg | rs == mdestReg) begin
            stall = 1;
        end
        else begin
            stall = 0;
        end
    end
endmodule

// functionality: at positive edge of clk: pc = nextPc 
module program_counter(input clk, input [31:0] nextPc, input [1:0] stall, output reg[31:0] pc);
    initial begin
        pc = 32'd100;   
    end      
    
    //stalls
    always @(posedge clk) begin 
        if(stall ==1) begin
            pc[31:0] = pc[31:0];
        end
        else begin
            pc <= nextPc;
        end
    end 
endmodule

// functionality: on any signal change: nextPc = pc +32'd4
module pc_adder(input [31:0] pc, output reg[31:0] nextPc);
             
    always @(*) begin
        nextPc = pc + 32'd4;
    end 

endmodule 

// functionality :InstOut is set to value of memory array at position pc
module im(input [31:0] pc, output reg[31:0] instOut);        
    reg[31:0] memory[63:0];

    //initial begin
     //   memory[25] <= 32'b10001100001000100000000000000000;
     //   memory[26] <= 32'b10001100001000110000000000000100;
    //    memory[27] <= 32'b10001100001001000000000000001000;
    //    memory[28] <= 32'b10001100001001010000000000001100;
    //    memory[29] <= 32'b00000000001010100011000000100000;
    //end
    
    initial begin
        memory[25] = { //add $3 $1, $2
            6'b000000,
            5'b00001,
            5'b00010,
            5'b00011,
            5'b00000,
            6'b100000
        };
        memory[26] = { //sub $4, $9, $3
            6'b000000,
            5'b01001,
            5'b00011,
            5'b00100,
            5'b00000,
            6'b100010
        };
        memory[27] = { //or $5 $3, $9
            6'b000000,
            5'b00011,
            5'b01001,
            5'b00101,
            5'b00000,
            6'b100101
        };
        memory[28] = { //xor $6 $3, $9
            6'b000000,
            5'b00011,
            5'b01001,
            5'b00110,
            5'b00000,
            6'b100110
        };
        memory[29] = { //and $7 $3, $9
            6'b000000,
            5'b00011,
            5'b01001,
            5'b00101,
            5'b00000,
            6'b100100
        };
    end
    always @ (*)begin
        instOut = memory[pc[31:2]];
    end
endmodule

// functionality: at positive edge of clk: dinstOut <= InstOut
module reg_if_id(input clk, input[31:0] instOut, input [1:0] stall, output reg[31:0] dinstOut);
    //stalling
    always @(posedge clk) begin 
        if(stall ==1) begin
            dinstOut <= dinstOut;
        end
        else begin
            dinstOut <= instOut;
        end
    end
endmodule

// functionality: outputs are assigned based on values of op and func
module control_unit(
    input[5:0] op, 
    input[5:0] func,
    output reg wreg, 
    output reg m2reg, 
    output reg wmem, 
    output reg[3:0] aluc, 
    output reg aluimm, 
    output reg regrt);
    always @(*) begin
        case(op)
            6'b000000: //r-types
            begin
                case(func)
                    //add
                    6'b100000: begin 
                        wreg = 1'b1;
                        m2reg = 1'b0;
                        wmem = 1'b0;
                        aluc = 4'b0010;
                        aluimm = 1'b0;
                        regrt  = 1'b0;
                    end
                    //sub
                    6'b100010: begin 
                        wreg = 1'b1;
                        m2reg = 1'b0;
                        wmem = 1'b0;
                        aluc = 4'b0110;
                        aluimm = 1'b0;
                        regrt  = 1'b0;
                    end
                    // or
                    6'b100101: begin 
                        wreg = 1'b1;
                        m2reg = 1'b0;
                        wmem = 1'b0;
                        aluc = 4'b0001;
                        aluimm = 1'b0;
                        regrt  = 1'b0;
                    end
                    // xor
                    6'b100110: begin 
                        wreg = 1'b1;
                        m2reg = 1'b0;
                        wmem = 1'b0;
                        aluc = 4'b0011;
                        aluimm = 1'b0;
                        regrt  = 1'b0;
                    end
                    // and
                    6'b100100: begin 
                        wreg = 1'b1;
                        m2reg = 1'b0;
                        wmem = 1'b0;
                        aluc = 4'b0000;
                        aluimm = 1'b0;
                        regrt  = 1'b0;
                    end
                endcase
            end
            //lw
            6'b100011:
                begin
                    wreg = 1'b1;
                    m2reg = 1'b1;
                    wmem = 1'b0;
                    aluc = 4'b0010;
                    aluimm = 1'b1;
                    regrt  = 1'b1;
                end
        endcase 
    end        
endmodule 

// functionality: on any signal change: destReg = rd, if regrt 0, 
module regrt_mux
(input [4:0] rt, 
input [4:0] rd, 
input regrt, 
output reg[4:0] destReg);

    always @(*) begin
        if(regrt == 1) begin
            destReg <= rt;
        end 
        else begin
            destReg <= rd;
        end
    end 
endmodule


// imm32 is set to sign-extended value of imm
module imm_ext(
    input [15:0] imm, 
    output reg [31:0] imm32
);
    always @(*)begin
        imm32 = {{16{imm[15]}}, imm[15:0]};
    end 
endmodule

// functionality: outputs are set to inputs
module id_exe_reg(
    input clk,
    input wreg,             
    input m2reg,            
    input wmem,             
    input [3:0] aluc,       
    input aluimm,           
    input [4:0] destReg,    
    input [31:0] qa,        
    input [31:0] qb,        
    input [31:0] imm32,     
    output reg ewreg,
    output reg em2reg,
    output reg ewmem,
    output reg [3:0] ealuc,
    output reg ealuimm,
    output reg [4:0] edestReg,
    output reg [31:0] eqa,
    output reg [31:0] eqb,
    output reg [31:0] eimm32);
        
    always @(posedge clk) begin
        ewreg <= wreg;
        em2reg <= m2reg;
        ewmem <= wmem;
        ealuc <= aluc;
        ealuimm <= aluimm; 
        edestReg <= destReg;
        eqa <= qa;
        eqb <= qb;
        eimm32 <= imm32;
    end 
endmodule

//Lab 4 implementation:

//functionality: on any signal change
// if ealuimm is 0, b is set to value of eqb
// otherwise, b is set to value of eimm32
module alu_mux(
    input [31:0] eqb, 
    input [31:0] eimm32,
    input ealuimm,
    output reg [31:0] b);
    
    always @(*) begin
        if(ealuimm == 0) begin
            b <= eqb;
        end 
        else begin
            b <= eimm32;
        end
    end
endmodule

//functionality: on any signal change
// the computation of eqa and b through the operation indicated by ealuc
// is performed, with r being set to the result of this calculation
module alu(
    input [31:0] eqa, 
    input [31:0] b,
    input [3:0] ealuc, 
    output reg [31:0] r);
    
    always @(*) begin
        if(ealuc == 4'b0010) begin //add operation
            r <= eqa + b;
        end 
        else if(ealuc == 4'b0110) begin // subtraction operation
            r <= eqa - b;
        end
        else if(ealuc == 4'b0000) begin // and operation
            r <= eqa & b;
        end 
        else if(ealuc == 4'b0001) begin // or operation
            r <= eqa | b;
        end 
    end
endmodule

//functionality: on positive edge of clock
// mwreg set to value of ewreg
// mm2reg set to value of em2reg
// mwmem set to value of ewmem
// mdestReg set to value of edestReg
// mr set to value of r
// mqb set to value of eqb
module exemem_pipel_reg(
    input clk,
    input ewreg,
    input em2reg,
    input ewmem,
    input [4:0] edestReg,
    input [31:0] r,
    input [31:0] eqb,
    output reg mwreg,
    output reg mm2reg,
    output reg mwmem,
    output reg [4:0] mdestReg,
    output reg [31:0] mr,
    output reg [31:0] mqb);
    
    always @(posedge clk) begin
        mwreg <= ewreg;
        mm2reg <= em2reg;
        mwmem <= ewmem;
        mdestReg <= edestReg;
        mr <= r;
        mqb <= eqb;
    end
endmodule 

//functionality:
// on any signal change:
// mdo is set to value of memory array at position mr
// at negative edge of clock:
// if mwmem is 1, memory array at position mr is set to mqb
module data_mem(
    input clk,
    input [31:0] mr,
    input [31:0] mqb,
    input [31:0] mwmem,
    output reg [31:0] mdo);
    reg[31:0] memory[63:0];

    initial begin
        memory[0] <= 'hA00000AA;
        memory[4] <= 'h10000011;
        memory[8] <= 'h20000022;
        memory[12] <= 'h30000033;
        memory[16] <= 'h40000044;
        memory[20] <= 'h50000055;
        memory[24] <= 'h60000066;
        memory[28] <= 'h70000077;
        memory[32] <= 'h80000088;
        memory[36] <= 'h90000099;
    end
    always @ (*)begin
        mdo = memory[mr[31:2]];
    end
    always @(negedge clk) begin
        if(mwmem == 1) begin
            memory[mr[31:2]] = mqb;
        end 
    end
endmodule

//functionality: on posedge clk
// wwreg set to value of mwreg
// wm2reg set to value of mm2reg
// wdestReg set to value of mdestReg
// wr set to value of mr
// wdo set to value of mdo
module memwb_pipel_reg(
    input clk,
    input mwreg,
    input mm2reg,
    input [4:0] mdestReg,
    input [31:0] mr,
    input [31:0] mdo,
    output reg wwreg,
    output reg wm2reg,
    output reg [4:0] wdestReg,
    output reg [31:0] wr,
    output reg [31:0] wdo);
    
    always @(posedge clk) begin
        wwreg <= mwreg;
        wm2reg <= mm2reg;
        wdestReg <= mdestReg;
        wr <= mr;
        wdo <= mdo;
    end
endmodule

//Lab 5 implementation:

//functionality: on any signal change
// if wm2reg is 0, wbData is set to value of wr
// otherwise, wbData is set to value of wdo
module WbMux(
    input [31:0] wr,
    input [31:0] wdo,
    input wm2reg,
    output reg [31:0] wbData
);

    always @(*) begin
        if(wm2reg == 1) begin
            wbData <= wdo;
        end
        else if(wm2reg == 0) begin
            wbData <= wr;
        end
    end
endmodule

// functionality: on any signal change, qa =rs, qb = rt
module reg_file // regfile is heavily changed
(
    input clk,
    input wwreg,
    input [31:0] wbData,
    input [4:0] wdestReg,
    //
    input [4:0] rs, 
    input [4:0] rt, 
    output reg[31:0] qa, 
    output reg[31:0] qb
 );
    reg[31:0] RegFile[31:0];

    initial begin
        RegFile[0] <= 'h00000000;
        RegFile[1] <= 'hA00000AA;
        RegFile[2] <= 'h10000011;
        RegFile[3] <= 'h20000022;
        RegFile[4] <= 'h30000033;
        RegFile[5] <= 'h40000044;
        RegFile[6] <= 'h50000055;
        RegFile[7] <= 'h60000066;
        RegFile[8] <= 'h70000077;
        RegFile[9] <= 'h80000088;
        RegFile[10] <= 'h90000099;
    end
    
    
    //
    always @(*) begin
        qa = RegFile[rs];
        qb = RegFile[rt];
    end
    always @(negedge clk) begin
        if(wwreg ==1) begin
            RegFile[wdestReg] <= wbData;
        end
    end
endmodule 
