\TLV_version 1d: tl-x.org
\SV
   `include "sqrt32.v";
   module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);    /* verilator lint_save */ /* verilator lint_off UNOPTFLAT */  bit [256:0] RW_rand_raw; bit [256+63:0] RW_rand_vect; pseudo_rand #(.WIDTH(257)) pseudo_rand (clk, reset, RW_rand_raw[256:0]); assign RW_rand_vect[256+63:0] = {RW_rand_raw[62:0], RW_rand_raw};  /* verilator lint_restore */
      /* verilator lint_off WIDTH */
\TLV


   // ----------------------
   // Stimulus
   |calc
      @0
         // Need 3 invalid cycles before skip.
         $skip_ok = ! >>1$valid && ! >>2$valid && ! >>3$valid && >>4$valid;

                                             
                                      // 50% valid and 50% of those are skips, but only if it's okay to skip.
         $valid = $rand_valid && (!$rand_skip || $skip_ok) && !/top>>1$reset;
         $skip_to = $valid && $rand_skip;
         ?$valid
                                                 $aa[31:0] = $rand_aa[4:0];
                                                 $bb[31:0] = $rand_bb[4:0];



   // ----------------------
   // DUT

   // Reset
   // Create pipesignal out of reset module input.
   $reset = *reset;

   // Calc pipeline
   |calc
      ?$valid
         
         // Corrected $aa for skip calculation.
         //<(2)+>@0
         //<(2)+>   $corrected_aa[31:0] = $skip_to ? ($aa + >>4$cc) : $aa;


         // Pythagorean Theorem hop distance calculation.
         @1
            $aa_sq[31:0] = $aa * $aa;   //<(2)*> = $corrected_aa * $corrected_aa;
            $bb_sq[31:0] = $bb * $bb;
         @2
            $cc_sq[31:0] = $aa_sq + $bb_sq;
         @3
            $cc[31:0] = sqrt($cc_sq);
      
      
      // Total distance accumulator.
      @4
         //[(1)+]?$valid
         //[(1)+]   $tot_incr[31:0] = >>1$tot_dist + $cc;  // adder
         $tot_dist[31:0] =
                           '0;   //[(1)-] DELETE LINE
         //[(1)+]     /top<<3$reset    ? 32'b0     :   // reset
         //[(1)+]     $valid
         //<(2)+>            && ! >>4$skip_to
         //[(1)+]                      ? $tot_incr :   // add $cc
         //[(1)+]                        >>1$tot_dist; // retain (or use "$RETAIN")



   // ----------------------
   // Output
   |calc
      @0
         // Free-running cycle count.
         $cyc_cnt[15:0] = /top>>1$reset ? 16'b0 : >>1$cyc_cnt + 16'b1;
      @5
         \SV_plus
            always_ff @(posedge clk) begin
               if ($valid) begin
                  \$display("Cyc \%d:\\n  \$skip_to: \%d\\n  \$aa: \%d\\n  \$bb: \%d\\n  \$cc: \%d\\n  \$tot_dist: \%d\\n", $cyc_cnt, $skip_to, $aa, $bb, $cc, $tot_dist);
                  //<(2)*> [Substitute $corrected_aa for $aa above.]
               end
            end

      @1
         // Pass the test on cycle 40.
         *passed = $cyc_cnt > 16'd40;


\SV
endmodule
