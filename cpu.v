`timescale 1ns / 1ps
`define COMMAND_SIZE 33
`define CODE_SIZE 4
`define PROGRAM_SIZE 1024
`define DATA_SIZE 8192
`define LITERAL_SIZE 16
`define ADDR_WIDTH 13

`define NOP 0
`define INCR 1
`define MULT 2
`define LOAD_A 3
`define LOAD_B 4
`define LOAD_C 5
`define WRITE_A 6
`define WRITE_MEM 7
`define WRITE_MEM_C 8
`define JGZ 9
`define JUMP 10
`define JNEQ 11

/*
33 BIT

NOP, INCR           |CODE 4BIT| |
LOAD_A              |CODE 4BIT|ADDRESS 12BIT| |
LOAD_B              |CODE 4BIT|ADDRESS 12BIT| |
WRITE_A             |CODE 4BIT|ADDRESS 12BIT| |
WRITE               |CODE 4BIT|ADDRESS 12BIT|LITERAL 16BIT|
JGZ, JUMP           |CODE 4BIT|ADDRESS 12BIT| |
*/


module cpu(
    input clk, reset
    );
    
reg[`COMMAND_SIZE-1:0] com1,com2,com3,com4;
reg[`ADDR_WIDTH-1:0] pc;
reg[`COMMAND_SIZE-1:0] programs [0:`PROGRAM_SIZE-1];
reg[`LITERAL_SIZE-1:0] data [0:`DATA_SIZE-1];
reg[`LITERAL_SIZE-1:0] reg_A, reg_B, reg_C;
wire gz, eq;

wire[`CODE_SIZE-1:0] op2 = com2[`COMMAND_SIZE-1-:`CODE_SIZE];
wire[`CODE_SIZE-1:0] op3 = com3[`COMMAND_SIZE-1-:`CODE_SIZE];
wire[`CODE_SIZE-1:0] op4 = com4[`COMMAND_SIZE-1-:`CODE_SIZE];
wire[`ADDR_WIDTH-1:0] addr_to_read = com2[`COMMAND_SIZE-1-`CODE_SIZE-:`ADDR_WIDTH];
wire[`ADDR_WIDTH-1:0] addr_to_write = com4[`COMMAND_SIZE-1-`CODE_SIZE-:`ADDR_WIDTH];
wire[`ADDR_WIDTH-1:0] addr_to_jump = com4[`COMMAND_SIZE-1-`CODE_SIZE-:`ADDR_WIDTH];
wire[`LITERAL_SIZE-1:0] literal = com4[`COMMAND_SIZE-1-`CODE_SIZE-`ADDR_WIDTH-:`LITERAL_SIZE];

assign gz = reg_A>reg_B;
assign eq = reg_A==reg_B;

integer i;
initial 
begin
    pc = 0;
    $readmemb("Program.mem", programs);
    for(i = 0; i < `DATA_SIZE; i = i + 1)
        data[i] = `LITERAL_SIZE'b0;
    com1 = 0;
    com2 = 0;
    com3 = 0;
    com4 = 0;
    reg_A = 0;
    reg_B = 0;
    reg_C = 0;
end

//clock 2
always@(posedge clk)begin
    case(op2)
        `LOAD_A:reg_A<=data[addr_to_read];
        `LOAD_B:reg_B<=data[addr_to_read];
        `LOAD_C:reg_C<=data[addr_to_read];
    endcase
end

//clock 3
always@(posedge clk)begin
    case(op3)
        `INCR:reg_A <= reg_A+1;
        `MULT:reg_A <= reg_A*reg_B;
    endcase
end

//clock 4
always@(posedge clk)begin
    case(op4)
        `WRITE_A:data[addr_to_write] <= reg_A;
        `WRITE_MEM:data[addr_to_write] <= literal;
    endcase
end

always@(posedge clk)begin
    com1<=programs[pc];
    com2<=com1;
    com3<=com2;
    com4<=com3;
end
    
always@(posedge clk)begin
    case(op4)
        `JUMP:pc <= addr_to_jump;
        `JGZ:begin
            if(gz)
                pc <= addr_to_jump;
         end
         `JNEQ:begin
            if(!eq)
                pc <= addr_to_jump;
         end
        default:pc <= pc+1;
    endcase
end
endmodule
