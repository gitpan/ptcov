#! /usr/local/bin/perl

# using the Tk widget library 

use English;
use Tk; 
use Tk::Dialog;

require("FileSelection.pl") ;  
require("ReportCreation.pl") ; 


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

sub QuitPerlTestCoverage { 

    local($Top) = @_ ; 
  # quit the main window 

  $Top->destroy ;    

}

sub CreateMainMenu { 

 local($Top) = @_ ;     
    
# create a frame first 
my $TopFrame = $Top->Frame(-relief => 'raised', -borderwidth => 2 ,
			-bg => 'white' , -fg => 'blue' , 
			) ; 
# pack the frame 
$TopFrame->pack(-fill => 'x');

# create the menu frame on which the menu sits 
my $MenuFrame = $TopFrame->Frame( -relief => 'sunken' , 
			       -bg => 'white' , -fg => 'blue' ) ; 
$MenuFrame->pack( -side => 'top' , -anchor => 'nw' , -expand => 'yes' , 
		  -fill => 'x' ) ; 

# attach the file button
my $File = $MenuFrame->Menubutton( -text => 'File', -underline => 0 , 
				  -fg => 'blue' , -bg => 'white' );

# attach the analyze report button 

  $Report = $MenuFrame->Menubutton( # this is a test  
                                    -text => 'Report' , -underline => 0 , 
				    -fg => 'blue' , -bg => 'white' ,

				    ) ; 
$Report->command( -label => "View  " ,
                  -state => 'disabled' , 
		  -foreground => 'blue' , 
                   -command => [ 
                                  sub { 
                                        \&ViewReport($Top,$StoredCoverageFileName) ; 
                                  } ] 
				    ) ; 



# create a dummy frame on which list and the canvas sit 
$DummyFrame = $TopFrame->Frame( -fg => 'blue' , -bg => 'white' ) ; 
$DummyFrame->pack( -side => 'top' ) ; 

# create frame for canvas and the list box 
 my $ListFrame = $DummyFrame->Frame( -fg => 'blue' , -bg => 'white' ) ; 
   $ListFrame->pack( -side => 'left' ) ; 
# embed the list box 
   MarkFiles($ListFrame) ; 

# diable the listframe , until 

# create canvas frame 
 $CanvasFrame = $DummyFrame->Frame() ; 
 $CanvasFrame->pack( -side => 'right' ) ;  


# Add load and quit to the menubutton
# $File->command( -label => "Load" , -command => [ \&LoadCoverageFile , $Top , $ListFrame ] , 
#                -foreground => 'blue' , ) ; 
$File->command( -label => "Quit" , -command => [ \&QuitPerlTestCoverage , $Top], 
                -foreground => 'blue' , ) ;  

# pack the menu 
$File->pack(-side=>'left' , -fill => "x"  );
$Report->pack( -side => 'left' , -fill => 'x' , -padx => '30'   ) ; 



# Add a canvas widget at the bottom of the frame , to handle the size
$TopCanvas = $CanvasFrame->Canvas(
        -width        => '10c',
        -height       => '10c',
	-relief       => 'sunken',
        -bd => 2 , 
	-bg => 'white' 			  
			  );
# pack it below the frame 
$TopCanvas->pack(-side => "right" ) ;  

my $BitMap =  "$ENV{PTCOV_PATH}/images/PerlTestCov.bmp" ;
# create a bitmap for the perl test cov
$TopCanvas->create(qw(bitmap  5c 5c ),
	          -bitmap => "@" .  "$BitMap" , qw( -foreground skyblue ) , 
                   qw(-tags item));

my @text = ( "text" , "9.8c" , "9.8c" , "-text" , "Baskar S" ) ;
$TopCanvas->create( @text ,  -fill => 'blue' , -anchor => 'se') ;  
	    


# create a text widget 
    $Text = $Top->Text() ; 
# get the font details 
    $DefaultFont = $Text->cget( '-font' )  ; 
# get the exact font details 
    $DefaultExpandedFonts = `xlsfonts -m -fn \"$DefaultFont\" ` ; 
# get the height of the font 
    $DefaultFontHeight = ${[split(/-/,$DefaultExpandedFonts)]}[8] / 10  ; 
# get the width of the font 
    $DefaultFontWidth = (${[split(/-/,$DefaultExpandedFonts)]}[12])/10 ;
# get the dots/mm 
    $DefaultDotsPerMm = ( ${[split(/-/,$DefaultExpandedFonts)]}[10]/25.3 ) ;  

# bind the keyboard activity on the text to none

# destroy the widget 
    $Text->destroy() ; 


}




sub ViewCoverage { 
 
# Create a main window 
  $Top = MainWindow->new ; 

$Top->title("Perl Test Coverage") ; 

# create the menu at the top of the window 
CreateMainMenu($Top) ;

 MainLoop ; 


}


1;
