`default_nettype none
module jtag_formal (
    input tck,
    input tdi,
    input tdo,
    input tms,
    input trst
);

  jtag uut (.*);

`ifdef FORMAL
  logic f_past_valid;

  initial begin
    f_past_valid = 0;
    reset = 1;
  end

  always_comb begin
    if (!f_past_valid) assume (reset);
  end

  always @(posedge tck) begin
    if (f_past_valid) begin
      // Check that all valid state transitions have occurred.
      assert ($past(current_state == TestLogicReset) && current_state == TestLogicReset);
      // Check that all states can reach TestLogicReset.

      // Check that all invalid state transitions have not occurred.
    end
  end
`endif

endmodule
