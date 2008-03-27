package      libList;
require      Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(min max uniqueList);
@EXPORT_OK = qw(listDiff intersection mean sse sum union pearson_correlation);
#================================================================
# libraries of some list opearation
# listDiff() return the difference of two lists
# min()
# max()
# intersection()
# union()
# uniqueList()
# sum()
# mean()
# sse()  sum of squared error
# pearson_correlation(list1,list2)
#=================================================================

use strict;


sub listDiff {
    my ( $aRef, $bRef ) = @_;
    my @aOnly = ();
    my @bOnly = ();
    my %aSeen = ();
    my %bSeen = ();
    my $item;

    foreach $item ( @$aRef ) {
	$aSeen{$item} = 1;
    }
    foreach $item ( @$bRef ) {
	$bSeen{$item} = 1;
    }

    foreach $item ( @$aRef ) {
	push @aOnly, $item if ( ! $bSeen{$item} );
    }
    foreach $item ( @$bRef ) {
	push @bOnly, $item if ( ! $aSeen{$item} );
    }
    return ([@aOnly], [@bOnly]);
}
    


sub intersection {
    my @lists = @_;
    my ( @uniqueLists, $list,$ctList,$listUnion,$item, %ct,@isect);

    $ctList = scalar ( @lists );
    return  if ( $ctList == 0 );
    
				# first get unique lists
    foreach $list ( @lists ) {
	push @uniqueLists, &uniqueList($list); 
    }
    return  $uniqueLists[0]  if ( $ctList == 1 );
    
    %ct = ();
    @isect = ();
				# count the occurence of items
    foreach $list ( @uniqueLists ) {
	foreach $item ( @$list ) {
	    $ct{$item}++;
	}
    }

    $listUnion = &union(@uniqueLists);
    foreach $item ( @$listUnion ) {
	next if ( ! defined $ct{$item} );
				# check the occurence of the item against 
				# the number of lists
	if ( $ct{$item} == $ctList ) {
	    push @isect, $item;
	}
    }
    return [@isect];
}


	    
sub max {
    my ( $listRef )  = @_;
    my ( $item );
    return if ( ! @$listRef );
    my $max = $listRef->[0];
    foreach $item ( @$listRef ) {
	$max = $item if ( $item > $max );
    }

    return $max;
}


sub mean {
    my ( $listRef ) = @_;
    my ( $item );
    return if ( ! @$listRef );

    my $ctItem = scalar ( @$listRef );
    my $sum = &sum($listRef);
    return $sum/$ctItem;
}


sub min {
    my ( $listRef )  = @_;
    my ( $item );
    return if ( ! @$listRef );
    my $min = $listRef->[0];
    foreach $item ( @$listRef ) {
	$min = $item if ( $item < $min );
    }

    return $min;
}


sub pearson_correlation {
    my ( $list_ref1,$list_ref2 ) = @_;
    my ( $sum_x,$sum_y,$sum_x2,$sum_y2,$n,$sum_xy,$r,$i );
   
    if ( scalar(@$list_ref1) != scalar(@$list_ref2) ) {
	return undef;
    }
    
    $sum_x = &sum($list_ref1);
    $sum_y = &sum($list_ref2);

    $sum_x2 = &sum_square($list_ref1);
    $sum_y2 = &sum_square($list_ref2);
    
    $n = scalar(@$list_ref1);

    $sum_xy = 0;
    for $i ( 0..$n-1 ) {
	$sum_xy += $list_ref1->[$i] * $list_ref2->[$i];
    }

    $r = ($sum_xy - $sum_x*$sum_y/$n)/
	sqrt(($sum_x2-$sum_x*$sum_x/$n)*($sum_y2-$sum_y*$sum_y/$n));
    return $r;
}


sub sse {
    my ($listRef ) = @_;
    my ($item,$mean,$sse);
    return if ( ! @$listRef );

    $mean = &mean($listRef);
    $sse = 0;
    foreach $item ( @$listRef ) {
	$sse += ( $item - $mean) * ( $item - $mean );
    }
    return $sse;
}

sub sum {
    my ( $listRef ) = @_;
    my ( $item );
    return if ( ! @$listRef );

    my $sum = 0;
    foreach $item ( @$listRef ) {
	$sum += $item;
    }
    return $sum;
}

sub sum_square {
    my ( $listRef ) = @_;
    my ( $item );
    return undef if ( ! @$listRef );

    my $sum = 0;
    foreach $item ( @$listRef ) {
	$sum += $item * $item;
    }
    return $sum;
}



sub union {
    my (@lists) = @_;
    
    my @union =  ();
    my %union =  ();	
    my ($list,$item);

    foreach $list ( @lists ) {
	foreach $item ( @$list ) {
	    $union{$item} = 1;
	}
    }
    @union = keys %union;
    return [@union];
}


sub uniqueList {
    my ( $listRef ) = @_;
    my @unique =  ();
    my %unique =  ();	
    my $item;

    foreach $item ( @$listRef ) {
	$unique{$item} = 1;
    }
    @unique = keys %unique;

    return [ @unique ];
}


1;




