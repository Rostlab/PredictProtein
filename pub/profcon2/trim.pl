#!/bin/perl

$filename = "predict_h162745632093029392";
$filename =~ s/predict_h//g;
$length = length $filename;

if ((length $filename)>8){
    $filename = substr($filename,$length-8,8);
}

print $filename."\n";

