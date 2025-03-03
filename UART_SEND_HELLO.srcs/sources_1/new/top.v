`timescale 1ns / 1ps

module top(
    input clk,
    input start,     // Start transmission
    output reg tx, 
    output txdone
);

// Parameters
parameter clk_value = 50_000_000;
parameter baud = 9600;
parameter wait_count = clk_value / baud;

// State Definitions
parameter idle = 0, send = 1, check = 2, gap = 3;
reg [1:0] state = idle;

// Characters to Send: "Namaste FPGA\t\n"
reg [7:0] message [0:12];  // "Namaste FPGA\t\n"
reg [3:0] char_index = 0;   // Index for message

// TX Logic
reg [9:0] txData;
integer bitIndex = 0;
reg [9:0] shifttx = 0;

// Delay between characters
integer char_delay = 0;

// Baud Rate Generator
reg bitDone = 0;
integer count = 0;

// Load "Namaste FPGA\t\n" into memory
initial begin
    message[0]  = "N";
    message[1]  = "a";
    message[2]  = "m";
    message[3]  = "a";
    message[4]  = "s";
    message[5]  = "t";
    message[6]  = "e";
    message[7]  = " ";
    message[8]  = "F";
    message[9]  = "P";
    message[10] = "G";
    message[11] = "A";
    message[12] = 9;   // ASCII for '\t' (Tab)
    message[13] = 10;  // ASCII for '\n' (Newline)
end

////////////////////////// Baud Rate Generator //////////////////////////
always @(posedge clk) begin
    if (state == idle) begin 
        count <= 0;
    end else begin
        if (count == wait_count) begin
            bitDone <= 1'b1;
            count   <= 0;  
        end else begin
            count   <= count + 1;
            bitDone <= 1'b0;  
        end    
    end
end

////////////////////////// TX Logic //////////////////////////
always @(posedge clk) begin
    case (state)
    
        idle: begin
            tx       <= 1'b1;  // Idle state is HIGH
            txData   <= 0;
            bitIndex <= 0;
            shifttx  <= 0;
            char_delay <= 0;
            
            if (start == 1'b1) begin
                txData <= {1'b1, message[char_index], 1'b0}; // Load char with start & stop bits
                state  <= send;
            end
        end
        
        send: begin
            tx    <= txData[bitIndex]; // Send bits one by one
            state <= check;
        end 
        
        check: begin
            if (bitIndex < 9) begin
                if (bitDone == 1'b1) begin
                    state    <= send;
                    bitIndex <= bitIndex + 1;
                end
            end else begin
                state    <= gap;  // Small delay before sending next character
                bitIndex <= 0;
            end
        end

        gap: begin
            if (char_delay < wait_count * 2) begin
                char_delay <= char_delay + 1;
            end else begin
                char_delay <= 0;
                
                if (char_index < 13) begin  // Message length = 14 (including '\t' and '\n')
                    char_index <= char_index + 1;
                    txData     <= {1'b1, message[char_index], 1'b0}; // Load next character
                    state      <= send;
                end else begin
                    char_index <= 0;  // Restart message transmission
                    state      <= (start == 1'b1) ? send : idle; // Repeat if start is still high
                end
            end
        end

        default: state <= idle;
        
    endcase
end

// TX Done Signal
assign txdone = (state == idle) ? 1'b1 : 1'b0;  // HIGH when all characters are sent

endmodule
