// Design code  : 
module mul(
input [15:0] a,b,
output [31:0] m
);
assign m = a * b;
endmodule

// Testbench code: 

class transaction;
  randc bit [15:0] a;
  randc bit [15:0] b;
  bit [31:0] m;
endclass
 
class generator;
mailbox mbx;
event done;
transaction t;
integer i;
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
task main();
t = new();
for(i = 0; i < 25; i++)begin
t.randomize();
mbx.put(t);
$display("[GEN] : Data send to Driver");
@(done);
#10;
end
endtask
endclass
 
interface mul_intf();
  logic [15:0] a;
  logic [15:0] b;
  logic [31:0] m;
endinterface
 
class driver;
mailbox mbx;
transaction t;
event done;
virtual mul_intf vif;
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
task main();
t = new();
forever begin
mbx.get(t);
vif.a = t.a;
vif.b = t.b;
$display("[DRV] : Interface is triggered");
-> done;
#10;
end
endtask
 
endclass  
 
 
class monitor;
 virtual mul_intf vif;
 mailbox mbx;
 transaction t;
 
 function new(mailbox mbx);
 this.mbx = mbx;
 endfunction
 
task main();
t = new();
forever begin
t.a = vif.a;
t.b = vif.b;
t.m = vif.m;
mbx.put(t);
$display("[MON] : Data send to Scoreboard");
#10;
end
endtask
 
endclass
 
 
class scoreboard;
mailbox mbx;
transaction t;
  bit [31:0] temp;
 
function new(mailbox mbx);
this.mbx = mbx;
endfunction
 
task main();
t = new();
forever begin
mbx.get(t);
temp = t.a * t.b;
if(t.m == temp)
begin
$display("[SCO] :Test Passed");
end
else
begin
$display("[SCO] :Test Failed");
end
#10;
end
endtask
endclass
 
class environment;
generator gen;
driver drv;
monitor mon;
scoreboard sco;
 
mailbox gdmbx, msmbx;
 
virtual mul_intf vif;
event gddone;
 
function new(mailbox gdmbx, mailbox msmbx);
this.gdmbx = gdmbx;
this.msmbx = msmbx;
gen = new(gdmbx);
drv = new(gdmbx);
mon = new(msmbx);
sco = new(msmbx);
endfunction
 
task main();
drv.vif = vif;
mon.vif = vif;
 
gen.done = gddone;
drv.done = gddone;
 
fork
gen.main();
drv.main();
mon.main();
sco.main();
join_any
 
endtask
endclass
 
module tb();
environment e;
mailbox gdmbx, msmbx;
 
mul_intf vif();
 
mul dut (vif.a, vif.b, vif.m);
 
initial begin
gdmbx = new();
msmbx = new();
e = new(gdmbx,msmbx);
e.vif = vif;
e.main();
#500;
$finish;
end
  initial begin 
    $dumpvars ; 
    $dumpfile("dump.vcd"); 
  end

endmodule
