module tb_computer();
	reg clk,reset;
	wire [15:0] address_instruction,data_out_instruction,
		data_in,data_out,address_data,ALU_result;
	wire MemRd,MemWr;
	wire [3:0] state;
	wire [2:0] ALUop;
	wire [7:0] data_out2;
	always #10ns clk = ~clk;
	initial begin 
			clk = 1;
			reset = 1;
			#1ns
			reset =0;
			#1ns
			reset = 1;
			$monitor("instruction : 0x%x\n",data_out_instruction);
			#80000ns $finish;
		end
	
	computer dut (
		.clk(clk),
		.address_instruction(address_instruction),
		.data_out_instruction(data_out_instruction),
		.data_in(data_in),
		.data_out(data_out),
		.data_out2(data_out2),
		.address_data(address_data),
		.MemRd(MemRd),
		.MemWr(MemWr),
		.reset(reset),
		.state(state),
		.ALU_result(ALU_result),
		.ALUop(ALUop)
		);
	
endmodule

module reg_file(
	input clk,
	input RegWrite,
	input [2:0] Rs1, Rs2, RW,
	input [15:0] w_bus,
	output reg [15:0] BusA, BusB
	);
	reg [15:0] regarr [0:7] = '{16'h0000, 16'h3, 16'h1, 16'h12, 16'd100, 
		16'h7, 16'h4, 16'h7};  // R0 is initialized to 0
	
	always @(*) begin
			BusA = regarr[Rs1];
			BusB = regarr[Rs2];
		end
	
	always @(posedge clk) begin
			if (RegWrite && RW != 3'b000)  // Ensure R0 (index 0) is not written to
				regarr[RW] <= w_bus;
		end
	
	// Ensure R0 is always zero
	always @(posedge clk or negedge clk) begin
			regarr[0] <= 16'h0000;
		end
endmodule	 




module mux2x1 #(
	parameter WIDTH = 16
	)      
	
	(input [WIDTH-1:0] a, b,     
	input select,  
	output [WIDTH-1:0] out    
	);
	
	
	assign out = select ? b : a;
	
endmodule 



module dataMemory (
	output reg [15:0] fullDataOut,  // 16-bit output from memory
	output reg [7:0] HalfDataOut,   // Lower 8-bit output from memory
	input clk,                      // Clock signal
	input [15:0] address,           // 16-bit input memory address to read from or write to
	input [15:0] dataIn,            // 16-bit input memory data to be written to the memory
	input memRead,                  // Control signal to enable reading from the memory
	input memWrite                  // Control signal to enable writing to the memory
	);
	
	reg [7:0] mem [0:511]; // Byte-addressable memory array (2 bytes per 16-bit word, hence 512 locations)
	
	initial begin
			// Initialize Values (example initialization for 8 locations)
			mem[0] = 8'h00; mem[1] = 8'h08; // 16'h0008
			mem[2] = 8'h00; mem[3] = 8'h2C; // 16'h002C
			mem[4] = 8'h01; mem[5] = 8'hB0; // 16'h01B0
			mem[6] = 8'hFF; mem[7] = 8'h86; // 16'hFF86
			mem[8] = 8'hFF; mem[9] = 8'h38; // 16'hFF38
			mem[10] = 8'hFF; mem[11] = 8'hFE; // 16'hFFFE
			mem[12] = 8'h00; mem[13] = 8'hD3; // 16'h00D3
			mem[14] = 8'h00; mem[15] = 8'h0C; // 16'h000C
		end
	
	// When the control signal memWrite is 1, store the dataIn at the given address:
	always @(posedge clk) begin
			if (memWrite) begin
					mem[address] <= dataIn[7:0];       // Store the lower byte
					mem[address + 1] <= dataIn[15:8];  // Store the upper byte
				end
		end
	
	// When the control signal memRead is 1, read the data from the given address and return it as fullDataOut and halfDataOut:
	always @* begin
			if (memRead) begin
					fullDataOut = {mem[address + 1], mem[address]}; // Combine upper and lower bytes
					HalfDataOut = mem[address];                     // Extract the lower 8 bits
			end else begin
					fullDataOut = 16'b0;
					HalfDataOut = 8'b0;
				end
		end
	
endmodule




module instructionMemory #(
	parameter WIDTH = 16
	) (
	output reg [15:0] data,    // Output will be 16 bits, consisting of two bytes
	input [WIDTH-1:0] address   // Address input
	);
	
	// Memory array to store bytes (8 bits each)
	reg [7:0] mem [0: 32]; // Define memory with 8-bit width for byte addressing
	
	// Initial block to initialize memory with some values
	
	initial begin
			// Storing instructions in little-endian format
			mem[0] = 8'h40; mem[1] = 8'h02; // and r1 , r1 , r0
			mem[2] = 8'h02; mem[3] = 8'h99; // bltz r1
			mem[4] = 8'h04; mem[5] = 8'ha9; // beqz rq
			mem[6] = 8'h22; mem[7] = 8'h31; // addi r1 , r1 , 2
			mem[8] = 8'h07; mem[9] = 8'hc0; // jmp 	  
			mem[10] = 8'h24; mem[11] = 8'h31; // addi r1 , r1 , 4
			mem[12] = 8'h07; mem[13] = 8'hc0; // jmp 
		end
	
	
	// Combine two consecutive bytes to form a 16-bit word in little-endian format
	assign data = {mem[address + 1], mem[address]};
	
endmodule










module mux4x1  #(
	parameter WIDTH = 16
	) 
	
	(input [WIDTH-1:0] a, b, c, d,       
	input [1:0] s,     
	
	output reg [WIDTH-1:0] out
	);
	
	
	always @* begin 
			
			case (s) 
				2'b00 : out = a;
				2'b01 : out = b;
				2'b10 : out = c;
				2'b11 : out = d;
			endcase
		end
	
	
endmodule      


module flipflop (  
	
	output reg [15:0] out,
	input clk,
	input writeEn,
	input [15:0] in,
	input reset
	);
	always @(posedge clk or negedge reset) begin
			
			if (!reset)
				out <= 0;
			
			else if (writeEn)
				out <= in; 
		end
	
endmodule





module dataPath(input PCwrite , IRwrite ,
	RBSrc ,  RegWri , WrSel, dataInSrc,AddrSrc,
	ALUSrcB ,MDRSrc,ExSrc,WBData,clk,reset ,
	input [1:0]	  RASrc , RWSrc,PCSrc,ALUSrcA ,ExOP,ExOP2,
	input [2:0] ALUop,
	input [15:0] data_out_instruction, data_out,
	input [7:0] data_out2,
	output [3:0] opcode, 
	output  mode,
	output [15:0] address_data, address_instruction, data_in,
	output z, n, v,
	output [15:0] ALU_result
	);	
	
	wire [15:0] TMPpc;
	wire [2:0] Rs1i,Rs1r,Rss, Rs2, Rdr,Rdi,RsV;  	  
	
	assign TMPpc = address_instruction;		
	
	wire [15:0] instruction, BUS1, BUS2, B_operand, A_operand, srcA,srcB,  sExtended,mdrIn,
		extended_immediate1,extended_immediate2, ALU_operand1, ALU_operand2,
		PCtype, ALU_result_buffer,dataOut1,MDRin,MDRout,wbin,wbin2,jumpTargetAddress,writeInput,wbInput,imExtended; 
	wire [7:0]	choseEx;			
	wire [2:0] RS1in ,RS2in , RWin 	;
	assign opcode = instruction[15:12];
	assign mode = instruction[11];
	assign Rdr = instruction[11:9];	 	
	assign RsV = instruction[11:9];	 
	assign Rdi = instruction[10:8];
	assign Rs1r = instruction[8:6];
	assign Rs2 = instruction[5:3];	
	assign Rs1i = instruction[7:5];	 
	wire [4:0] immediateI;	 
	wire [7:0] immediateS;
	assign immediateI = instruction[4:0]; 
	assign immediateS = instruction[8:1];	  
	wire [12:0]offsetx2;  
	wire [11:0]offset;
	assign offset = instruction[11:0];
	assign offsetx2 ={offset,1'b0};
	assign jumpTargetAddress={address_instruction[15:13], offsetx2};   
	
	flipflop IR (.out(instruction), .clk(clk), .writeEn(IRwrite), .in(data_out_instruction), .reset(1'b1));	  
	
	flipflop A (.out(A_operand), .clk(clk), .writeEn(1'b1), .in(BUS1), .reset(1'b1));
	
	flipflop B (.out(B_operand), .clk(clk), .writeEn(1'b1), .in(BUS2), .reset(1'b1)); 	
	
	flipflop pc(.out(address_instruction) , .clk(clk), .writeEn(PCwrite), .in(PCtype) , .reset(reset)); 
	
	flipflop ALUout(.in(ALU_result), .clk(clk), .writeEn(1'b1), .out(ALU_result_buffer), .reset(1'b1));
	
	flipflop MDR(.out(MDRout), .clk(clk), .writeEn(1'b1), .in(mdrIn), .reset(1'b1));		
	
	mux4x1 #(3) RAsrc_mux (.a(RsV), .b(Rs1r), .c(Rs1i), .d(3'b111), .s(RASrc), .out(RS1in));	  
	
	mux2x1 #(3) RBsrc_mux (.a(Rdi), .b(Rs2), .select(RBSrc), .out(RS2in));	 
	
	mux4x1 #(3) Rwsrc_mux (.a(Rdr), .b(Rdi), .c(3'b111), .d(3'b0), .s(RWSrc), .out(RWin));  	 
	
	mux2x1 wbMux (.a(ALU_result_buffer), .b(MDRout), .select(WBData), .out(wbInput));
	
	mux2x1  Wrsrc_mux (.a(wbInput), .b(TMPpc), .select(WrSel), .out(writeInput));		 
	
	
	mux4x1  ALUsrc1_mux (.a(16'b0), .b(TMPpc), .c(A_operand), .d(16'b0), .s(ALUSrcA), .out(ALU_operand1));  	 
	
	extender #(5) ex1 (
		.in(immediateI),
		.ExOP(ExOP),
		.out(imExtended)
		);	  
	
	mux2x1 #(8) ex2Src (.a(immediateS), .b(data_out2), .select(ExSrc), .out(choseEx));
	
	extender ex2 (
		.in(choseEx),
		.ExOP(ExOP2),
		.out(sExtended)
		);
	
	//mux4x1 ALUsrc2_mux(.a(16'b0), .b(B_operand), .c(imExtended), .d(16'b0), .s(ALUSrcB), .out(ALU_operand2));	  
	mux2x1 ALUsrc2_mux (.a(B_operand), .b(imExtended), .select(ALUSrcB), .out(ALU_operand2));  
	
	mux2x1 dataIn_mux (.a(sExtended), .b(B_operand), .select(dataInSrc), .out(data_in));  
	
	mux2x1 add_mux (.a(ALU_result_buffer), .b(A_operand), .select(AddrSrc), .out(address_data));	
	
	mux2x1 MDR_mux (.a(data_out), .b(sExtended), .select(MDRSrc), .out(mdrIn));	 
	
	mux4x1 pcMux(.a(jumpTargetAddress), .b(ALU_result), .c(ALU_result_buffer), .d(BUS1), .s(PCSrc), .out(PCtype));
	
	
	
	
	reg_file file (
		
		.clk(clk),
		.RegWrite(RegWri),
		.Rs1(RS1in), .Rs2(RS2in), .RW(RWin),
		.w_bus(writeInput), 
		.BusA(BUS1), .BusB(BUS2)
		);		
	
	ALU alu(
		
		.ALUop(ALUop), 
		.A(ALU_operand1), 
		.B(ALU_operand2), 
		.result(ALU_result) ,
		.Z(z), 
		.V(v), 
		.N(n)
		);	
	
	
	
endmodule


module extender #(
	parameter IN_WIDTH = 8 // Default input width
	)(
	input [IN_WIDTH-1:0] in,
	input [1:0] ExOP,
	output reg [15:0] out //  output width of 16 bits
	); 
	
	always @(*) begin
			if (ExOP == 2'b01) begin // Zero Extension
					out = { {(16-IN_WIDTH){1'b0}}, in };
			end else if (ExOP == 2'b10) begin // Sign Extension
					out = { {(16-IN_WIDTH){in[IN_WIDTH-1]}}, in };
			end else begin // No Extension Needed
					out = { {(16-IN_WIDTH){1'b0}}, in };
				end
		end
endmodule



//ALU Module:
module ALU(
	input [2:0] ALUop,               // 3-bit operation code input
	input signed [15:0] A, B,       // Two signed 16-bit inputs A and B
	output reg signed [15:0] result, // Signed 16-bit result to handle potential overflow
	output Z,                       // Zero flag: indicates if the result is zero
	output V,                       // Overflow flag: indicates if overflow occurred
	output N                        // Negative flag: indicates if the result is negative
	);
	reg [1:0] carry;
	// Calculate Zero flag: set to 1 if result is zero
	assign Z = (result == 0);
	
	// Calculate Negative flag: set to the most significant bit (MSB) of the result
	// Note: this is a bug in the code because result is 17 bits and it should use result[16]
	assign N = result[15];  // This should be result[16] for correct operation
	
	// Overflow flag: indicates signed overflow based on the carry from the MSB addition
	assign V = carry[1] ^ carry[0]; // carry needs to be declared as reg here, also carry isn't used in this declaration
	
	// Always block to perform the operation based on ALUop
	always @(*) begin
			case(ALUop)
				3'b000: result = A + 2;
				// Case 3'b000: Add 2 to the input A
				// This is an increment operation, increasing A by 2
				
				3'b001: result = A & B;
				// Case 3'b001: Perform bitwise AND between A and B
				// Each bit of result is the AND of the corresponding bits of A and B
				
				3'b010: begin
						// Case 3'b010: Perform addition between A and B with carry handling
						// First 15 bits addition with capture of carry-out
						{carry[0], result[14:0]} = A[14:0] + B[14:0];
						// Add the 15th bit (MSB) along with the carry from the lower bits
						{carry[1], result[15]} = A[15] + B[15] + carry[0];
						// The result is a 16-bit addition with potential overflow detection
						
					end
				
				3'b011: result = A - B;
				// Case 3'b011: Perform subtraction of B from A
				// Each bit of result is the subtraction of the corresponding bits of A and B
				
				
				3'b100: result = B - A;
				// Case3'b100: Perform subtraction of A from B
				// Each bit of result is the subtraction of the corresponding bits of A and B
				
				
				
			endcase
		end
endmodule





//ALUControl Module:

module ALUControl(
	input [3:0] opcode,        //<-- 4-bit opcode from the instruction
	input [2:0] ALUctrl,       //<-- 3 bit from the  main cntrl
	output reg [2:0] ALUop    //<-- 3-bits ALU operation code(8 diff operation)
	
	);
	
	parameter
		INC = 3'b000,
		AND = 3'b001,
		ADD = 3'b010,
		SUB = 3'b011,
		RSUB = 3'b100;
	
	
	//the ADD opeartions (AddI. Add) will be for these opCode :
	//[0001_No2, 0011_No4, 0101_No6, 0110_No7, 0111_No9].
	
	//the AND opeartions (AndI. And) will be for these opCode : [0000_No1, 0100_No5].
	
	// The SUB operations will be for other opcodes (it will affect the flags).
	
	
	
	// based on the opCode We will chose the opeartion that the Alu will do it:
	
	always @(*) begin
			
			case (ALUctrl)
				
				ADD,INC,RSUB : ALUop = ALUctrl;  //<-- based on the signal from the Main Control Unit.
				
				3'b111: begin
						
						case (opcode)
							4'b0001, 4'b0011, 4'b0101, 4'b0110, 4'b0111: ALUop = ADD; //<-- ADD.
							4'b0000, 4'b0100: ALUop = AND; //<-- AND.
							4'b0010 :ALUop= SUB; //<-- SUB.
						endcase
					end
			endcase
			
		end
endmodule

module PCControlUnit(
	
	input [3:0] opcode,
	input Z,V,N,
	input [3:0] state,
	input PCForcedWrite,
	output PCwrite	
	); 
	
	parameter BGT = 4'b1000,BLT = 4'b1001,
		BEQ = 4'b1010,BNE = 4'b1011;
	
	wire branch;
	
	
	assign branch = ((opcode == BNE) && !Z) || 
		((opcode == BEQ) && Z) || 
		((opcode ==BGT) && (!Z && !(N ^ V))) || 
		((opcode == BLT) && (N ^ V));
	
	
	assign PCwrite =  ((state == 4) && branch) || PCForcedWrite;	
endmodule









module MainControlUnit(
	
	input clk,reset,
	input [3:0] opcode,
	input m,
	//output reg PCwrite,
	output reg PCForcedWrite,IRwrite,RBSrc,
	RegWrite,Wrsel,ALUSrcB,ExSrc,
	DataInSrc,AddrSrc,MemRd,MemWr,
	MDRSrc,WBdata,
	
	output reg [1:0] RASrc,RWSrc,
	ALUSrcA,PCSrc,ExOP,ExOP2,
	
	output reg [3:0] state,
	output reg [2:0] ALUctrl
	);
	
	parameter 
		AND = 4'b0000,
		ADD = 4'b0001,
		SUB = 4'b0010,
		ADDI = 4'b0011,
		ANDI = 4'b0100,
		LW = 4'b0101,
		LBu = 4'b0110,
		LBs = 4'b0110,
		SW = 4'b0111,
		BGT = 4'b1000,
		BGTZ = 4'b1000,
		BLT = 4'b1001,
		BLTZ = 4'b1001,
		BEQ = 4'b1010,
		BEQZ = 4'b1010,
		BNE = 4'b1011,
		BNEZ = 4'b1011,
		JMP = 4'b1100,
		CALL = 4'b1101,
		RET = 4'b1110,
		Sv = 4'b1111;	
	
	parameter IF          = 0,  // Instruction Fetch
		ID          = 1,  // Instruction Decode and Branch Address Calculation
		CALL_ID_R7WB  = 2,  // Call Instruction Decode and Write Back to R7
		RET_ID      = 3,  // Return Instruction Decode
		BRANCH_EXEC = 4,  // Branch Execution
		SV_MEM_WB   = 5,  // Store to Memory and Write Back
		ALU_ADDR_CALC = 6, // ALU Address Calculation
		ALU_EXEC_ANDI_ADDI  = 7,  // First ALU Execution
		ALU_EXEC_R_TYPE  = 8,  // Second ALU Execution
		MEM_READ_LW = 9,  // Memory Read for Load Word
		MEM_READ_LBU = 10, // Memory Read for Load Byte Unsigned
		MEM_READ_LBS = 11, // Memory Read for Load Byte Signed
		MEM_SW = 12, // Memory Write for Store Word
		LOAD_WB     = 13,  // Load Write Back
		ALU_RES_WB          = 14;  // Write Back
	
	reg jmp;
	reg [1:0] ra;
	reg rb;
	reg [1:0] rw;	
	reg [1:0] pc;
	reg call;
	always @* begin	  
			jmp=0;
			ra=0;
			rb=0;
			rw=0;	 
			pc=2'b00;
			call = (opcode == CALL);
			case(opcode)
				JMP,CALL : begin
						jmp = 1;
					end
				AND,ADD,SUB : begin
						rb = 1;
						ra = 2'b01;
						rw = 2'b00;
					end	
				//	CALL: begin
				//		Wrsel=1;  
				//		rw = 2'b11;	 
				//		ExOP=2'b10;	 
				//		RegWrite=1;
				//	end
				Sv : begin
						ra = 2'b00;
					end
				
				RET : begin	  
						jmp = 1;
						ra = 2'b11;	  
						pc=2'b11;
						
						
					end	
				
				default : begin
						rb = 0;
						jmp = 0;
						ra = 2'b10;
						rw = 2'b01;
					end
			endcase
		end
	
	always @(posedge clk or negedge reset) begin
			
			if (!reset)
				state <= IF;
			else begin
					case(state)
						
						
						IF : begin
								state <= 1;
							end
						
						ID : begin
								case(opcode)
									SUB,ADD,AND : state <= 8;
									ADDI,ANDI : state <= 7;
									BGT,BLT,BNE,BEQ,
										BGTZ,BLTZ,BNEZ,BEQZ : state <= 4;
									LW,SW,LBu,LBs : state <= 6;
									Sv : state <= 5;
									JMP,CALL,RET : state <=0;
								endcase
							end
						ALU_ADDR_CALC : begin
								
								case(opcode)
									LBu : begin
											case(m)
												1: state<= 11;
												0: state<= 10;
											endcase	
										end
									LW : state <= 9;
									SW : state <= 12;
								endcase	
								
								
							end
						MEM_READ_LW,MEM_READ_LBU,MEM_READ_LBS : begin
								state <= 13;
							end
						ALU_EXEC_R_TYPE,ALU_EXEC_ANDI_ADDI: begin 
								state <= 14;
							end
						LOAD_WB,ALU_RES_WB,
							SV_MEM_WB,CALL_ID_R7WB,
							RET_ID,BRANCH_EXEC,MEM_SW: begin
								state <= 0;
							end				
					endcase
				end
		end
	
	always @(*) begin
			PCForcedWrite = 0;
			IRwrite = 0;
			RBSrc = 0;
			RegWrite = 0;
			Wrsel = 0;
			ALUSrcA = 0;
			ALUctrl = 0;
			ExSrc = 0;
			ExOP2 = 0;
			DataInSrc = 0;
			AddrSrc = 0;
			MemRd = 0;
			MemWr = 0;
			MDRSrc = 0;
			WBdata = 0;
			ExOP = 0;
			RASrc = 0;
			RWSrc = 0;
			ALUSrcB = 0;
			PCSrc = 0;
			AddrSrc = 0;
			case(state)
				IF : begin
						PCForcedWrite = 1;
						ALUSrcA = 1;
						ALUctrl = 3'b000; //INC
						PCSrc = 2'b01;		
						IRwrite=1;	 
						//PCwrite = 1;
						
					end
				ID : begin
						ExOP = 2'b10;
						ALUSrcA = 2'b01;
						ALUSrcB = 1;
						PCSrc = pc;
						PCForcedWrite = jmp; 
						ALUctrl = 3'b010;//ADD
						RBSrc = rb;
						RASrc = ra;
						ExSrc = 0;
						ExOP2 = 2'b10; 
						RegWrite = call;
						RWSrc = 2'b10;
						Wrsel = 1;
					end
				//	CALL_ID_R7WB : begin
				//	ExOP = 2'b10;
				//	PCSrc = 2'b00;
				//	PCForcedWrite = jmp;
				//	RegWrite = 1;
				//	RWSrc = 2'b11;
				//	Wrsel = 1;
				//end
				//RET_ID : begin
				//PCForcedWrite = jmp;
				//PCSrc = 2'b11;
				//RASrc = 2'b11;
				//end
				BRANCH_EXEC : begin
						PCSrc =  2'b10;
						ALUctrl = 3'b100;
						ALUSrcA  = {~m,1'b0};
						ALUSrcB = 0;
					end
				SV_MEM_WB : begin
						DataInSrc = 0;
						ExOP2 = 2'b10;
						MemRd = 0;
						MemWr = 1;
						AddrSrc =  1;
					end
				ALU_ADDR_CALC : begin 
						
						ALUSrcA = 2'b10;
						ALUSrcB = 2'b01;
						ALUctrl = 3'b111;
						ExOP=2'b10;
						
					end
				ALU_EXEC_ANDI_ADDI : begin
						ALUSrcA = 2'b10;
						ALUSrcB = 1;
						ExOP = 2'b10;
						ALUctrl = 3'b111;
					end
				ALU_EXEC_R_TYPE : begin
						ALUctrl = 3'b111;
						ALUSrcA = 2'b10;
						ALUSrcB = 0;
					end
				MEM_READ_LW : begin
						MemRd = 1;
						MemWr = 0;
						AddrSrc = 0;
						MDRSrc = 0;
					end			   
				MEM_READ_LBU : begin
						MemRd = 1;
						MemWr = 0;
						AddrSrc = 0;
						MDRSrc = 1;
						ExSrc = 1;
						ExOP2 = 2'b01;
					end
				MEM_READ_LBS : begin
						MemRd = 1;
						MemWr = 0;
						AddrSrc = 0;
						MDRSrc = 1;
						ExSrc = 1;
						ExOP2 = 2'b10;
					end
				MEM_SW : begin
						MemRd = 0;
						MemWr = 1;
						DataInSrc = 1;
						AddrSrc = 0;
					end
				LOAD_WB : begin
						WBdata = 1;
						Wrsel = 0;
						RegWrite = 1;
						RWSrc = 2'b01;
					end
				ALU_RES_WB : begin
						WBdata = 0;
						RegWrite = 1;
						Wrsel = 0;
						RWSrc = rw;
					end
				
			endcase
		end
endmodule



module CPU(
	
	input [15:0] data_out_instruction,data_out,
	input [7:0] data_out2,
	input clk,reset,
	output [15:0] address_data,address_instruction,data_in,
	output [15:0] ALU_result,
	output MemRd,MemWr,
	output [3:0] state,
	output [2:0] ALUop
	);
	
	wire [3:0] opcode;
	wire mode;
	wire z,n,v;
	wire RBSrc ,  RegWri , WrSel, dataInSrc,AddrSrc,
		ALUSrcB ,MDRSrc,ExSrc,WBData,
		PCForcedWrite,PCwrite,IRwrite;
	wire [1:0] RASrc,RWSrc,ALUSrcA,PCSrc,ExOP2,ExOP;  
	wire [2:0] ALUctrl; 
	
	dataPath dp (
		.PCwrite(PCwrite), 
		.IRwrite(IRwrite),
		.RBSrc(RBSrc),  
		.RegWri(RegWri), 
		.WrSel(WrSel),
		.dataInSrc(dataInSrc),
		.AddrSrc(AddrSrc),
		.ALUSrcB(ALUSrcB), 
		.MDRSrc(MDRSrc),
		.ExSrc(ExSrc),
		.WBData(WBData),
		.clk(clk),
		.reset(reset),
		.RASrc(RASrc), 
		.RWSrc(RWSrc),
		.PCSrc(PCSrc),
		.ALUSrcA(ALUSrcA),
		.ALUop(ALUop),
		.ExOP(ExOP),
		.ExOP2(ExOP2),
		.data_out_instruction(data_out_instruction),
		.data_out(data_out),
		.data_out2(data_out2),
		.opcode(opcode),
		.mode(mode),
		.address_data(address_data),
		.address_instruction(address_instruction),
		.data_in(data_in),
		.z(z),
		.n(n),
		.v(v),
		.ALU_result(ALU_result)
		);
	
	MainControlUnit mcu(
		.clk(clk),
		.reset(reset),
		.opcode(opcode),
		.m(mode),
		.PCForcedWrite(PCForcedWrite),
		//.PCwrite(PCwrite),
		.IRwrite(IRwrite),
		.RBSrc(RBSrc),
		.RegWrite(RegWri),
		.Wrsel(WrSel),
		.ALUSrcB(ALUSrcB),
		.ExSrc(ExSrc),
		.ExOP2(ExOP2),
		.DataInSrc(dataInSrc),
		.AddrSrc(AddrSrc),
		.MemRd(MemRd),
		.MemWr(MemWr),
		.MDRSrc(MDRSrc),
		.WBdata(WBData),
		.ExOP(ExOP),
		.RASrc(RASrc),
		.RWSrc(RWSrc),
		.ALUSrcA(ALUSrcA),
		.PCSrc(PCSrc),
		.state(state),
		.ALUctrl(ALUctrl)
		);
	
	ALUControl alu_ctrl_unit (
		.opcode(opcode),
		.ALUctrl(ALUctrl),
		.ALUop(ALUop)
		);
	
	// PC Control unit instance
	PCControlUnit pc_ctrl_unit (
		.opcode(opcode),
		.Z(z),
		.V(v),
		.N(n),
		.state(state),
		.PCForcedWrite(PCForcedWrite),
		.PCwrite(PCwrite)
		);  
endmodule	



module computer (
	input clk,reset,
	output [15:0] address_instruction,data_out_instruction,
	data_in,data_out,address_data,
	output [7:0] data_out2,
	output MemRd,MemWr,
	output [3:0] state,
	output [15:0] ALU_result,
	output [2:0] ALUop
	);
	
	instructionMemory inst_mem(
		
		.data(data_out_instruction),
		.address(address_instruction)
		);
	
	dataMemory data_mem(
		
		.fullDataOut(data_out),
		.HalfDataOut(data_out2),
		.clk(clk),
		.address(address_data),
		.dataIn(data_in),
		.memRead(MemRd),
		.memWrite(MemWr)
		
		);
	
	CPU cpu (
		.clk(clk),  // Connecting clock signal
		.reset(reset),  // Connecting reset signal
		.data_out_instruction(data_out_instruction),  // Instruction data output
		.data_out(data_out),  // Data output from CPU
		.data_out2(data_out2),  // Data output 2
		.address_data(address_data),  // Address for data
		.address_instruction(address_instruction),  // Instruction address
		.data_in(data_in),  // Data input to CPU
		.ALU_result(ALU_result),  // Result from ALU
		.MemRd(MemRd),  // Memory read signal
		.MemWr(MemWr),  // Memory write signal
		.state(state),  // Current state of the CPU
		.ALUop(ALUop)  // ALU operation code
		);
	
endmodule	 



module tb_computer3();
	
	// Testbench signals
	reg clk, reset;
	wire [15:0] address_instruction, data_out_instruction, data_in, data_out, address_data, ALU_result;
	wire [7:0] data_out2;
	wire MemRd, MemWr;
	wire [3:0] state;
	wire [2:0] ALUop;
	wire [3:0] opcode; // Add opcode signal to monitor
	
	// Extract opcode from instruction
	assign opcode = data_out_instruction[15:12];
	
	// Instantiate the computer module
	computer dut (
		.clk(clk),
		.reset(reset),
		.address_instruction(address_instruction),
		.data_out_instruction(data_out_instruction),
		.data_in(data_in),
		.data_out(data_out),
		.address_data(address_data),
		.data_out2(data_out2),
		.MemRd(MemRd),
		.MemWr(MemWr),
		.state(state),
		.ALU_result(ALU_result),
		.ALUop(ALUop)
		);
	
	// Clock generation
	initial begin
			clk = 0;
			forever #5 clk = ~clk; // Toggle clock every 5 time units
		end
	
	// Initial block for test stimulus
	initial begin
			// Initialize inputs
			reset = 1;
			#10;
			reset = 0;
			#10;
			reset = 1;
			
			// Monitor signals
			$monitor("Time: %0dns, State: %0d, Opcode: %0b, Address Instruction: 0x%04X, Data Out Instruction: 0x%04X, Address Data: 0x%04X, Data Out: 0x%04X, ALU Result: 0x%04X, MemRd: %b, MemWr: %b, ALUop: %0b",
				$time, state, opcode, address_instruction, data_out_instruction, address_data, data_out, ALU_result, MemRd, MemWr, ALUop);
			
			// Simulate for a specific amount of time to observe more instructions
			#300;
			$finish;
		end
	
endmodule


