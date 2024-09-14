module minipit (
    input clk,
    input rst_n,
    input write_enable,
    input repeating,
    input [7:0] counter_high,
    input [7:0] counter_low,
    input divider_on,
    output counter_set,
    output wire interrupting
);

  wire reset = !rst_n;

  reg  r_interrupting;
  reg  r_counter_set;
  assign counter_set  = r_counter_set;

  assign interrupting = r_interrupting;

  // counter derived from config byte 1 concatenated with config byte 0
  reg [15:0] counter;
  reg [15:0] current_count;

  // A counter to use when the divider is enabled
  reg [ 7:0] divider_count;

  always @(posedge clk) begin
    if (reset) begin
      counter <= 0;
      current_count <= 0;
      r_counter_set <= 0;
      divider_count <= 0;
      r_interrupting <= 0;
    end else begin
      if (write_enable) begin
        counter <= {counter_high, counter_low};
      end else begin
        r_counter_set <= 1;
      end

      if (counter_set && divider_on) begin
        divider_count <= divider_count + 1;
        if (divider_count == 10) begin
          divider_count <= 0;  // reset
          current_count <= current_count + 1;
        end
      end else if (counter_set) begin
        current_count <= current_count + 1;
      end else begin
        current_count <= current_count;
      end

      if (counter_set && (current_count == counter)) begin
        // pull interrupt line high for one clock cycle
        r_interrupting <= 1;
        if (repeating) begin
          current_count <= 0;
        end
        // on a rollover of divider_count, reset the interrupt
        if (divider_on && (divider_count > 0)) begin
          r_interrupting <= 0;
        end
      end else begin
        r_interrupting <= 0;
      end
    end
  end
endmodule
