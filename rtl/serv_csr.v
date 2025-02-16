`default_nettype none
module serv_csr
  (
   input wire 	    i_clk,
   input wire [4:2] i_cnt,
   input wire [3:2] i_cnt_r,
   //From mpram
   input wire 	    i_rf_csr_out,
   //to mpram
   output wire 	    o_csr_in,
   //Stuff
   input wire 	    i_mtip,
   output wire 	    o_timer_irq_en,
   input wire 	    i_mstatus_en,
   input wire 	    i_mie_en,
   input wire 	    i_mcause_en,
   input wire [1:0] i_csr_source,
   input wire 	    i_trap,
   input wire [3:0] i_mcause,
   input wire 	    i_d,
   output wire 	    o_q);

`include "serv_params.vh"

   reg 		    mstatus;
   reg 		    mstatus_mie;
   reg 		    mie_mtie;

   reg 		mcause31;
   reg [3:0] 	mcause3_0;
   wire 	mcause;

   wire 	csr_in;
   wire 	csr_out;

   assign csr_in = (i_csr_source == CSR_SOURCE_EXT) ? i_d :
		   (i_csr_source == CSR_SOURCE_SET) ? csr_out | i_d :
		   (i_csr_source == CSR_SOURCE_CLR) ? csr_out & ~i_d :
		   (i_csr_source == CSR_SOURCE_CSR) ? csr_out :
		   1'bx;

   assign csr_out = (i_mstatus_en & mstatus) |
		    i_rf_csr_out |
		    (i_mcause_en & mcause);

   assign o_q = csr_out;

   assign 	o_timer_irq_en = mstatus_mie & mie_mtie;

   assign mcause = (i_cnt[4:2] == 3'd0) ? mcause3_0[0] : //[3:0]
		   ((i_cnt[4:2] == 3'd7) & i_cnt_r[3]) ? mcause31 //[31]
		   : 1'b0;

   assign o_csr_in = csr_in;

   always @(posedge i_clk) begin
      if (i_mstatus_en & (i_cnt[4:2] == 3'd0) & i_cnt_r[3])
	mstatus_mie <= csr_in;

      if (i_mie_en & (i_cnt[4:2] == 3'd1) & i_cnt_r[3])
	mie_mtie <= csr_in;

      mstatus <= (i_cnt[4:2] == 0) & i_cnt_r[2] & mstatus_mie;

      if (i_trap) begin
	 mcause31  <= i_mtip & o_timer_irq_en;
	 mcause3_0 <= (i_mtip & o_timer_irq_en) ? 4'd7 : i_mcause[3:0];
      end

      if (i_mcause_en) begin
	 if (i_cnt[4:2] == 3'd0)
	   mcause3_0 <= {csr_in, mcause3_0[3:1]};
	 if ((i_cnt[4:2] == 3'd7) & i_cnt_r[3])
	   mcause31 <= csr_in;
      end
   end

endmodule
