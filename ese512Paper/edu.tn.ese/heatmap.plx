#Copyright (c) 2015, Debbie Weighill, The University of Tennessee
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification,
#are permitted provided that the following conditions are met:
#
#1. Redistributions of source code must retain the above copyright notice, this
#list of conditions and the following disclaimer.
#
#2. Redistributions in binary form must reproduce the above copyright notice, 
#this list of conditions and the following disclaimer in the documentation and/or 
#other materials provided with the distribution.
#
#3. Neither the name of the copyright holder nor the names of its contributors 
#may be used to endorse or promote products derived from this software without 
#specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
#FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
#DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
#SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
#CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
#OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
#OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#!/usr/bin/perl
use warnings;
use strict;

open OUT, ">heatmap.txt";

for my $carbon_intensity (5..217)
{
	if (($carbon_intensity % 5) == 0)
	{
		print OUT "\t$carbon_intensity";
	}
}
print OUT "\n";

#first read in state carbon output and convert to kilograms CO2/kWh, store in a ref
my $state;
open STATE, "state_formatted.txt";

my $counter = 1;

while (<STATE>)
{
	if ($counter != 1)
	{
		chomp $_;
		my @line = split /\t/, $_;
		my $kgperkwh = ($line[1] / 1000000) * 3412.14163;
		$state->{$line[0]} = $kgperkwh;
		#print "$kgperkwh\n";
	}
	$counter++;
}
close STATE;



my $performance_ratio = 0.75;
my $roof_frac = 0.75;
#vary carbon intensity, keep efficiency at 0.16


for my $i (10..70)
{
	my $efficiency = $i/100;

	print OUT "$efficiency";
	
	for my $carbon_intensity (5..217)
	{
	
		if (($carbon_intensity % 5) == 0)
		{
		

			my $sum_saved = 0;
			my $count = 0;

			my $sum_no_solar = 0;

			#open solar/rooftop data
			open DATA, "solar_data_formatted.txt";
			$counter = 1;
			
			while (<DATA>)
			{
				if ($counter != 1)
				{
					chomp $_;
					my @line = split /\s+/, $_;
		
					#calculate amount of energy from solar, given a certain efficiency and fraction of rooftop area
					# efficiency * performance_ratio * insolence * roof_area * roof_frac
					my $energy_from_solar = $efficiency * $performance_ratio * $line[2] * $line[3] * $roof_frac;
					#print "$energy_from_solar\n";
		
					#calculate carbon emissions from solar in kg CO2 per day
					my $emissions_solar = $energy_from_solar * ($carbon_intensity/1000);
		
					#print "$line[1]\n";
					#calculate carbon emmissions of building without soalr
					my $emissions_no_solar = $line[4] * $state->{$line[1]};
		
					#calculate carbon saved
					#(emissions if no panels installed) - (emissions if panels installed)
					my $saved = $emissions_no_solar - ($emissions_solar + (($line[4] - $energy_from_solar) * $state->{$line[1]}));
		
		
					$count++;
					$sum_saved += $saved;
					$sum_no_solar += $emissions_no_solar;		
				}
				$counter++;
	
			}
			close DATA;

			my $average_saved = $sum_saved/$count;
			my $percent_saved = ($sum_saved/$sum_no_solar) * 100;

			print OUT "\t$percent_saved";
		}#end if
	
	}#end inner loop
	
	print OUT "\n";

}#end outer loop
