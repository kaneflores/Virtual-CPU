`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pennsylvania State University
// Engineer: Kane Flores
// 
// Create Date: 10/21/2023 05:29:22 PM
// Module Name: testbench
// Project Name: First iteration: Lab 3: Stages 1 and 2 (Instruction Fetch, Instruction Decode)
// Current iteration: Lab 4: Stages 3 and 4 (Execution, Memory Access)
// Third iteration: Lab 5: Stage 5 (Writeback)
// Final iteration: Adding stalls to prevent data hazards
//////////////////////////////////////////////////////////////////////////////////

module testbench();
    reg clk;
    wire [31:0] pc;
    wire [31:0] dinstOut;
    wire [3:0] ealuc;
    wire [4:0] edestReg;
    wire [31:0] eqa;
    wire [31:0] eqb;
    wire [31:0] eimm32;
    wire ewreg;
    wire em2reg;
    wire ewmem;
    wire ealuimm;
    wire mwreg;
    wire mm2reg;
    wire mwmem;
    wire [4:0] mdestReg;
    wire [31:0] mr;
    wire [31:0] mqb;
    wire wwreg;
    wire wm2reg;
    wire [4:0] wdestReg;
    wire [31:0] wr;
    wire [31:0] wdo;
    //new lines
    wire [1:0] stall;
    wire [31:0] wbData;
        
    dataPath dataPath_module(clk, pc, dinstOut, ewreg, em2reg, ewmem, ealuc, ealuimm, edestReg, eqa, eqb, eimm32, 
    mwreg, mm2reg, mwmem, mdestReg, mr, mqb, wwreg, wm2reg, wdestReg, wr, wdo, stall, wbData);
    
    initial
    begin
        clk = 0;
    end
    always 
    begin
        #1;
        clk = ~clk;
    end
endmodule
