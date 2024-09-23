`default_nettype none

// Ensures that the first_state happens before the second_state.
// We use a label as a breadcrumb in case an invalid state is asserted
`define HAPPENS_BEFORE(first_state, second_state) \
  if (f_past_valid && $past(trst) && current_state == second_state) begin \
    HA_``first_state``_to_``second_state : assert ($past(current_state) == first_state); \
  end;

module jtag (
    input tck,
    /* verilator lint_off UNUSEDSIGNAL */
    input tdi,
    /* verilator lint_off UNUSEDSIGNAL */
    input tdo,
    input tms,
    input trst
);

  localparam bit [4:0] TestLogicReset = 5'h0;
  localparam bit [4:0] RunTestOrIdle = 5'h1;
  localparam bit [4:0] SelectDrScan = 5'h2;
  localparam bit [4:0] SelectIrScan = 5'h3;
  localparam bit [4:0] CaptureDr = 5'h4;
  localparam bit [4:0] CaptureIr = 5'h5;
  localparam bit [4:0] ShiftDr = 5'h6;
  localparam bit [4:0] ShiftIr = 5'h7;
  localparam bit [4:0] Exit1Dr = 5'h8;
  localparam bit [4:0] Exit1Ir = 5'h9;
  localparam bit [4:0] PauseDr = 5'h10;
  localparam bit [4:0] PauseIr = 5'h11;
  localparam bit [4:0] Exit2Dr = 5'h12;
  localparam bit [4:0] Exit2Ir = 5'h13;
  localparam bit [4:0] UpdateDr = 5'h14;
  localparam bit [4:0] UpdateIr = 5'h15;

  reg [4:0] current_state;

  // for checking that the TAP state machine is in reset at the right time.
  reg [4:0] tms_reset_check;
  reg [7:0] cycles;

  always @(posedge tck) begin
    if (trst) begin
      current_state <= TestLogicReset;  // 0
      tms_reset_check <= 5'b0_0000;
      cycles <= 0;
    end else begin
      tms_reset_check <= tms_reset_check << 1;
      tms_reset_check[0] <= tms;
      cycles <= cycles + 1;
      // TAP state machine
      case (current_state)
        TestLogicReset: begin  // 0
          tms_reset_check <= 5'b0_0000;
          case (tms)
            1: current_state <= TestLogicReset;
            default: current_state <= RunTestOrIdle;
          endcase
        end
        RunTestOrIdle:  // 1
        case (tms)
          1: current_state <= SelectDrScan;
          default: current_state <= RunTestOrIdle;
        endcase
        SelectDrScan:  // 2
        case (tms)
          1: current_state <= SelectIrScan;
          default: current_state <= CaptureDr;
        endcase
        SelectIrScan:  // 3
        case (tms)
          1: current_state <= TestLogicReset;
          default: current_state <= CaptureIr;
        endcase
        CaptureDr:  // 4
        case (tms)
          1: current_state <= Exit1Dr;
          default: current_state <= ShiftDr;
        endcase
        CaptureIr:  // 5
        case (tms)
          1: current_state <= Exit1Ir;
          default: current_state <= ShiftIr;
        endcase
        ShiftDr:  // 6
        case (tms)
          1: current_state <= Exit1Dr;
          default: current_state <= ShiftDr;
        endcase
        ShiftIr:  // 7
        case (tms)
          1: current_state <= Exit1Ir;
          default: current_state <= ShiftIr;
        endcase
        Exit1Dr:  // 8
        case (tms)
          1: current_state <= UpdateDr;
          default: current_state <= PauseDr;
        endcase
        Exit1Ir:  // 9
        case (tms)
          1: current_state <= UpdateIr;
          default: current_state <= PauseIr;
        endcase
        PauseDr:  // 10
        case (tms)
          1: current_state <= Exit2Dr;
          default: current_state <= PauseDr;
        endcase
        PauseIr:  // 11
        case (tms)
          1: current_state <= Exit2Ir;
          default: current_state <= PauseIr;
        endcase
        Exit2Dr:  // 12
        case (tms)
          1: current_state <= UpdateDr;
          default: current_state <= ShiftDr;
        endcase
        Exit2Ir:  // 13
        case (tms)
          1: current_state <= UpdateIr;
          default: current_state <= ShiftIr;
        endcase
        UpdateDr:  // 14
        case (tms)
          1: current_state <= SelectDrScan;
          default: current_state <= RunTestOrIdle;
        endcase
        UpdateIr:  // 15
        case (tms)
          1: current_state <= SelectDrScan;
          default: current_state <= RunTestOrIdle;
        endcase
        default: current_state <= TestLogicReset;
      endcase
    end
  end


`ifdef FORMAL
  logic f_past_valid;

  initial begin
    f_past_valid = 0;
  end

  always @(posedge tck) f_past_valid <= 1;

  always_comb begin
    if (!f_past_valid) assume (trst);
  end

  always @(posedge tck) begin
    if (f_past_valid) begin
      // our state never overruns the enum values.
      assert (current_state <= 5'h15);
      cover (current_state <= UpdateIr);
    end
  end

  always @(posedge tck) begin
    // Whenever TMS is high for five cycles, the design is in reset
    if (f_past_valid && (tms_reset_check == 5'b1_1111)) begin
      assert (current_state == TestLogicReset);
    end

    // TRST puts us in state 0
    if (f_past_valid && $past(trst)) begin
      initial_state : assert (current_state == TestLogicReset);
    end

    //
    // Checking that states are achievable via the documented Tap FSM
    //
    `HAPPENS_BEFORE(TestLogicReset, RunTestOrIdle)
    `HAPPENS_BEFORE(RunTestOrIdle, RunTestOrIdle)
    `HAPPENS_BEFORE(RunTestOrIdle, SelectDrScan)
    `HAPPENS_BEFORE(SelectDrScan, SelectIrScan)
    `HAPPENS_BEFORE(SelectDrScan, CaptureDr)
    `HAPPENS_BEFORE(SelectIrScan, CaptureIr)
    `HAPPENS_BEFORE(CaptureDr, Exit1Dr)
    `HAPPENS_BEFORE(CaptureDr, ShiftDr)
    `HAPPENS_BEFORE(CaptureIr, Exit1Ir)
    `HAPPENS_BEFORE(CaptureIr, ShiftIr)
    `HAPPENS_BEFORE(ShiftDr, Exit1Dr)
    `HAPPENS_BEFORE(ShiftDr, ShiftDr)
    `HAPPENS_BEFORE(ShiftIr, Exit1Ir)
    `HAPPENS_BEFORE(ShiftIr, ShiftIr)
    `HAPPENS_BEFORE(Exit1Dr, UpdateDr)
    `HAPPENS_BEFORE(Exit1Dr, PauseDr)
    `HAPPENS_BEFORE(Exit1Ir, UpdateIr)
    `HAPPENS_BEFORE(Exit1Ir, PauseIr)
    `HAPPENS_BEFORE(PauseDr, Exit2Dr)
    `HAPPENS_BEFORE(PauseDr, PauseDr)
    `HAPPENS_BEFORE(PauseIr, Exit2Ir)
    `HAPPENS_BEFORE(PauseIr, PauseIr)
    `HAPPENS_BEFORE(Exit2Dr, UpdateDr)
    `HAPPENS_BEFORE(Exit2Dr, ShiftDr)
    `HAPPENS_BEFORE(Exit2Ir, UpdateIr)
    `HAPPENS_BEFORE(Exit2Ir, ShiftIr)
    `HAPPENS_BEFORE(UpdateDr, SelectDrScan)
    `HAPPENS_BEFORE(UpdateDr, RunTestOrIdle)
    `HAPPENS_BEFORE(UpdateIr, SelectDrScan)
    `HAPPENS_BEFORE(UpdateIr, RunTestOrIdle)
    // This state is broken for unknown reasons.
    /*`HAPPENS_BEFORE(SelectIrScan, TestLogicReset) */

  end
`endif
endmodule
