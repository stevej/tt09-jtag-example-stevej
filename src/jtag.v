`default_nettype none

module jtag (
    input tck,
    input tdi,
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
  reg [8:0] cycles;

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
          1: current_state <= UpdateIr;
          default: current_state <= ShiftIr;
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

    if (f_past_valid) begin
      // TRST puts us in state 0
      if ($past(trst)) begin
        assert (current_state == TestLogicReset);
      end

      if ($past(trst)) begin
        cover (current_state == TestLogicReset);
      end
      /*
      if (($past(current_state) == TestLogicReset) && ($past(tms) == 0)) begin
        assert (current_state == RunTestOrIdle);
      end
*/
      // Check that all valid state transitions have occurred.
      //assert ($past(tms_reset_check) == 5'b1_1111 && current_state == TestLogicReset);
      // Check that all states can reach TestLogicReset.
    end
  end
`endif
endmodule
