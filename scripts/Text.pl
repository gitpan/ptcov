#! /usr/local/bin/perl 

use Tk ; 


sub LoadTextWidget { 

local($Text,$FileName) = @_ ; 
my $Line  ;

# open the file 
open(IN,$FileName) ; 

my $Count = 1 ; 
 
while( <IN> ) 
{ 
    $Line = sprintf("%5d | %s",$Count,$_) ; 
    $Text->insert('end',$Line) ;
    $Count++ ; 
}


$TotalLines{$FileName} = $Count ; 

# close the file 
close(IN) ; 

}



sub AttachTags { 

    local($Canvas,$FileName,@LinesCovered) = @_ ; 
    local(%CoveredLines) ; 
    local(@TextLines) ; 
    my $Line; 

 open(IN,$FileName) ; 

 foreach $Line (@LinesCovered) 
 { 
     $CoveredLines{$Line} = 1 ;
   # get the actual line, that's attached to the physical line 
     $ActualLine = $ActualLineForPhysicalLine{$FileName}{$Line} ; 
   # set the flag for all the physical lines attached to the actual line 
     foreach $CovLine (@{$PhysicalToActualLineMapping{$FileName}[$ActualLine]})
     {
	 $CoveredLines{$CovLine} = 1 ;
      } 
   
 }

    $Line = 0 ; 
while(($TextLine =  <IN>) )
{ # while .. 
    
    $Line++ ; 

    # check if the line is covered     
    next if( defined($CoveredLines{$Line}) ) ; 
 
     # leave out if it's a declaration 
    next if( defined($DeclList{$FileName}{$Line}) )  ;  
   
   # leave out if it's a {, }  
    next if( (  $TextLine =~ /^\s*(\}\s*)+\s*(\#.*)*\s*$/ ) ) ;
    next if( (  $TextLine =~ /^\s*(\{\s*)+\s*(\#.*)*\s*$/ ) ) ;   
 # check for blank lines
   next if( (  $TextLine =~ /^\s*$/ ) ) ;   

 # leave out else statements 
   next if( ( $TextLine =~ /^\s*(\}\s*)*\s*(else|elsif)\s*(\{\s*)*\s*(\#.*)*\s*$/) ) ;   
 
  # check if the line is a comment 
    if( ( $TextLine =~ /^\s*\#/ ) ) 
     { 
      # configure the tag 
	 $Canvas->itemconfigure( $Tag[$Line] , -fill => 'gray' ) ; 
         next ;   
     }


   # if all have failed , attach the uncovered tag
  # create a rectangular bar 
     next if( (  $TextLine =~ /^\s*\}\s*$/ ) ) ; 
    $Canvas->create( 'rectangle' , 
                       $LineXCoord[$Line] . "m"  , $LineYCoord[$Line] . "p"  ,
                       $PostScriptWidth{$Canvas} , 
                       ($LineYCoord[$Line] + $DefaultFontHeight) . "p"  ,
                        -fill => 'lightblue'  , -outline => 'lightblue'
                        ) ;   
# get the text from the tag 
    $TextData = $Canvas->itemcget( $Tag[$Line] , '-text' ) ; 
# delete the tag 
#    $Canvas->delete('$Line' ) ; 
# recreate the text 
    $Canvas->create( 'text' ,               
                      $LineXCoord[$Line] . "m"  , $LineYCoord[$Line] . "p"  ,
		     -text => $TextData , -fill => 'blue' , -anchor => 'nw' ) ; 
        
#     	 $Canvas->itemconfigure( $Line , # -stipple => 'gray50' , 
#          -fill => 'red' , 
#	-font => '-adobe-courier-bold-o-normal--14-140-75-75-m-90-iso8859-1');
  }

 }


sub PrintFiles { 

    local($Widget,$PrintCommand,$Window,@Files) = @_ ; 

# print the files  
foreach $File (@Files) 
{ 
    `$PrintCommand $File`; 
# remove the page 
    `rm -rf $File` ; 
}
# destroy the window 
$Window->destroy() ;  

}

sub PrintText { 

    local($Top,$Canvas) = @_ ; 
    local($y) ; 
    local(@Files) ; 
    my $PageCount = 0 ; 

# 842p is the height of a A4 size page , but use 700+  , to give better 
# room space . 

my $PageLength = 700 + (700 % $DefaultFontHeight )  ;  

 for($y=0;$y<=$PostScriptHeight{$Canvas};$y += $PageLength ) 
 {  
  
# dump into A4 size ps pages 
     $Canvas->postscript( "-width" , "595" . "p"  ,
                         "-height" , $PageLength . "p" ,  
		         "-y" , $y . "p" ,     
                         "-file" , "/tmp/$PageCount.ps" ) ;
     push(@Files,"/tmp/$PageCount.ps") ; 
     $PageCount++ ;  
 }

# call the getinput and act function 
    GetInputAndAct($Top,"Print Command","Give Print Command",*PrintFiles,@Files) ; 

}


sub GetInputAndAct { 

    local($Top,$ActionTitle,$LabelText,*OkAction,@Args) = @_ ; 

# ask for the printer name from the user 
 my $PrinterWin = $Top->Toplevel ;
    $PrinterWin->title($ActionTitle) ; 

# put a label and an entry into the window with a OK cancel button 
    my $LabelFrame = $PrinterWin->Frame( -bg => 'white' ) ; 
    $LabelFrame->pack( -side => 'top' , -fill => 'x' ) ; 

my $Label = $LabelFrame->Label( -text => $LabelText , 
                                -relief => 'sunken' ,
			        -padx => '15' , 
			        -pady => '30' , 
                                -bd => '2' ,  
			        -fg => 'blue' , 
			        -bg => 'white' , 
                               ) ;  

my $Entry = $LabelFrame->Entry( -textvariable => \$EntryValue , 
			        -relief => 'raised' ,
			        -width => '40' , 
			       -fg => 'blue' , 
			       -bg => 'white' , 
			       -bd => '2' ) ; 
  
    $Label->pack( -side => 'left' ) ; 
    $Entry->pack( -side => 'right' ) ; 
    $Entry->bind( '<Return>' => 
          [ 
              sub { 
		     local($Widget,$Window,*OkAction,@Args) = @_ ; 
                     &{*OkAction}($Widget,$EntryValue, $Window,@Args);
                     $EntryValue = "" ; 
		 } ,
              $PrinterWin , *OkAction , @Args ] ) ;  
                 
 
# create the button frame 
    my $ButtonFrame = $PrinterWin->Frame( -bg => 'white' ) ; 
    $ButtonFrame->pack( -side => 'top' , -fill => 'both'   ) ; 

# place the buttons
my $OkButton = $ButtonFrame->Button( -text => 'OK' ,  
				     -fg => 'blue' , 
				     -bg => 'white' ,
				      -width => '10' , 
				      -pady => '5' , 
					 -padx => '2' , 
				  -command => [ 
                            sub { 
                		     local($Widget,$Window,*OkAction,@Args) = @_ ; 
                                  &{*OkAction}($Widget,$EntryValue, $Window,@Args);
				     $EntryValue = "" ; 
		                } ,
                                $OkButton , $PrinterWin , *OkAction , @Args ] ) ;  
  
					        
my $CancelButton = $ButtonFrame->Button( -text => 'CANCEL' ,
					 -fg => 'blue' , 
				         -bg => 'white' ,
					 -width => '10' , 
					 -pady => '5' , 
					 -padx => '2' , 
		                 -command => [ $PrinterWin => 'destroy' ]); 

# pack 
    $OkButton->pack( -side => 'left' ) ; 
    $CancelButton->pack( -side => 'right' ) ; 

 

}


sub LoadCanvasWidget { 

    local($Canvas,$FileName) = @_ ; 

   
    my $YIncrement = $DefaultFontHeight ; 
    my $YStart = $DefaultFontHeight ;
    my $XIncrement = $DefaultFontWidth ; 

    my @text ;
# open the file 
open(FIL,$FileName) || PrintError("Cannot open $FileName ") ; 
 
    my $MaxLength = 0 ; 
    my $Line = 0 ;
    my $String ; 
    my $LineNoStr ; 
 while( <FIL> ) 
 { 
     $Line++ ; 

     $LineNoStr = sprintf("%5d | ",$Line) ;   
     $String =  $_ ;
     # add the line number to it 
#     $String = $LineNoStr . $String ; 
     $XStart = ( length($String) * $XIncrement ) / 2 ;
  # get the max line length  
   if( length($String) > $MaxLength )
  { 
     $MaxLength = length($String) ; 
   }
     
     
   @text = ( "text" , "5m" , $YStart . "p" , "-text" , $String ) ; 
   $Canvas->create( @text , 
            -fill => 'blue' , -anchor => 'nw', 
	    -tags => ('tag_' . $Line)   ) ;
   # store the x and the y co-ordinates 
   $LineXCoord[$Line] = 5  ; 
   $LineYCoord[$Line] =  $YStart ;    
   $Tag[$Line] = 'tag_' . $Line ;  

   $YStart += $YIncrement ;  
 }

# set the canvas's scroll region 
 $Canvas->configure( -scrollregion => 
                   [ '0c' , '0c' , ($MaxLength*$XIncrement) . "p" ,   
		    ($YStart + $YIncrement ) . "p" ] ) ;
# set the height and the width for the postscript to print 
$PostScriptHeight{$Canvas} = ( $YStart + $YIncrement ) . "p" ; 
$PostScriptWidth{$Canvas} = ($MaxLength*$XIncrement) . "p" ; 
 
}
     

 
sub DumpFile { 

    local($Top,$FileName,@LinesCovered) = @_ ;



# create a top level window 
    my $WFile = $Top->Toplevel ; 
    
# create the menu frame on which the menu sits 
my $MenuFrame = $WFile->Frame( -relief => 'sunken' , 
			       -bg => 'white' , -fg => 'blue' ) ; 
 $MenuFrame->pack( -side => 'top' , -anchor => 'nw' , -expand => 'yes' , 
		  -fill => 'x' ) ; 

# attach the file button
my $File = $MenuFrame->Menubutton( -text => 'File', -underline => 0 , 
				  -fg => 'blue' , -bg => 'white' );

 

    $File->pack( -side => 'left' , -fill => 'x' ) ; 

 $WFile->title($FileName) ;  

# create a frame 
my $CanvasFrame = $WFile->Frame() ; 
$CanvasFrame->pack( -side => 'top' ) ;  
# attach the text to a canvas for printing 
 my $Canvas = $CanvasFrame->Canvas(
	                            -width        => '25c',
                                    -height       => '15c',
				    -scrollregion => 
                                     [ '0c' , '0c' , '15c' , '10c' ] , 
	                            -relief       => 'sunken',
                                    -bd => 2 , 
	                             -bg => 'white' 		   
				     ); 

    $Canvas->pack( -side => 'left'    ) ;
 
# Add load and quit to the menubutton
$File->command( -label => "Print" , 
    -command => [ \&PrintText , $Top , $Canvas ]) ; 
$File->command( -label => "Quit" , -command => [ $WFile => 'destroy' ]) ;

  
# attach a text widget to it 
# my $Text = $Canvas->Text( -foreground => blue , 
#	             -background => white , 
#		     -width => 100 , 
#		     -height => 32 , 
#		     -wrap => 'none' ) ;

#  $Text->pack(-expand => 'yes', -fill => 'both');
#  $Text->pack(-side => 'top' ) ; 

# create a dummy frame 
  $DummyFrame = $WFile->Frame() ;
# pack it 
  $DummyFrame->pack( -side => 'bottom' , -fill => 'x'  ) ; 

# set the Y Scroll bar 
  my $YScroll = $CanvasFrame->Scrollbar(-command => [$Canvas => 'yview']);
  $Canvas->configure(-yscrollcommand => [$YScroll => 'set']);
  $YScroll->pack(-side => 'right', -fill => 'y');

# set the X scroll bar 
  my $XScroll = $DummyFrame->Scrollbar(-command => [$Canvas => 'xview'] , 
				   -orient => 'horiz' );
  $Canvas->configure(-xscrollcommand => [$XScroll => 'set']);
  $XScroll->pack(-side => 'bottom', -fill => 'x');

# Load a file 

 LoadCanvasWidget($Canvas,$FileName) ; 

# attach the tags now
 AttachTags($Canvas,$FileName,@LinesCovered); 

 

}



sub ProcessFile { 

    local($Top,$FileName,$DataFile) = @_ ; 
# open the file 

    open(IN,$DataFile) ; 

# get the covered lines 
 while( <IN> ) 
{ 
    chop() ; 
    push(@LinesCovered,$_) ; 

}

# call the dump file routine 
DumpFile($Top,$FileName,@LinesCovered) ;

}


sub Main2 { 

# create the top level window 
    $Top = MainWindow->new ;

    ProcessFile($Top,"initialize.pl","data") ;  

}
	    

1; 
# Main ; 



