#! /usr/local/bin/perl 

# define a fileselection widget
 
 package FileSelection ; 

use Tk ; 

require("pwd.pl") ; 


sub SelectFiles { 

    local($ListBox) = @_ ; 

 my @Indices =  $ListBox->curselection() ; 

    @main::Selections = () ; 
  
 foreach $Index (@Indices)
{ 
   push(@main::Selections,$ListBox->get($Index)) ; 
}

# check if the indices > 0 
  if( $#Indices != -1 ) 
 { 
    $main::Report->entryconfigure( '1' , '-state' , 'normal' ) ; 
 }  

} 


sub CancelFiles { 

    local($ListBox) = @_ ; 

  @main::Selections  = () ; 

# clear the listbox     
    $ListBox->selection('clear' , 0 , 'end' ) ;
# disable the view part  
  $main::Report->entryconfigure( '1' , '-state' , 'disabled' ) ; 

}



sub main'MarkFiles { 

    local($Top) = @_ ; 

# initialize the pwd 
    main'initpwd(); 
 
    $CurrentDirectory = $ENV{PWD} ; 
# Create a label 

   my $Frame = $Top->Frame(-borderwidth => 10 , -bg => 'white'  );
    $Frame->pack(-side => 'top', -expand => 'yes', -fill => 'y');

# create a frame to place the listbox
    my $ListBoxFrame = $Frame->Frame( ) ; 
    $ListBoxFrame->pack( -side => 'top' , -expand => 'yes' ) ; 

    my $YScroll = $ListBoxFrame->Scrollbar( -bg => 'white') ;
    $YScroll->pack(-side => 'right', -fill => 'y');
    my $XScroll = $ListBoxFrame->Scrollbar(-orient => 'horizontal',
                                             -bg => 'white' );
    $XScroll->pack(-side => 'bottom', -fill => 'x');
    my $FileList = $ListBoxFrame->Listbox(
        -width          => 40,
        -height         => 10,
        -yscrollcommand => [$YScroll => 'set'],
        -xscrollcommand => [$XScroll => 'set'],
        -selectmode =>  'multiple'  ,
	-foreground => 'blue' ,
        -selectforeground => 'white' ,
        -selectbackground => 'navyblue' , 
	-bg => 'white' ,	       
        -setgrid        => '1',
    );
    $FileList->pack(-expand => 'yes', -fill => 'y');
    $YScroll->configure(-command => [$FileList => 'yview']);
    $XScroll->configure(-command => [$FileList => 'xview']);

# create the buttons at the bottom of the frame 
  $ButtonFrame = $Frame->Frame( ) ; 
  $ButtonFrame->pack( -side => 'top' ) ; 

# create the select and cancel button 
  my $SelectButton = $ButtonFrame->Button( -text => 'SELECT' , 
					  -relief => 'raised' , 
					 -command => [ \&SelectFiles , $FileList],
					 -padx => 10 , 
                                         -fg => 'blue' , -bg => 'white' 
					  ) ; 

  my $CancelButton = $ButtonFrame->Button( -text => 'CANCEL' , 
					  -relief => 'raised' , 
					  -command => [ \&CancelFiles ,$FileList],
                                          -padx => 10 ,
                                          -fg => 'blue' , -bg => 'white' ,
					  ) ; 

# pack the buttons 
 $SelectButton->pack( -side => 'left' ) ; 
 $CancelButton->pack( -side => 'right' ) ; 


 # insert files in the current directory 
  
# open the coverage file 
    open(COV,$main::StoredCoverageFileName) || 
        main::PrintError("Could not open $StoredCoverageFileName") || return 1;
 
  while( <COV> ) 
 { 
    if( /^FILES=(.*)/ ) 
   { 
      @Files = split(/,/,$1) ; 
      last; 
    }
 }     

   close(COV) ; 

    $FileList->insert('end',@Files) ; 

 }

 1 ; 

