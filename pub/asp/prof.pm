#!/usr/bin/perl
#$prof_filename=$ARGV[0];

#$prof_res = prof::extract_preds($prof_filename);

#@seq = split '', $prof_res->[0];
#@prharr = split '', $prof_res->[3];
#@prearr = split '', $prof_res->[4];
#@prlarr = split '', $prof_res->[5];
#    print $prharr[12];
#print @prharr,"\n";
#print scalar  @prharr,"\n";
#print @prearr,"\n";
#print scalar  @prearr,"\n";
#print @prlarr,"\n";
#print scalar  @seq,"\n";




print @seq;


package prof;

sub extract_preds {

    my @extract_cols;
    my $file = shift (@_);
    for (@_) { push (@extract_cols, $_); }
    if (scalar(@extract_cols) == 0) {
	@extract_cols = ("AA","PHEL","RI_S","pH","pE","pL","Pbe","Pbie");
    } 
#    print "### extract_preds: Columns to be extracted from $file: @extract_cols\n";
    $last_col = scalar(@extract_cols);
    $output = "";

    open PROFIN, "<".$file or die "### extract_preds: couldn't open prof file $file\n";
    $datastarted = 0;
 
    while (<PROFIN>) {
	chomp;
	if ($datastarted) {
	    @temp = split /\t/;
	    for ($c=0; $c<$last_col; $c++) {
		$str[$c] .= $temp[$col[$c]];
	    }
	}
	if (/^No/) { 
	    #if ($prots++ > 100) {exit;}
	    $datastarted = 1; 
	    @temp = split /\s+/;
	    %fields = ();
	    $i=0;
	    foreach $x (@temp) {
		$fields{$x} = $i++;
	    }
	    for ($c=0; $c<$last_col; $c++) {
		$str[$c] = "";
		$col[$c] = $fields{$extract_cols[$c]};
	    }
	    @temp = split /\-/, $file;
	    $fileroot = $temp[0];
	    #$output .= ">$fileroot\n";
	}
    }

    return \@str;
}

#return 1;
