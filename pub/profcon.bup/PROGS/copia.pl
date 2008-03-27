#!/usr/bin/perl -w

##find every pair of amino acids in a bpd file that has:
#   1. sequence separation greater than or eqaul to $sep.
#   2. 2 atoms that has spatial separation that is smalled than $cutoff.


if (@ARGV<3){ die "Usage: $0 protein_name(MAX 8 char.) file.hssp file.rdbProf \n";}

@e=@ARGV;
$input_name=$e[0];
$input_hssp=$e[1];
$input_prof=$e[2];


$root_dir = $ENV{'PROFCON'};


$sep=6;
$win=4;
$win_mid=1;


##########################  READ HSSP FILE #########################

undef $mod;

$fhssp=$root_dir."/".$input_hssp;
open(FHSSP,"<$fhssp");

READ_HSSP: while (<FHSSP>) {

if (/^\/\//) {last READ_HSSP;}
if (/^## SEQUENCE/) {$mod=1; next READ_HSSP;}
if ((defined $mod) and ($mod==1)) {$mod=$mod+1; next READ_HSSP;}
if ((defined $mod) and ($mod==2)) {
$hsspline=substr($_,0,129); #chomp $hsspline;
undef @array;
@array = split(/\s+/,$hsspline);

for ($ii=1; $ii<27; $ii++) {
$occ[$array[1]][$ii]=$array[$ii+2];
                } # end of for
                                } # end of if ((defined $mod) and

                        } # end of READ_HSSP: while (<FHSSP>)

close(FHSSP);


##########################  READ PROF FILE #########################

undef $mod;

$none1=0;
$none2=0;
$none3=0;
$none4=0;
$none5=0;
$none6=0;

$nn=0;

$fprof=$root_dir."/".$input_prof;
open(FPROF,"<$fprof");

READ_PROF: while (<FPROF>) {

if (/^No/) {$mod=1; next READ_PROF;}

if ((defined $mod) and ($mod==1)) {
$nn=$nn+1;
($resnum,$tmp_type,$none1,$tmp_str,$tmp_ri_ss,$none2,$none3,$none4,$none5,$tmp_ri_acc,
$tmp_ph,$tmp_pe,$tmp_pl,$none6,$tmp_twoacc)=split(/\t/,$_);
$prof_restype[$resnum]=$tmp_type;

$occ[$resnum][27]=$tmp_str;
$occ[$resnum][28]=$tmp_ri_ss;
$occ[$resnum][29]=$tmp_ph;
$occ[$resnum][30]=$tmp_pe;
$occ[$resnum][31]=$tmp_pl;

$occ[$resnum][32]=$tmp_twoacc;
$occ[$resnum][33]=$tmp_ri_acc;

$resname[$resnum]=$tmp_type;
$ph[$resnum]=$tmp_ph;
$pe[$resnum]=$tmp_pe;
$pl[$resnum]=$tmp_pl;

                } # end of if ((defined $mod) and ($mod==1))

        } # end of READ_PROF: while (<FPROF>)

$last_seg=$nn;

close(FPROF);


######	GENERATE INFO ABOUT CONNECTING SEGMENT  ########


for ($pp=1; $pp<($last_seg-$sep+1); $pp++) {

for ($qq=($pp+$sep); $qq<($last_seg+1); $qq++) {


undef $seg_h; undef $seg_e; undef $seg_l;

undef $seg_A; undef $seg_R; undef $seg_N; undef $seg_D; undef $seg_C; undef $seg_Q; 
undef $seg_E; undef $seg_G; undef $seg_H; undef $seg_I; undef $seg_L; undef $seg_K;
undef $seg_M; undef $seg_F; undef $seg_P; undef $seg_S; undef $seg_T; undef $seg_W;
undef $seg_Y; undef $seg_V;

for ($ii=($pp+1); $ii<$qq; $ii++) {


if (defined $seg_h) {$seg_h=$seg_h+$ph[$ii];}
else {$seg_h=$ph[$ii];}

if (defined $seg_e) {$seg_e=$seg_e+$pe[$ii];}
else {$seg_e=$pe[$ii];}

if (defined $seg_l) {$seg_l=$seg_l+$pl[$ii];}
else {$seg_l=$pl[$ii];}


                } # end of for ($ii=$pp;


$ss_h{$pp.",".$qq}=int($seg_h/(abs($pp-$qq)-1));
$ss_e{$pp.",".$qq}=int($seg_e/(abs($pp-$qq)-1));
$ss_l{$pp.",".$qq}=int($seg_l/(abs($pp-$qq)-1));


$minus=0;

for ($ii=($pp+1); $ii< $qq; $ii++) {

if ($resname[$ii] eq "A") {
if (defined $seg_A) {$seg_A=$seg_A+1;}
else {$seg_A=1;}
                                }
if ($resname[$ii] eq "R") {
if (defined $seg_R) {$seg_R=$seg_R+1;}
else {$seg_R=1;}
                                }
if ($resname[$ii] eq "N") {
if (defined $seg_N) {$seg_N=$seg_N+1;}
else {$seg_N=1;}
                                }
if ($resname[$ii] eq "D") {
if (defined $seg_D) {$seg_D=$seg_D+1;}
else {$seg_D=1;}
                                }
if ($resname[$ii] eq "C") {
if (defined $seg_C) {$seg_C=$seg_C+1;}
else {$seg_C=1;}
                                }
if ($resname[$ii] eq "Q") {
if (defined $seg_Q) {$seg_Q=$seg_Q+1;}
else {$seg_Q=1;}
                                }
if ($resname[$ii] eq "E") {
if (defined $seg_E) {$seg_E=$seg_E+1;}
else {$seg_E=1;}
                                }
if ($resname[$ii] eq "G") {
if (defined $seg_G) {$seg_G=$seg_G+1;}
else {$seg_G=1;}
                                }
if ($resname[$ii] eq "H") {
if (defined $seg_H) {$seg_H=$seg_H+1;}
else {$seg_H=1;}
                                }
if ($resname[$ii] eq "I") {
if (defined $seg_I) {$seg_I=$seg_I+1;}
else {$seg_I=1;}
                                }
if ($resname[$ii] eq "L") {
if (defined $seg_L) {$seg_L=$seg_L+1;}
else {$seg_L=1;}
                                }
if ($resname[$ii] eq "K") {
if (defined $seg_K) {$seg_K=$seg_K+1;}
else {$seg_K=1;}
                                }
if ($resname[$ii] eq "M") {
if (defined $seg_M) {$seg_M=$seg_M+1;}
else {$seg_M=1;}
                                }
if ($resname[$ii] eq "F") {
if (defined $seg_F) {$seg_F=$seg_F+1;}
else {$seg_F=1;}
                                }
if ($resname[$ii] eq "P") {
if (defined $seg_P) {$seg_P=$seg_P+1;}
else {$seg_P=1;}
                                }
if ($resname[$ii] eq "S") {
if (defined $seg_S) {$seg_S=$seg_S+1;}
else {$seg_S=1;}
                                }
if ($resname[$ii] eq "T") {
if (defined $seg_T) {$seg_T=$seg_T+1;}
else {$seg_T=1;}
                                }
if ($resname[$ii] eq "W") {
if (defined $seg_W) {$seg_W=$seg_W+1;}
else {$seg_W=1;}
                                }
if ($resname[$ii] eq "Y") {
if (defined $seg_Y) {$seg_Y=$seg_Y+1;}
else {$seg_Y=1;}
                                }
if ($resname[$ii] eq "V") {
if (defined $seg_V) {$seg_V=$seg_V+1;}
else {$seg_V=1;}
                                }

if ($resname[$ii] eq "X") {
if (defined $minus) {$minus=$minus+1;}
else {$minus=1;}
                                }

        } # end of for ($ii=($pp+1)


if (defined $seg_A) {$seg_A=int($seg_A/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_A =0;}
$fill=1;
$ty{$fill.",".$pp.",".$qq}=$seg_A;
if (defined $seg_R) {$seg_R=int($seg_R/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_R =0;}
$fill=2;
$ty{$fill.",".$pp.",".$qq}=$seg_R;
if (defined $seg_N) {$seg_N=int($seg_N/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_N =0;}
$fill=3;
$ty{$fill.",".$pp.",".$qq}=$seg_N;
if (defined $seg_D) {$seg_D=int($seg_D/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_D =0;}
$fill=4;
$ty{$fill.",".$pp.",".$qq}=$seg_D;
if (defined $seg_C) {$seg_C=int($seg_C/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_C =0;}
$fill=5;
$ty{$fill.",".$pp.",".$qq}=$seg_C;
if (defined $seg_Q) {$seg_Q=int($seg_Q/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_Q =0;}
$fill=6;
$ty{$fill.",".$pp.",".$qq}=$seg_Q;
if (defined $seg_E) {$seg_E=int($seg_E/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_E =0;}
$fill=7;
$ty{$fill.",".$pp.",".$qq}=$seg_E;
if (defined $seg_G) {$seg_G=int($seg_G/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_G =0;}
$fill=8;
$ty{$fill.",".$pp.",".$qq}=$seg_G;
if (defined $seg_H) {$seg_H=int($seg_H/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_H =0;}
$fill=9;
$ty{$fill.",".$pp.",".$qq}=$seg_H;
if (defined $seg_I) {$seg_I=int($seg_I/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_I =0;}
$fill=10;
$ty{$fill.",".$pp.",".$qq}=$seg_I;
if (defined $seg_L) {$seg_L=int($seg_L/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_L =0;}
$fill=11;
$ty{$fill.",".$pp.",".$qq}=$seg_L;
if (defined $seg_K) {$seg_K=int($seg_K/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_K =0;}
$fill=12;
$ty{$fill.",".$pp.",".$qq}=$seg_K;
if (defined $seg_M) {$seg_M=int($seg_M/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_M =0;}
$fill=13;
$ty{$fill.",".$pp.",".$qq}=$seg_M;
if (defined $seg_F) {$seg_F=int($seg_F/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_F =0;}
$fill=14;
$ty{$fill.",".$pp.",".$qq}=$seg_F;
if (defined $seg_P) {$seg_P=int($seg_P/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_P =0;}
$fill=15;
$ty{$fill.",".$pp.",".$qq}=$seg_P;
if (defined $seg_S) {$seg_S=int($seg_S/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_S =0;}
$fill=16;
$ty{$fill.",".$pp.",".$qq}=$seg_S;
if (defined $seg_T) {$seg_T=int($seg_T/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_T =0;}
$fill=17;
$ty{$fill.",".$pp.",".$qq}=$seg_T;
if (defined $seg_W) {$seg_W=int($seg_W/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_W =0;}
$fill=18;
$ty{$fill.",".$pp.",".$qq}=$seg_W;
if (defined $seg_Y) {$seg_Y=int($seg_Y/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_Y =0;}
$fill=19;
$ty{$fill.",".$pp.",".$qq}=$seg_Y;
if (defined $seg_V) {$seg_V=int($seg_V/(abs($pp-$qq)-1-$minus)*100);}
else {$seg_V =0;}
$fill=20;
$ty{$fill.",".$pp.",".$qq}=$seg_V;


        } # end of  for ($qq=($pp+$sep); $qq<($last_seg+1); $qq++)

    } # end of for ($pp=1; $pp<($last_seg-$sep+1); $pp++)



##########################     OUTPUT FILES     ####################


$numb_samples=$root_dir."/DATA/NUMB_all.dat";
open (NUMB_ALL, ">$numb_samples");

$sample_all=$root_dir."/DATA/INPUT.sample_all";
open (SAMPLEST_ALL, ">$sample_all");

$out_tr_all=$root_dir."/DATA/INPUT.outtrain_all";
open (OUT_TEST_ALL, ">$out_tr_all");

$count_all=0;


##############    DEFINE FILES FORMATS    ###############


#### NUMB ####

format OUT_NUMB =
@>>>>>>> @>>>>> @>>>> @>>>>> @>>>>
$input_name,$pp,$qq,$prof_restype[$pp],$prof_restype[$qq]
.


### ALL ###

format ITSAM_ALL =
@<<<<<< @>>>>>>>
"ITSAM:",$count_all
.

format OUT_TEST_ALL =
@>>>>>>> @>>>>> @>>>>
$count_all,$left_print,$right_print
.


###########


format SAMPLEST =
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[1],$pos[2],$pos[3],$pos[4],$pos[5],$pos[6],$pos[7],$pos[8],$pos[9],$pos[10],$pos[11],$pos[12],$pos[13],$pos[14],$pos[15],$pos[16],$pos[17],$pos[18],$pos[19],$pos[20],$pos[21],$pos[22],$pos[23],$pos[24],$pos[25]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[26],$pos[27],$pos[28],$pos[29],$pos[30],$pos[31],$pos[32],$pos[33],$pos[34],$pos[35],$pos[36],$pos[37],$pos[38],$pos[39],$pos[40],$pos[41],$pos[42],$pos[43],$pos[44],$pos[45],$pos[46],$pos[47],$pos[48],$pos[49],$pos[50]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[51],$pos[52],$pos[53],$pos[54],$pos[55],$pos[56],$pos[57],$pos[58],$pos[59],$pos[60],$pos[61],$pos[62],$pos[63],$pos[64],$pos[65],$pos[66],$pos[67],$pos[68],$pos[69],$pos[70],$pos[71],$pos[72],$pos[73],$pos[74],$pos[75]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[76],$pos[77],$pos[78],$pos[79],$pos[80],$pos[81],$pos[82],$pos[83],$pos[84],$pos[85],$pos[86],$pos[87],$pos[88],$pos[89],$pos[90],$pos[91],$pos[92],$pos[93],$pos[94],$pos[95],$pos[96],$pos[97],$pos[98],$pos[99],$pos[100]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[101],$pos[102],$pos[103],$pos[104],$pos[105],$pos[106],$pos[107],$pos[108],$pos[109],$pos[110],$pos[111],$pos[112],$pos[113],$pos[114],$pos[115],$pos[116],$pos[117],$pos[118],$pos[119],$pos[120],$pos[121],$pos[122],$pos[123],$pos[124],$pos[125]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[126],$pos[127],$pos[128],$pos[129],$pos[130],$pos[131],$pos[132],$pos[133],$pos[134],$pos[135],$pos[136],$pos[137],$pos[138],$pos[139],$pos[140],$pos[141],$pos[142],$pos[143],$pos[144],$pos[145],$pos[146],$pos[147],$pos[148],$pos[149],$pos[150]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[151],$pos[152],$pos[153],$pos[154],$pos[155],$pos[156],$pos[157],$pos[158],$pos[159],$pos[160],$pos[161],$pos[162],$pos[163],$pos[164],$pos[165],$pos[166],$pos[167],$pos[168],$pos[169],$pos[170],$pos[171],$pos[172],$pos[173],$pos[174],$pos[175]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[176],$pos[177],$pos[178],$pos[179],$pos[180],$pos[181],$pos[182],$pos[183],$pos[184],$pos[185],$pos[186],$pos[187],$pos[188],$pos[189],$pos[190],$pos[191],$pos[192],$pos[193],$pos[194],$pos[195],$pos[196],$pos[197],$pos[198],$pos[199],$pos[200]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[201],$pos[202],$pos[203],$pos[204],$pos[205],$pos[206],$pos[207],$pos[208],$pos[209],$pos[210],$pos[211],$pos[212],$pos[213],$pos[214],$pos[215],$pos[216],$pos[217],$pos[218],$pos[219],$pos[220],$pos[221],$pos[222],$pos[223],$pos[224],$pos[225]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[226],$pos[227],$pos[228],$pos[229],$pos[230],$pos[231],$pos[232],$pos[233],$pos[234],$pos[235],$pos[236],$pos[237],$pos[238],$pos[239],$pos[240],$pos[241],$pos[242],$pos[243],$pos[244],$pos[245],$pos[246],$pos[247],$pos[248],$pos[249],$pos[250]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[251],$pos[252],$pos[253],$pos[254],$pos[255],$pos[256],$pos[257],$pos[258],$pos[259],$pos[260],$pos[261],$pos[262],$pos[263],$pos[264],$pos[265],$pos[266],$pos[267],$pos[268],$pos[269],$pos[270],$pos[271],$pos[272],$pos[273],$pos[274],$pos[275]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[276],$pos[277],$pos[278],$pos[279],$pos[280],$pos[281],$pos[282],$pos[283],$pos[284],$pos[285],$pos[286],$pos[287],$pos[288],$pos[289],$pos[290],$pos[291],$pos[292],$pos[293],$pos[294],$pos[295],$pos[296],$pos[297],$pos[298],$pos[299],$pos[300]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[301],$pos[302],$pos[303],$pos[304],$pos[305],$pos[306],$pos[307],$pos[308],$pos[309],$pos[310],$pos[311],$pos[312],$pos[313],$pos[314],$pos[315],$pos[316],$pos[317],$pos[318],$pos[319],$pos[320],$pos[321],$pos[322],$pos[323],$pos[324],$pos[325]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[326],$pos[327],$pos[328],$pos[329],$pos[330],$pos[331],$pos[332],$pos[333],$pos[334],$pos[335],$pos[336],$pos[337],$pos[338],$pos[339],$pos[340],$pos[341],$pos[342],$pos[343],$pos[344],$pos[345],$pos[346],$pos[347],$pos[348],$pos[349],$pos[350]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[351],$pos[352],$pos[353],$pos[354],$pos[355],$pos[356],$pos[357],$pos[358],$pos[359],$pos[360],$pos[361],$pos[362],$pos[363],$pos[364],$pos[365],$pos[366],$pos[367],$pos[368],$pos[369],$pos[370],$pos[371],$pos[372],$pos[373],$pos[374],$pos[375]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[376],$pos[377],$pos[378],$pos[379],$pos[380],$pos[381],$pos[382],$pos[383],$pos[384],$pos[385],$pos[386],$pos[387],$pos[388],$pos[389],$pos[390],$pos[391],$pos[392],$pos[393],$pos[394],$pos[395],$pos[396],$pos[397],$pos[398],$pos[399],$pos[400]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[401],$pos[402],$pos[403],$pos[404],$pos[405],$pos[406],$pos[407],$pos[408],$pos[409],$pos[410],$pos[411],$pos[412],$pos[413],$pos[414],$pos[415],$pos[416],$pos[417],$pos[418],$pos[419],$pos[420],$pos[421],$pos[422],$pos[423],$pos[424],$pos[425]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[426],$pos[427],$pos[428],$pos[429],$pos[430],$pos[431],$pos[432],$pos[433],$pos[434],$pos[435],$pos[436],$pos[437],$pos[438],$pos[439],$pos[440],$pos[441],$pos[442],$pos[443],$pos[444],$pos[445],$pos[446],$pos[447],$pos[448],$pos[449],$pos[450]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[451],$pos[452],$pos[453],$pos[454],$pos[455],$pos[456],$pos[457],$pos[458],$pos[459],$pos[460],$pos[461],$pos[462],$pos[463],$pos[464],$pos[465],$pos[466],$pos[467],$pos[468],$pos[469],$pos[470],$pos[471],$pos[472],$pos[473],$pos[474],$pos[475]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[476],$pos[477],$pos[478],$pos[479],$pos[480],$pos[481],$pos[482],$pos[483],$pos[484],$pos[485],$pos[486],$pos[487],$pos[488],$pos[489],$pos[490],$pos[491],$pos[492],$pos[493],$pos[494],$pos[495],$pos[496],$pos[497],$pos[498],$pos[499],$pos[500]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[501],$pos[502],$pos[503],$pos[504],$pos[505],$pos[506],$pos[507],$pos[508],$pos[509],$pos[510],$pos[511],$pos[512],$pos[513],$pos[514],$pos[515],$pos[516],$pos[517],$pos[518],$pos[519],$pos[520],$pos[521],$pos[522],$pos[523],$pos[524],$pos[525]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[526],$pos[527],$pos[528],$pos[529],$pos[530],$pos[531],$pos[532],$pos[533],$pos[534],$pos[535],$pos[536],$pos[537],$pos[538],$pos[539],$pos[540],$pos[541],$pos[542],$pos[543],$pos[544],$pos[545],$pos[546],$pos[547],$pos[548],$pos[549],$pos[550]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[551],$pos[552],$pos[553],$pos[554],$pos[555],$pos[556],$pos[557],$pos[558],$pos[559],$pos[560],$pos[561],$pos[562],$pos[563],$pos[564],$pos[565],$pos[566],$pos[567],$pos[568],$pos[569],$pos[570],$pos[571],$pos[572],$pos[573],$pos[574],$pos[575]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[576],$pos[577],$pos[578],$pos[579],$pos[580],$pos[581],$pos[582],$pos[583],$pos[584],$pos[585],$pos[586],$pos[587],$pos[588],$pos[589],$pos[590],$pos[591],$pos[592],$pos[593],$pos[594],$pos[595],$pos[596],$pos[597],$pos[598],$pos[599],$pos[600]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[601],$pos[602],$pos[603],$pos[604],$pos[605],$pos[606],$pos[607],$pos[608],$pos[609],$pos[610],$pos[611],$pos[612],$pos[613],$pos[614],$pos[615],$pos[616],$pos[617],$pos[618],$pos[619],$pos[620],$pos[621],$pos[622],$pos[623],$pos[624],$pos[625]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[626],$pos[627],$pos[628],$pos[629],$pos[630],$pos[631],$pos[632],$pos[633],$pos[634],$pos[635],$pos[636],$pos[637],$pos[638],$pos[639],$pos[640],$pos[641],$pos[642]
.


format SAMPLEST_2 =
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[262],$pos[263],$pos[264],$pos[265],$pos[266],$pos[267],$pos[268],$pos[269],$pos[270],$pos[271],$pos[272],$pos[273],$pos[274],$pos[275],$pos[276],$pos[277],$pos[278],$pos[279],$pos[280],$pos[281],$pos[282],$pos[283],$pos[284],$pos[285],$pos[286]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[287],$pos[288],$pos[289],$pos[290],$pos[291],$pos[292],$pos[293],$pos[294],$pos[295],$pos[296],$pos[297],$pos[298],$pos[299],$pos[300],$pos[301],$pos[302],$pos[303],$pos[304],$pos[305],$pos[306],$pos[307],$pos[308],$pos[309],$pos[310],$pos[311]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[312],$pos[313],$pos[314],$pos[315],$pos[316],$pos[317],$pos[318],$pos[319],$pos[320],$pos[321],$pos[322],$pos[323],$pos[324],$pos[325],$pos[326],$pos[327],$pos[328],$pos[329],$pos[330],$pos[331],$pos[332],$pos[333],$pos[334],$pos[335],$pos[336]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[337],$pos[338],$pos[339],$pos[340],$pos[341],$pos[342],$pos[343],$pos[344],$pos[345],$pos[346],$pos[347],$pos[348],$pos[349],$pos[350],$pos[351],$pos[352],$pos[353],$pos[354],$pos[355],$pos[356],$pos[357],$pos[358],$pos[359],$pos[360],$pos[361]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[362],$pos[363],$pos[364],$pos[365],$pos[366],$pos[367],$pos[368],$pos[369],$pos[370],$pos[371],$pos[372],$pos[373],$pos[374],$pos[375],$pos[376],$pos[377],$pos[378],$pos[379],$pos[380],$pos[381],$pos[382],$pos[383],$pos[384],$pos[385],$pos[386]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[387],$pos[388],$pos[389],$pos[390],$pos[391],$pos[392],$pos[393],$pos[394],$pos[395],$pos[396],$pos[397],$pos[398],$pos[399],$pos[400],$pos[401],$pos[402],$pos[403],$pos[404],$pos[405],$pos[406],$pos[407],$pos[408],$pos[409],$pos[410],$pos[411]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[412],$pos[413],$pos[414],$pos[415],$pos[416],$pos[417],$pos[418],$pos[419],$pos[420],$pos[421],$pos[422],$pos[423],$pos[424],$pos[425],$pos[426],$pos[427],$pos[428],$pos[429],$pos[430],$pos[431],$pos[432],$pos[433],$pos[434],$pos[435],$pos[436]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[437],$pos[438],$pos[439],$pos[440],$pos[441],$pos[442],$pos[443],$pos[444],$pos[445],$pos[446],$pos[447],$pos[448],$pos[449],$pos[450],$pos[451],$pos[452],$pos[453],$pos[454],$pos[455],$pos[456],$pos[457],$pos[458],$pos[459],$pos[460],$pos[461]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[462],$pos[463],$pos[464],$pos[465],$pos[466],$pos[467],$pos[468],$pos[469],$pos[470],$pos[471],$pos[472],$pos[473],$pos[474],$pos[475],$pos[476],$pos[477],$pos[478],$pos[479],$pos[480],$pos[481],$pos[482],$pos[483],$pos[484],$pos[485],$pos[486]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[487],$pos[488],$pos[489],$pos[490],$pos[491],$pos[492],$pos[493],$pos[494],$pos[495],$pos[496],$pos[497],$pos[498],$pos[499],$pos[500],$pos[501],$pos[502],$pos[503],$pos[504],$pos[505],$pos[506],$pos[507],$pos[508],$pos[509],$pos[510],$pos[511]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[512],$pos[513],$pos[514],$pos[515],$pos[516],$pos[517],$pos[518],$pos[519],$pos[520],$pos[521],$pos[522],$pos[1],$pos[2],$pos[3],$pos[4],$pos[5],$pos[6],$pos[7],$pos[8],$pos[9],$pos[10],$pos[11],$pos[12],$pos[13],$pos[14]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[15],$pos[16],$pos[17],$pos[18],$pos[19],$pos[20],$pos[21],$pos[22],$pos[23],$pos[24],$pos[25],$pos[26],$pos[27],$pos[28],$pos[29],$pos[30],$pos[31],$pos[32],$pos[33],$pos[34],$pos[35],$pos[36],$pos[37],$pos[38],$pos[39]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[40],$pos[41],$pos[42],$pos[43],$pos[44],$pos[45],$pos[46],$pos[47],$pos[48],$pos[49],$pos[50],$pos[51],$pos[52],$pos[53],$pos[54],$pos[55],$pos[56],$pos[57],$pos[58],$pos[59],$pos[60],$pos[61],$pos[62],$pos[63],$pos[64]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[65],$pos[66],$pos[67],$pos[68],$pos[69],$pos[70],$pos[71],$pos[72],$pos[73],$pos[74],$pos[75],$pos[76],$pos[77],$pos[78],$pos[79],$pos[80],$pos[81],$pos[82],$pos[83],$pos[84],$pos[85],$pos[86],$pos[87],$pos[88],$pos[89]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[90],$pos[91],$pos[92],$pos[93],$pos[94],$pos[95],$pos[96],$pos[97],$pos[98],$pos[99],$pos[100],$pos[101],$pos[102],$pos[103],$pos[104],$pos[105],$pos[106],$pos[107],$pos[108],$pos[109],$pos[110],$pos[111],$pos[112],$pos[113],$pos[114]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[115],$pos[116],$pos[117],$pos[118],$pos[119],$pos[120],$pos[121],$pos[122],$pos[123],$pos[124],$pos[125],$pos[126],$pos[127],$pos[128],$pos[129],$pos[130],$pos[131],$pos[132],$pos[133],$pos[134],$pos[135],$pos[136],$pos[137],$pos[138],$pos[139]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[140],$pos[141],$pos[142],$pos[143],$pos[144],$pos[145],$pos[146],$pos[147],$pos[148],$pos[149],$pos[150],$pos[151],$pos[152],$pos[153],$pos[154],$pos[155],$pos[156],$pos[157],$pos[158],$pos[159],$pos[160],$pos[161],$pos[162],$pos[163],$pos[164]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[165],$pos[166],$pos[167],$pos[168],$pos[169],$pos[170],$pos[171],$pos[172],$pos[173],$pos[174],$pos[175],$pos[176],$pos[177],$pos[178],$pos[179],$pos[180],$pos[181],$pos[182],$pos[183],$pos[184],$pos[185],$pos[186],$pos[187],$pos[188],$pos[189]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[190],$pos[191],$pos[192],$pos[193],$pos[194],$pos[195],$pos[196],$pos[197],$pos[198],$pos[199],$pos[200],$pos[201],$pos[202],$pos[203],$pos[204],$pos[205],$pos[206],$pos[207],$pos[208],$pos[209],$pos[210],$pos[211],$pos[212],$pos[213],$pos[214]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[215],$pos[216],$pos[217],$pos[218],$pos[219],$pos[220],$pos[221],$pos[222],$pos[223],$pos[224],$pos[225],$pos[226],$pos[227],$pos[228],$pos[229],$pos[230],$pos[231],$pos[232],$pos[233],$pos[234],$pos[235],$pos[236],$pos[237],$pos[238],$pos[239]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[240],$pos[241],$pos[242],$pos[243],$pos[244],$pos[245],$pos[246],$pos[247],$pos[248],$pos[249],$pos[250],$pos[251],$pos[252],$pos[253],$pos[254],$pos[255],$pos[256],$pos[257],$pos[258],$pos[259],$pos[260],$pos[261],$pos[523],$pos[524],$pos[525]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[526],$pos[527],$pos[528],$pos[529],$pos[530],$pos[531],$pos[532],$pos[533],$pos[534],$pos[535],$pos[536],$pos[537],$pos[538],$pos[539],$pos[540],$pos[541],$pos[542],$pos[543],$pos[544],$pos[545],$pos[546],$pos[547],$pos[548],$pos[549],$pos[550]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[551],$pos[552],$pos[553],$pos[554],$pos[555],$pos[556],$pos[557],$pos[558],$pos[559],$pos[560],$pos[561],$pos[562],$pos[563],$pos[564],$pos[565],$pos[566],$pos[567],$pos[568],$pos[569],$pos[570],$pos[571],$pos[572],$pos[573],$pos[574],$pos[575]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[576],$pos[577],$pos[578],$pos[579],$pos[580],$pos[581],$pos[582],$pos[583],$pos[584],$pos[585],$pos[586],$pos[587],$pos[588],$pos[589],$pos[590],$pos[591],$pos[592],$pos[593],$pos[594],$pos[595],$pos[596],$pos[597],$pos[598],$pos[599],$pos[600]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[601],$pos[602],$pos[603],$pos[604],$pos[605],$pos[606],$pos[607],$pos[608],$pos[609],$pos[610],$pos[611],$pos[612],$pos[613],$pos[614],$pos[615],$pos[616],$pos[617],$pos[618],$pos[619],$pos[620],$pos[621],$pos[622],$pos[623],$pos[624],$pos[625]
@>>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>> @>>>>
$pos[626],$pos[627],$pos[628],$pos[629],$pos[630],$pos[631],$pos[632],$pos[633],$pos[634],$pos[635],$pos[636],$pos[637],$pos[638],$pos[639],$pos[640],$pos[641],$pos[642]
.



#########################################
########################     -      #####
#######################     / \     ######
#######################    -----   #######
#####################     /     \  ########
############################################


for ($pp=1; $pp<($last_seg-$sep+1); $pp++) {

for ($qq=($pp+$sep); $qq<($last_seg+1); $qq++) {


        $each=0;

        for ($i=-$win;$i<($win+1);$i++) {

        for ($ll=1;$ll<30;$ll++){
                $pos[$ll+29*$each]=0;
                                }

        if (not exists $occ[$pp+$i][1]) {
        $pos[21+29*$each]=100;
                                }
        else {
        for ($ll=1;$ll<21;$ll++){
        $pos[$ll+29*$each]=$occ[$pp+$i][$ll];
                                }

	$pos[22+29*$each]=$occ[$pp+$i][28]*10;
        $pos[23+29*$each]=$occ[$pp+$i][29]*10;
        $pos[24+29*$each]=$occ[$pp+$i][30]*10;
        $pos[25+29*$each]=$occ[$pp+$i][31]*10;

        if ($occ[$pp+$i][32] eq "b") {
        $pos[26+29*$each]=100;}
        if ($occ[$pp+$i][32] eq "e") {
        $pos[27+29*$each]=100;}

        $pos[28+29*$each]=$occ[$pp+$i][33]*10;

        $pos[29+29*$each]=int($occ[$pp+$i][26]*50);


                } # end fo else
        $each=$each+1;
                } # end of for ($i=-$win;



        for ($i=-$win;$i<($win+1);$i++) {

        for ($ll=1;$ll<30;$ll++){
                $pos[$ll+29*$each]=0;
                                }

        if (not exists $occ[$qq+$i][1]) {
        $pos[21+29*$each]=100;
                                }
        else {
        for ($ll=1;$ll<21;$ll++){
        $pos[$ll+29*$each]=$occ[$qq+$i][$ll];
                                }

        $pos[22+29*$each]=$occ[$qq+$i][28]*10;
        $pos[23+29*$each]=$occ[$qq+$i][29]*10;
        $pos[24+29*$each]=$occ[$qq+$i][30]*10;
        $pos[25+29*$each]=$occ[$qq+$i][31]*10;

        if ($occ[$qq+$i][32] eq "b") {
        $pos[26+29*$each]=100;}
        if ($occ[$qq+$i][32] eq "e") {
        $pos[27+29*$each]=100;}

        $pos[28+29*$each]=$occ[$qq+$i][33]*10;

        $pos[29+29*$each]=int($occ[$qq+$i][26]*50);

                } # end of else
        $each=$each+1;
                } # end of for ($i=-$win;



#########  mid window ########

        $medium=$pp+int(abs($pp-$qq)/2);

        for ($i=-$win_mid;$i<($win_mid+1);$i++) {

        for ($ll=1;$ll<30;$ll++){
                $pos[$ll+29*$each]=0;
                                }

        if (not defined $occ[$medium+$i][1]) {
        $pos[21+29*$each]=100;
                                }
        else {
        for ($ll=1;$ll<21;$ll++){
        $pos[$ll+29*$each]=$occ[$medium+$i][$ll];
                                }

        $pos[22+29*$each]=$occ[$medium+$i][28]*10;
        $pos[23+29*$each]=$occ[$medium+$i][29]*10;
        $pos[24+29*$each]=$occ[$medium+$i][30]*10;
        $pos[25+29*$each]=$occ[$medium+$i][31]*10;

        if ($occ[$medium+$i][32] eq "b") {
        $pos[26+29*$each]=100;}
        if ($occ[$medium+$i][32] eq "e") {
        $pos[27+29*$each]=100;}

        $pos[28+29*$each]=$occ[$medium+$i][33]*10;

        $pos[29+29*$each]=int($occ[$medium+$i][26]*50);

                } # end of else
        $each=$each+1;
                } # end of for ($i=-$win;

################################


        $seqsep=abs($pp-$qq);

        if (($seqsep == 6) or ($seqsep == 7)) {$pos[1+29*$each]=100;}
        else {$pos[1+29*$each]=0;}
        if ($seqsep == 8) {$pos[2+29*$each]=100;}
        else {$pos[2+29*$each]=0;}
        if ($seqsep == 9) {$pos[3+29*$each]=100;}
        else {$pos[3+29*$each]=0;}

        if (($seqsep >=10) and ($seqsep < 15)) {$pos[4+29*$each]=100;}
        else {$pos[4+29*$each]=0;}
        if (($seqsep >=15) and ($seqsep < 20)) {$pos[5+29*$each]=100;}
        else {$pos[5+29*$each]=0;}
        if (($seqsep >=20) and ($seqsep < 25)) {$pos[6+29*$each]=100;}
        else {$pos[6+29*$each]=0;}
        if (($seqsep >=25) and ($seqsep < 30)) {$pos[7+29*$each]=100;}
        else {$pos[7+29*$each]=0;}

        if (($seqsep >=30) and ($seqsep < 40)) {$pos[8+29*$each]=100;}
        else {$pos[8+29*$each]=0;}
        if (($seqsep >=40) and ($seqsep < 50)) {$pos[9+29*$each]=100;}
        else {$pos[9+29*$each]=0;}

        if ($seqsep >= 50) {$pos[10+29*$each]=100;}

        else {$pos[10+29*$each]=0;}


######## segment info

	for ($ll=1; $ll<(21); $ll++) {
	
	$pos[10+$ll+29*$each]=$ty{$ll.",".$pp.",".$qq};

					}
	
        $pos[31+29*$each]=$ss_h{$pp.",".$qq};
        $pos[32+29*$each]=$ss_e{$pp.",".$qq};
        $pos[33+29*$each]=$ss_l{$pp.",".$qq};


        $left_print=100;
        $right_print=0;


######## print numb

        select((select(NUMB_ALL),$~ = "OUT_NUMB")[0]);
        write (NUMB_ALL);

######## print all

        $count_all=$count_all+1;

        select((select(OUT_TEST_ALL),$~ = "OUT_TEST_ALL")[0]);
        write (OUT_TEST_ALL);
        select((select(SAMPLEST_ALL),$~ = "ITSAM_ALL")[0]);
        write(SAMPLEST_ALL);
        select((select(SAMPLEST_ALL),$~ = "SAMPLEST")[0]);
        write(SAMPLEST_ALL);


        $count_all=$count_all+1;

        select((select(OUT_TEST_ALL),$~ = "OUT_TEST_ALL")[0]);
        write (OUT_TEST_ALL);
        select((select(SAMPLEST_ALL),$~ = "ITSAM_ALL")[0]);
        write(SAMPLEST_ALL);
        select((select(SAMPLEST_ALL),$~ = "SAMPLEST_2")[0]);
        write(SAMPLEST_ALL);


			} # end of for ($qq=($pp+1); $qq

		} # end of for ($pp=1; $pp


print SAMPLEST_ALL "//","\n";
print OUT_TEST_ALL "//","\n";

########### TITLE FILES ##############

format SAMPLE_TITLE_ALL =
@<<<<<<<<<<<<<<<<<<<<<
"* overall: (A,T25,I8)"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMIN                 :      642"
@<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>
"NUMSAMFILE            : ",$count_all
@<
"*"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"* samples: count (A8,I8) NEWLINE 1..NUMIN (25I6)"
.



format OUT_TEST_TITLE_ALL =
@<<<<<<<<<<<<<<<<<<<<<
"* overall: (A,T25,I8)"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMOUT                :        2"
@<<<<<<<<<<<<<<<<<<<<<<< @>>>>>>
"NUMSAMFILE            : ",$count_all
@<
"*"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"* samples: count (I8) SPACE 1..NUMOUT (25I6)"
.


#########      OUTPUT FILES TITLES      ##############

#### ALL #####

$sample_all=$root_dir."/DATA/TITLE.sample_all";
open (SAMPLEST_TITLE, ">$sample_all");

$out_tr_all=$root_dir."/DATA/TITLE.outtrain_all";
open (OUT_TEST_TITLE, ">$out_tr_all");


        select((select(SAMPLEST_TITLE),$~ = "SAMPLE_TITLE_ALL")[0]);
        write(SAMPLEST_TITLE);
        select((select(OUT_TEST_TITLE),$~ = "OUT_TEST_TITLE_ALL")[0]);
        write(OUT_TEST_TITLE);


########  PARAM FILE FOR NN ################


format P_OUT =
@<<<
"* I8"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMIN                 :      642"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMHID                :       30"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMOUT                :        2"
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
"NUMLAYERS             :        2"
@<<<<<<<<<<<<<<<<<<<<<<<< @>>>>>
"NUMSAM                : ",$count_all
.

$ini_param=$root_dir."/DATA/param.dat";
open (P_OUT, ">$ini_param");

write(P_OUT);


			###################
			####################
			####### END ########
			####################
			###################


