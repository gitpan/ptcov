#! /usr/local/bin/perl 

require("pwd.pl") ; 

sub AbsolutePathName { 

    local($FileName) = @_ ;
 
  my $SaveDir = `pwd` ;
 
  chop($SaveDir) ; 
 
    my $FileNameOnly = pop(@{[split(/\//,$FileName)]}) ; 
    my $FileDir = $FileName; 
    $FileDir =~ s/$FileNameOnly\s*$// ; 
    chop($FileDir) ; 

# check if the file directory is defined 
if( $FileDir eq "" ) 
{ 
    my $AbsolutePath =  $SaveDir . "/" . $FileName ; 
    return( $AbsolutePath ) ; 
} 

# change to the directory specified 
 chdir($FileDir) ; 
 my $CurDir = `pwd` ;
 chop($CurDir) ;  
 
# change back the directory 
chdir($SaveDir) ; 

my $AbsolutePath =  $CurDir . "/" . $FileNameOnly ; 
 return( $AbsolutePath) ; 

}


sub ReadTraceFileFromStdIn { 

    local(%FileDefined) ; 
    local($LineNo,$FileName,$Info) ; 
 
#    open(IN,"./db.out") ; 

while( <STDIN> ) 
{ 

  # check for the format 
  if( /^(\S+)::\S*\((\S+)\)/ ) 
  { 
    # get the filename and the line number 
     $Info = $2 ; 
     # split the info for the line no. and the filename 
     $Info =~ /(\S+):(\d+)/ ; 
     $LineNo = $2 ; 
     $FileName = $1 ; 

   # check if the accessed file is a std file 
   if( ( $FileName =~ /^\s*\/usr\/local\// ) ) 
   {
      # coverage details of the /usr/local/ files not needed  
       next ; 
   }

    # check if the file is accessed the first time 
    if( ! (defined($FileDefined{$FileName}) ) )
    { 
        $FileDefined{$FileName} = AbsolutePathName($FileName) ;
       # check if the file has been accessed in the previous runs 
	if( !( defined($FileAccessed{$FileDefined{$FileName}}) ) ) 
        {
          $FileAccessed{$FileDefined{$FileName}} = 1 ;  
          push(@CoveredFiles,$FileDefined{$FileName}) ;
                      
        }
    }     

    # check if the line has been already recorded 
    next if( defined($LineDefined{$FileDefined{$FileName}}{$LineNo}) ) ;

    # if not record it now 
    $LineDefined{$FileDefined{$FileName}}{$LineNo} = 1 ; 
    push(@{$CoveredLines{$FileDefined{$FileName}}},$LineNo) ; 
   }

}

}

sub DumpTraceInfo { 

    local($CoverageFileName) = @_ ; 

# open the .tracefile for writing 
open(PCOV,"> $CoverageFileName") || 
    PrintFatalError("Cannot open trace file for writing") ; 

# write the filenames initially 
    print PCOV "FILES=" . $CoveredFiles[0] ; 
# dump all the filenames 
foreach $FileCount ( 1 .. $#CoveredFiles)
{ 
  print PCOV "," . $CoveredFiles[$FileCount] ; 
}
 print PCOV "\n" ; 

# dump the linenumbers for each of the file

foreach $FileName (@CoveredFiles) 
{ 
    
    print  PCOV "$CoveredLines{$FileName}[0]" ; 
    foreach $LineCount ( 1 .. $#{$CoveredLines{$FileName}} )
    { 
       print  PCOV ",$CoveredLines{$FileName}[$LineCount]" ; 
     }
     print PCOV "\n" ; 
}
close(PCOV) ;

} 
      
    
sub UpdateTraceInfo { 

local($CoverageFileName) = @_ ; 


# open the coverage file , if it exists 
 open(PCOV,$CoverageFileName) || return ; 
 

# read the tracefile info 
    my $Line ; 
    chop( $Line = <PCOV>) ;

  # get the files that have been covered 
  if( ( $Line =~ /^\s*FILES/) ) 
  { 
    # get all the files that have been covered
    $Line =~ s/\s+//g ; 
    $Line =~ /FILES=(.*)/ ;
    my $Files = $1 ;  
   # get the table of covered files 
     @CoveredFiles = split(/,/,$Files) ;    
  } else 
  { 
      return ; 
  }


# get the coverage for each file 
 foreach $CoveredFile (@CoveredFiles) 
 {

  # tell that the file has been already accessed 
    $FileAccessed{$CoveredFile} = 1 ;  

   chop($Line = <PCOV>) ; 
   my @PreCoveredLines = split(/,/,$Line) ; 
   # check if the line has been taken into account 
   foreach $LineNo (@PreCoveredLines) 
   { 
         # store the line as covered 
           push(@{$CoveredLines{$CoveredFile}},$LineNo) ;
           $LineDefined{$CoveredFile}{$LineNo} = 1 ;  
     
    }          
  }
 
  close(PCOV) ; 
}



sub Main { 


# initialize the pwd 
    initpwd() ; 

# get the filename to store 
    my $CoverageFileName = "/tmp/covfile.$<" ; 

#    print "Entering Trace ... \n" ; 

# update trace info from the previous tracefile 
    UpdateTraceInfo($CoverageFileName) ;   
# read the trace file 
    ReadTraceFileFromStdIn() ;

# dump the trace information 
    DumpTraceInfo($CoverageFileName) ; 
 

}

Main ; 
   
        


