#! /usr/local/bin/perl 

use Tk ; 
 require("Text.pl") ; 

sub PrintError { 

    local($String) = @_ ; 
      my $Dialog = $Top->Dialog(
			     -title => 'Error' , 
			     -text => $String , 
                             -bitmap => 'error' ,
			     -fg => 'blue' , 
			     -bg => 'white' , 
			     -button_label => [ 'OK' ] ) ; 
  $Dialog->Show( -global ) ; 

    return 1 ; 
}

sub ReadCoverageFile { 

    local($CoverageFileName,@WantedFiles) = @_ ; 

# open the coverage file name 
    open(COV,$CoverageFileName) || 
	PrintError("Cannot open $CoverageFileName ") || return 0 ; 

# read the first line 
    $Line = <COV> ; 
  # get the files that have been covered 
  if( ( $Line =~ /^\s*FILES/) ) 
  { 
    # get all the files that have been covered
    $Line =~ s/\s+//g ; 
    $Line =~ /FILES=(.*)/ ; 
   # get the table of covered files 
    @CoveredFiles = split(/,/,$1) ; 
   } else 
   { 
      PrintError("Coverage file $CoverageFileName corrupted ") ;
      return 0 ;  
    } 

# get the wanted files into the hash 
  my %SelectedFiles ; 
 foreach $File (@WantedFiles)
 { 
     $SelectedFiles{$File} = 1 ; 
 }      
# get the coverage for each file 
 foreach $CoveredFile (@CoveredFiles) 
 { 
     $Line = <COV> ; 
  # check if the file needs to be parsed 
   if( defined($SelectedFiles{$CoveredFile}) ) 
   { 
     # process the count for valid covered lines
     @{$CoveredLines{$CoveredFile}} = ProcessValidCoveredLines($Line,$CoveredFile) ; 
   }
 }

# close the file 
    close(COV) ; 

    return 1 ; 
} 

sub ProcessValidCoveredLines { 

    local($CoveredLinesList,$FileName) = @_ ; 

# split the line and store it 
 my @ActualCoveredLines ;
 my @TextLines ; 
 my %CoveredLines ;
 my $StringCompleted = 1 ; 
 my $PrevStringQuote = "" ; 
    my $Line = 0 ; 
 
foreach $Line (@{[split(/,/,$CoveredLinesList)]})
 { 
     $Line =~ /^\s*(\d+)\s*$/  ; 
     $CoveredLines{$1} = 1 ; 
 }


  open(IN,$FileName) || PrintError("Cannot open $FileName in read mode \n") || return 0;

# get the platform 
  my $Platform = `$ENV{PTCOV_PATH}/scripts/getarch` ;  
  chop($Platform) ;
# run the special perl interpreter over the file 
 open(LIN,"$ENV{PTCOV_PATH}/binaries/" . $Platform . "/GetLineInfo -c $FileName |") || 
        PrintError("Could not parse $FileName") || return 0; 

# read the line info, and fill the hash 
while( <LIN> ) 
{ 
  if( /EXEC\s*(\d+)/ ) 
  { 
      $ExecList{$FileName}{$1} = 1 ;
  } elsif( /DECL\s*(\d+)/ )
  { 
      $DeclList{$FileName}{$1} = 1 ; 
  } elsif( /syntax\s*OK/ )
  { 
    # compilation has gone through OK  
     next; 
   } else   
    { 
      PrintError("Compilation error parsing $FileName.Please use 'perl -c $FileName ' to verify \n") ;    
      return 0; 
    }

}

 my $LookForCoveredLine = 0 ;  

# read the text file 
  while(( $TextLine = <IN>) ) 
  { 
      
      $Line++ ;

    if( ( $LookForCoveredLine == 0 ) && ( defined($ExecList{$FileName}{$Line}) )  ) 
   {  
       $LookForCoveredLine = 1 ; 
    } 

    if( $LookForCoveredLine == 0 ) 
   { 
       next ; 
    } 
    
    # check if the line is covered     
     next if( !( defined($CoveredLines{$Line})) ) ; 
 
#      print " Line No. $Line \n" ; 
# leave out if it's a { , } 
    next if( ( $TextLine =~ /^\s*(\}\s*)+\s*(\#.*)*\s*$/ ) ) ;
    next if( ( $TextLine =~ /^\s*(\{\s*)+\s*(\#.*)*\s*$/ ) ) ;
    next if( ( $TextLine =~ /^\s*(\}\s*)*\s*(else|elsif)\s*(\{\s*)*\s*(\#.*)*\s*$/) ) ;   
  
    
    push(@ActualCoveredLines,$Line) ;

    # now reset the covered line flag 
      $LookForCoveredLine = 0; 
 
   
 }

    return (@ActualCoveredLines) ; 

}

sub GetTotalLines { 

    local($FileName) = @_ ; 

# open the file 
 open(FIL,$FileName) || PrintError("Cannot open $Filename for reading") || return 0 ; 
# set it to read till ; 
    my $PhysicalLineCount = 0 ; 
    my $ActualLineCount = 0 ; 
    my $CarriedOverOpeningBraces = 0 ;  
    my $StringCompleted = 1 ; 
    my $PrevStringQuote = "" ; 


while( <FIL> ) 
{ 
     
  $PhysicalLineCount++;
  
   my $Line = $_ ;

# move ahead if it's a declaration 
  next if(  defined($DeclList{$FileName}{$PhysicalLineCount}) ) ; 
# leave out  all the comments
     next if( ( $Line =~ /^\s*\#(.*)/ ) ) ; 
 # check if the line has nothing but {
     next if( ($Line =~ /^\s*(\{\s*)+\s*(\#.*)*\s*$/) ) ;

 # check if it's a blank line 
  next if( ($Line =~ /^\s*$/) ) ; 

 # check if the line has nothing but } 
    next if( ($Line =~ /^\s*(\}\s*)+\s*(\#.*)*\s*$/) ) ;
# leave out else statements 
   next if( ( $Line =~ /^\s*(\}\s*)*\s*(else|elsif)\s*(\{\s*)*\s*(\#.*)*\s*$/) ) ;      
 
if( ( defined($ExecList{$FileName}{$PhysicalLineCount}) )  )
{ 

   # if defined as an executable line 
    $ActualLineCount++ ; 
}




### All statements below are executable statements

 push(@{$PhysicalToActualLineMapping{$FileName}[$ActualLineCount]},
             $PhysicalLineCount) ; 
 $ActualLineForPhysicalLine{$FileName}{$PhysicalLineCount} = 
            $ActualLineCount ;


}

 $TotalLines{$FileName} = $ActualLineCount  ;    
return 1 ; 
} 


sub CalculateCoverageForFile { 

    local($FileName) = @_ ; 

# initialize the total line 
$TotalLinesInSuite = 0 ; 
$TotalCoveredLinesInSuite = 0 ; 

# get the physical line covered from the coverage file
 foreach $PhysicalCoveredLine (@{$CoveredLines{$FileName}})
{ 
  # get the actual line to which this physical line is attached 
  my $ActualLine =  
    $ActualLineForPhysicalLine{$FileName}{$PhysicalCoveredLine} ; 
  # push the lines to the  
  push(@{$DisplayCoveredLines{$FileName}},
       @{$PhysicalToActualLineMapping{$FileName}[$ActualLine]}) ;

}


# coverage for file 
 $PercentageCoverage{$FileName} = 100 * (($#{$CoveredLines{$FileName}} + 1)/
                                         $TotalLines{$FileName}) ; 

# get the total lines in all the files 
$TotalLinesInSuite +=  $TotalLines{$FileName} ; 
$TotalCoveredLinesInSuite += ($#{$CoveredLines{$FileName}} + 1) ; 

return 1 ; 

}  
 

sub ShowUnCoveredLines { 

    local($Text,$Top,$FileName) = @_ ; 

    DumpFile($Top,$FileName,@{$DisplayCoveredLines{$FileName}}) ; 

}

sub MailReportToMailIds { 

    local($Widget,$MailIds,$Window,$CoverageFileName) = @_ ; 


# mail 
    `mail "$MailIds" < $CoverageFileName ` ; 
# remove the file 
    `rm $CoverageFileName ` ; 


# destroy the window 
 $Window->destroy() ;  

}


sub MailReport { 

    local($Top,$Text) = @_ ; 

my $CoverageFile = "/tmp/CovReport.$$" ; 
# save the file 
    open(REP,"> $CoverageFile") ; 

my $TextInfo = $Text->get('0.0' , 'end') ;
    print REP $TextInfo ; 

    close(REP) ; 

# get the mail ids 
    GetInputAndAct($Top,"Mail Command","Give the mail id's",*MailReportToMailIds,$CoverageFile) ; 

}

  
sub PrintReport { 

    local($Top,$Text) = @_; 

my $CoverageFile = "/tmp/CovReport.$$" ; 
# save the file 
    open(REP,"> $CoverageFile") ; 

my $TextInfo = $Text->get('0.0' , 'end') ;
    print REP $TextInfo ; 

    close(REP) ; 

# print the file 
 GetInputAndAct($Top,"Print Command","Give Print Command",*PrintFiles,$CoverageFile) ; 

}



sub GenerateReport { 

    local($Top,@WantedFiles) = @_ ; 

# create a text widget and insert the report 
# create a top level window 
    my $WFile = $Top->Toplevel ; 
    
 $WFile->title("Test Coverage Report") ;  

# create the menu frame on which the menu sits 
my $MenuFrame = $WFile->Frame( -relief => 'sunken' , 
			       -bg => 'white' , -fg => 'blue' ) ; 
 $MenuFrame->pack( -side => 'top' , -anchor => 'nw' , -expand => 'yes' , 
		  -fill => 'x' ) ; 

# attach the file button
my $File = $MenuFrame->Menubutton( -text => 'File', -underline => 0 , 
				  -fg => 'blue' , -bg => 'white' );

 

$File->pack( -side => 'left' , -fill => 'x' ) ; 



# create a frame for text 
$TextFrame = $WFile->Frame() ; 
$TextFrame->pack( -side => 'top' ) ;  

# attach a text widget to it 
 my $Text = $WFile->Text( -foreground => blue , 
	             -background => white , 
		     -width => 50 , 
		     -height => 32 ,
		     -wrap => 'none' ) ;


# set the Y Scroll bar 
  my $YScroll = $WFile->Scrollbar(-command => [$Text => 'yview']);
  $Text->configure(-yscrollcommand => [$YScroll => 'set']);
  $YScroll->pack(-side => 'right', -fill => 'y');

# set the X scroll bar 
  my $XScroll = $WFile->Scrollbar(-command => [$Text => 'xview'] , 
				   -orient => 'horiz' );
  $Text->configure(-xscrollcommand => [$XScroll => 'set']);
  $XScroll->pack(-side => 'bottom', -fill => 'x');


  $Text->pack(-expand => 'yes', -fill => 'both');
  $Text->pack(-side => 'top' ) ; 

# Add load and quit to the menubutton
$File->command( -label => "Print" , 
    -command => [ \&PrintReport , $Top, $Text ]) ;
$File->command( -label => "Mail" , 
	       -command => [ \&MailReport , $Top , $Text ] ) ; 
$File->command( -label => "Quit" , -command => [ $WFile => 'destroy' ]) ;


# dump the report

# print the header 
    $Line = "---------------------+-------+---------+---------+\n" ; 
 # insert the line 
 $Text->insert('end',$Line) ;     

 my $Line = "      FileName       | Total | Covered | Coverage|\n" ; 
 # insert the line 
 $Text->insert('end',$Line) ; 
    $Line = "---------------------+-------+---------+---------+\n" ; 
 # insert the line 
 $Text->insert('end',$Line) ;     

    my $TextLine = 4 ; 
 foreach $FileName (@WantedFiles) 
 {
   # to allow bind access it . Kludgy :-( ... I know!
     $GlobalFileName = $FileName ; 
   my $TrimFileName =  pop(@{[split(/\//,$FileName)]}) ; 
   $Line = sprintf("%20s |%5d  |%5d    |%.2f %1s  |\n",$TrimFileName,
		   $TotalLines{$FileName},($#{$CoveredLines{$FileName}} +1),
                   $PercentageCoverage{$FileName},"%") ; 
   # insert the line 
   $Text->insert('end',$Line) ;
   # create a tag 
   $Text->tag( 'add' , $TrimFileName , $TextLine . ".0" , $TextLine . ".end" );
   # bind the tag to call the dump file 
   $Text->tag( 'bind' , $TrimFileName , '<Any-Enter>' => 
                sub { shift->tag('configure', $TrimFileName,
                      -background => 'navyblue' , 
                      -foreground => 'white' )} ) ; 
   $Text->tag( 'bind' , $TrimFileName , '<Any-Leave>' => 
                sub { shift->tag('configure', $TrimFileName,
                       -background => 'white' , 
                      -foreground => 'blue' )} ) ;    		

   $Text->tag( 'bind' , $TrimFileName , '<Double-1>' => [ 
                      \&ShowUnCoveredLines , $Top , $FileName ] );  
               		  
   $TextLine++ ;        		
      
 }

# print the total coverage  
# print the header 
    $Line = "---------------------+-------+---------+---------+\n" ; 
 # insert the line 
 $Text->insert('end',$Line) ;  
   
 my $PercentageCoverageInSuite = 100 * ( $TotalCoveredLinesInSuite / 
					$TotalLinesInSuite ) ; 

   $Line = sprintf("%20s |%5d  |%5d    |%.2f %1s  |\n","Coverage Summary",
		   $TotalLinesInSuite,$TotalCoveredLinesInSuite,
                   $PercentageCoverageInSuite,"%") ; 
   # insert the line 
   $Text->insert('end',$Line) ;

# print the tail 
    $Line = "=====================+=======+=========+=========+\n" ; 
 # insert the line 
 $Text->insert('end',$Line) ;  

 $Text->configure( -state => 'disabled' ) ;  

}




sub CalculateCoverage { 

    local($Top,$CoverageFileName,@WantedFiles) = @_ ; 

    my $AllIsFine = 1 ; 
# read the coverage file 
    $AllIsFine &= ReadCoverageFile($CoverageFileName,@WantedFiles) ;
 
  foreach $WantedFile (@WantedFiles) 
  { 
      $AllIsFine &= GetTotalLines($WantedFile) ;       
      $AllIsFine &= CalculateCoverageForFile($WantedFile) ;
  }
 
 if( $AllIsFine == 1 ) 
{ 
  # generate the report now 
  GenerateReport($Top,@WantedFiles) ;
}     

}

 sub ViewReport { 

    local($Top,$CoverageFileName) = @_ ; 
# create the top level window 
#     $Top = MainWindow->new ;
    

    my @WantedFiles = @main::Selections ; 

    CalculateCoverage($Top,$CoverageFileName,@WantedFiles) ; 
}




 1; 


# GetTotalLines("./x.pl") ; 




   



  



 



