#! /usr/local/bin/perl 

sub CollectCoverage { 

    local($FileName,@Executable) = @_ ; 

# check if the filename is readable and writable 
if( ( -f $FileName ) && 
    ( !( -r $FileName ) || !( -w $FileName ) ) )
{ 
  print "ERROR >> Coverage File $FileName needs read and write permissions  \n" ; 
  return ; 
}

# copy the file , if it exists
if( ( -f $FileName ) ) 
{ 
 
  my $Copy = "cp $FileName /tmp/covfile.$<" ; 
  `$Copy` ; 
  `sleep 1` ;
}  


$dir_path = $ENV{HOME} . "/.perldb"  ;  

# create the perldb in the current  directory 
open(PDB,"> $dir_path") || die "ERROR >> Current directory should be writable \n" ; 

print PDB 
     "&parse_options(\"NonStop=1 LineInfo=|$ENV{PTCOV_PATH}/scripts/ReadTraceFile.pl\"); \n" ; 
print PDB "sub afterinit { \$trace = 1; } \n " ; 

close(PDB) ; 

# create the executable string 
foreach $Element (@Executable) 
{ 
   $Execute .= " " . $Element ; 
}

# bind a dummy wrapper , to handle the execution trace of first and last lines
open(DUMMY,"> /tmp/.Dummy.$<.pl") ;   

    print DUMMY "#!/usr/local/bin/perl \n" ; 
print DUMMY "$Execute \n" ; 

# execute !!

 system("/usr/local/bin/perl -d $Execute") ; 

# remove the perldb 
 `rm -rf .perldb ` ; 

# copy the coverage file to the file specified
`sync` ;  
`sleep 1` ; 
`cp /tmp/covfile.$< $FileName` ; 
 `rm -rf /tmp/covfile.$< ` ;
`rm -rf  /tmp/.Dummy.$<.pl" `; 


}

1;



     


