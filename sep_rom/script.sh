#!/bin/bash
if [ -n *.mem ] ; then
	find *.mem | grep -v img | grep -v weights |  while read LINE ; do rm -rf $LINE ; done
fi
if [ -n rom.sv ] ; then 
	rm -rf rom.sv
fi
count=0 
file_count=1
file=""
if [[ -n $1 ]] && [[ -n $2 ]] && [[ -n $3 ]] ; then
	let "limit=$1*$2*$3"
else 
	echo -e "ERROR: please enter Width Height #Filter_Channels #Filters\nIN ORDER" ;
	exit 1;
fi
touch readmem.sv always.sv decl.sv rom.sv
address=` ./log2.pl "$limit"` ;
#echo -e "always @(*) begin\n if (rom_en) begin" >> always.sv
echo "
	/* verilator lint_off COMBDLY */
	module rom_array_layer_1 #(
	parameter WIDTH=16,
	parameter KERNEL="$1",
	parameter ADDR="$address",
	parameter NUM="$4")
	(
		input [ADDR-1:0] address ,
		output reg [WIDTH-1:0] rom_out [0:NUM-1]
	);	
	" >> rom.sv
echo "initial  begin" >> readmem.sv 
cat weights.mem | while read LINE ; do
if [ -z "$file" ] ; then
       	touch file_1.mem 
       	 file="file_1.mem" 
	echo "
  	(* rom_style=\"{distributed}\" *)
	reg [WIDTH-1:0] rom_"$file_count" [0:2**ADDR-1] ;" >> decl.sv;
	#echo -e "\t rom_out[$(($file_count-1))] <= rom_"$file_count"[address["$(($file_count-1))"]];" >> always.sv
	echo "\$readmemb("\"$file\"",rom_"$file_count",0,"$limit"-1);" >> readmem.sv;
	((file_count++));
fi
if [[ $count -eq $limit ]] ; then
	touch file_"$file_count".mem;
	echo "
  	(* rom_style=\"{distributed}\" *)
	reg [WIDTH-1:0] rom_"$file_count" [0:2**ADDR-1] ;" >> decl.sv;
	#echo -e "\t rom_out[$(($file_count-1))] <= rom_"$file_count"[address];" >> always.sv
	file=file_"$file_count".mem;
	echo "\$readmemb("\"$file\"",rom_"$file_count",0,2**ADDR-1);" >> readmem.sv;
	count=0;
       	if (( $file_count  >  "$4" )) ; then
		break ;
	else
		((file_count++));
	fi
fi
echo $LINE >> $file; ((count++)); done 

#echo -e "end\n end" >> always.sv
for (( i = 0 ; i < 64 ; i++)) ; do
	#echo -e "always @(*) begin\n \t  rom_out["$i"]<= rom_"$(($i+1))"[address["$i"]] ;\n end" >> always.sv
	echo "assign rom_out["$i"] = rom_"$(($i+1))"[address] ;" >> always.sv ;
done
echo "end" >> readmem.sv
cat decl.sv >> rom.sv
cat readmem.sv >> rom.sv
cat always.sv >> rom.sv
echo "endmodule" >> rom.sv
rm -rf always.sv decl.sv readmem.sv
find *.mem | grep -v img | grep -v weights |  while read LINE ; do cat weights.mem >> $LINE ; done

