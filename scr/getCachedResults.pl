#!/usr/bin/perl -w
use Digest::MD5 qw(md5_hex);

($file_fasta,$workID, $workDir) =  @ARGV;
#$workDir = '/nfs/data5/users/ppuser/server/work';

my @ext = ('f','proftmb','prosite','seg','mat','rdbHtm');
my @extGZ = ('tmhmm','hsspFil','saf','pfam','coils', 'hsspPsi');


if ( ! $file_fasta or ! -s $file_fasta ) {
   print STDOUT "input sequence not found\n";
   exit(1);
} 


$md5_hash = &fasta2md5($file_fasta);

$dir_id = '/data/genome/md5/'.substr($md5_hash,0,3).'/'.$md5_hash.'/'; 
#print "$dir_id\n"x10;

if (-e $dir_id){
    for(@ext){
	local $From = "$dir_id/$md5_hash.".$_;
	$_='blastPsiMatTmb' if ($_ =~ /^mat$/);
	local $To   = "$workDir/$workID.".$_;
	copyFile($From, $To);
    }
    for(@extGZ){
	local $From = "$dir_id/$md5_hash.".$_.".gz";
	local $To   = "$workDir/$workID.".$_;
	unzipFile($From, $To);
    }

    # lastly unzip the blast results
    specialUnzip($dir_id, $md5_hash, $workDir, $workID);
}
exit;

sub fasta2md5 {
   my ( $file ) = @_;
   my ( $fh,$line,$seq,$md5 );

   $seq = "";
   open ($fh,$file) or die "cannot open $file:$!";
   while ($line=<$fh>) {
       next if ( $line !~ /\w/ );
       next if ( $line =~ /^\>/ );
       $seq .= $line;
   }
   close $fh;

   $seq =~ s/[^A-Za-z]+//g;
   $seq = uc($seq);
   $md5 = md5_hex($seq);
   
   return $md5;
}


sub copyFile{
    use File::Copy;
    local ($from, $to ) = @_;
    copy($from,$to); 

}

sub unzipFile {

    local ($from, $to ) = @_;
    $command = "gunzip -c $from | cat > $to";
    system ($command);

}

sub specialUnzip{		#     Special case for blast

    local ( $dir_id, $md5_hash, $workDir, $workID ) = @_;
    local $from = "$dir_id/$md5_hash.blasttab.gz";
    local $to   = "$workDir/$workID.blastPsiAli";
    $command = "gunzip -c $from | cat > $to";
    system ($command);


    local $from = "$dir_id/$md5_hash.rdbProf.gz";
    local $to   = "$workDir/$workID.profRdb";
    $command = "gunzip -c $from | cat > $to";
    system ($command);
}
