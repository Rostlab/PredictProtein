#!/usr/bin/perl

package prof;

sub extract_preds {

    my @extract_cols;
    my $file = shift (@_);
    for (@_) { push (@extract_cols, $_); }
    if (scalar(@extract_cols) == 0) {
	@extract_cols = ("PHEL","RI_S","pH","pE","pL","Pbe","Pbie");
    } 
    print "### extract_preds: Columns to be extracted from $file: @extract_cols\n";
    $last_col = scalar(@extract_cols);
    $output = "";

    open PROFIN, "<".$file or die "### extract_preds: couldn't open prof file $file\n";
    $datastarted = 0;
 
    while (<PROFIN>) {
	chomp;
	### Run only when data section has started
	if ($datastarted) {
	    @temp = split /\t/;
	    for ($c=0; $c<$last_col; $c++) {
		$str[$c] .= $temp[$col[$c]];
	    }
	}

	### Detect start of data section and parse column headers
	if (/^No/) { 
	    #if ($prots++ > 100) {exit;}
	    $datastarted = 1; 
	    @temp = split /\s+/;
	    %fields = ();
	    $i=0;
	    foreach $x (@temp) {
		$fields{$x} = $i++; # creat column # lookup for column name $x in %fields
	    }
	    for ($c=0; $c<$last_col; $c++) {
		$str[$c] = "";
		if (exists $fields{$extract_cols[$c]}) {
		    $col[$c] = $fields{$extract_cols[$c]};
		}else{
		    return (1, "### extract_preds: Column header $extract_cols[$c] not found in file $file");
		}
	    }
	    @temp = split /\-/, $file;
	    $fileroot = $temp[0];
	    #$output .= ">$fileroot\n";
	}
    }
    for ($c=0; $c<$last_col; $c++) {
	$output .= $extract_cols[$c]."\t$str[$c]\n";
    }
    return (0, $output);
}

return 1;
