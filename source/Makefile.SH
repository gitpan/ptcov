	$BYACC -d perly.y
        ./perly.fixer y.tab.c perly.c
	sed -e 's/fprintf *( *stderr *,/PerlIO_printf(Perl_debug_log,/g' \
	    -e 's/y\.tab/perly/g' perly.c >perly.tmp && mv perly.tmp perly.c
	echo 'extern YYSTYPE yylval;' >>y.tab.h
	cmp -s y.tab.h perly.h && rm -f y.tab.h || mv y.tab.h perly.h