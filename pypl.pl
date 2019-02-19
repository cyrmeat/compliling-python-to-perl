#!/usr/bin/perl -w

# Starting point for COMP[29]041 assignment 1
# http://www.cse.unsw.edu.au/~cs2041/assignments/pypl
# written by z5122763@unsw.edu.au September 2017

# hash to save variable's type, "1" is list, "2" is dictionary
%type = ();

# index for locating where to print "}"
$index = 0;

# "flag = 1" is for sys.stdout.write(), "flag = 0" is for print()
$flag = 0;

# use $special = "\t" to "print" in single-line while/if
$special = "";

# readling line from input
while ($line = <>) {
    chomp $line;

    # change \t to four white spaces
    $line =~ s/\t/    /g;

    # int (remove int)
    $line =~ s/(.*[^p][^r])int\((.*)\)$/$1$2/;

    # change "sys.stdin.readline()" to <STDIN>
    $line =~ s/sys\.stdin\.readline\(\)/\<STDIN\>/;

    # change list[i], dict[i]
    # re(regular expression) to find line with list[i] or dict[i]
    if ($line =~ /^(.*?)(\w+)\[(.*)\](.*)$/){
	$left = $1;
	$ld = $2;
	$position = $3;
	$right = $4;
	# if variable is a list element
	if ($type{$ld} == 1){
	    # if "i" in list[i] is a number, do not add "$" sign
	    if ($position =~ /^\d+$/){
	        $line = $left.$ld."\[$position\]$right";
	    }
	    # if "i" is a variable, add "$"
	    else{
		$line = $left.$ld."\[\$$position\]$right";
	    }
	}
	# if variable is a dictionary element
	elsif ($type{$ld} == 2){
	    # if "i" in dict[i] is a number, do not add "$" sign
            if ($position =~ /^\d+$/){
                $line = $left.$ld."\{$position\}$right";
            }
	    # if "i" is a variable, add "$"
            else{
                $line = $left.$ld."\{\$$position\}$right";
            }
	}
    }
    
    # change len() to real number
    # find line with "len(xxx)"
    if ($line =~ /len\((.*?)\)(.*)$/){
	# $content is the "xxxx" in len(xxxx), $content1 is the "+ 1" in "x = len(xxxx) + 1"
	$content = $1;
	$content1 = $2;
	# remove the "len(xxxx)" part from line
	$line =~ s/(^.*)len.*$/$1/;
	# re to find sample: len([3, 4, 5])
	if ($content =~ /\[(.*)\]/){
	    # split the elements using ",\s*"
	    $things = $1;
	    @eles = split(/,\s*/, $things);
	    # get the length of the list
	    $num = @eles;
	    $line .= "$num";
	    $line .= $content1;
	}
	# sample: len("vervetbetb")
	elsif ($content =~ /\".*\"/){
	    $num = length $content;
	    $line .= "$num";
	    $line .= $content1;
	}
	# sample: len(sys.argv)
	elsif ($content =~ /sys\.argv/){
	    $line .= "\@ARGV";
            $line .= $content1;
	}
	# sample: len(<STDIN>);
	# sample: len(list) or len(string)
	else {
	    # len(list)
	    # @list in perl is the length of a list
	    if ($type{$content} and $type{$content}==1){
		$line .= "\@$content";
                $line .= $content1;
	    }
	    # len(string)
	    # using length "xxxxxxx" can get the length of a string in perl
	    else{
		$num = length $content;
		$line .= "$num";
		$line .= $content1;
	   }
	}
    }
    
    # change sorted() to (sort....)
    # find the line with "sorted(xxx)"
    if ($line =~ /^(.*)sorted\((.*)(\).*)$/){
	$line = $1."\(sort $2$3";
    }

    # change dict.keys() to keys %dict
    if ($line =~ /^(.*\s)(.+)\.keys\(\)(.*)$/){
	$left = $1;
	$middle = $2;
	$right = $3;
	if ($middle =~ /^(.*)\[(.*)\]/){
	    $line = $left."keys \%\{$1\{$2\}\}$right";
	}
	else {
	    $line = $1."keys \%$2$3";
	}
    }

    # use if, elsif, else to seperate different situations, and print the corresponding perl line
    # the first line: #!/usr/bin/python3
    if ($line =~ /^#!/ && $. == 1) {
        # translate #! line
        print "#!/usr/bin/perl -w\n";
    } 

    # comment
    elsif ($line =~ /^\s*(#|$)/) {
        # Blank & comment lines can be passed unchanged
        print "$line\n";
    } 

    # find line with print(......)
    elsif ($line =~ /^(\s*)print\(.*?\)$/){
	$space = $1;
        forindex($space);
	# set0 is a function for print things
	set0($line);
    }
    # subset 1
    # sample: factor1 = 7
    # sample: answer = factor0 * factor1
    elsif ($line =~ /^(\s*)([^=]+) \= ([^=]+[^:]*)$/ && not $line =~ /(while|if)/) {
	$space = $1;
        forindex($space);
	# set1 is a function for assign value to variable
        set1($line);
    }
    # subset 2
    # single=line while, if statement
    elsif ($line =~ /^(\s*)((while|if)[^:]*): (.*)$/){
	$space = $1;
        forindex($space);
	$left = $2;
	$right = $4;
	($symbol, $content) = $left =~ /(while|if) (.*)/;
	$content =~ s/\(//g;
	$content =~ s/\)//g;
	@eles = split" ", $content;
	$textl = "";
	foreach $ele (@eles) {
	    if ($ele =~ /^\d+$/){
                $textl = $textl."$ele ";
            }
            elsif ($ele =~ /[+\-*\/%\<\>\=\!]+/){
                $textl = $textl."$ele ";
            }
	    elsif ($ele =~ /not|or|and/){
		$textl = $textl."$ele ";
	    }
            else {
                $textl = $textl."\$$ele ";
            }
	}
	print "$space$symbol \($textl\) \{\n";
	#$textr = "";
	@sentences = split";", $right;
	foreach $sentence (@sentences){
            $special = "\t";
	    if ($sentence =~ /print/){
		set0($sentence);
	    }
	    else {
		set1($sentence);
	    }
	}
	print "$space\}\n";
    }
    # subset 3
    # multi-line if/while
    elsif ($line =~ /^(\s*)(while|if|elif|else)([^:]*)\:$/){
	$space = $1;
	forindex($space);
	$symbol = $2;
	@eles = split" ", $3;
	$symbol =~ s/elif/elsif/;
	$textl = "";
        foreach $ele (@eles) {
	    $ele =~ s/\(//g;
	    $ele =~ s/\)//g;
            if ($ele =~ /^\d+$/){
                $textl = $textl."$ele ";
            }
            elsif ($ele =~ /[+\-*\/%\<\>\=\!]+/){
                $textl = $textl."$ele ";
            }
            elsif ($ele =~ /not|or|and/){
                $textl = $textl."$ele ";
            } 
            else {
                $textl = $textl."\$$ele ";
            }
        }
	if ($symbol eq "else"){
	    print "$space$symbol \{\n";
	}
	# $symbol == "elsif", "while", "if"
	else{
	    print "$space$symbol \($textl\) \{\n";
	}
    }
    # for i in range(0, 5):
    elsif ($line =~ /^(\s*)for (\S+) in range([^:]+):/){
	$space = $1;
	forindex($space);
	$left = $2;
	$right = $3;
	$right =~ s/\,\s*/\.\./;
	# sample: for i in range(3)
	if ($right =~ /\(([^\.]*)\)/){
	    $num = $1." - 1";
	    $num =~ s/([^\d\s+\-*\/%])/\$$1/;
	    print "$space"."foreach \$$left \(0\.\.$num\) \{\n";
	}
	# sample: for i in range(3, 5)
	else {
	    $right =~ /\((.*)\.\.(.*)\)/;
	    $num = $2." - 1";
	    $num1 = $1;
	    $num =~ s/([^\d\s+\-*\/%])/\$$1/g;
	    $num1 =~ s/([^\d\s+\-*\/%])/\$$1/g;
	    print "$space"."foreach \$$left \($num1\.\.$num\) \{\n";   
	}
    }
    # delete "import sys"
    elsif ($line =~ /^import/){
	# do nothing
    }
    # "sys.stdout.write"
    elsif ($line =~ /^(\s*)sys\.stdout\.write(.*)$/) {
	$space = $1;
        forindex($space);
	$sentence = "print".$2;
	$flag = 1;
	set0($sentence);
    }
    # break
    elsif ($line =~ /^(\s*)break$/){
	forindex($1);
	print "$1"."last\;\n";
    }
    # continue
    elsif ($line =~ /^(\s*)continue$/){
        forindex($1);
	print "$1"."next\;\n";
    }
    # subset 4
    # list append
    elsif ($line =~ /^(\s*)([^.]+).append\((.*)\)/){
        forindex($1);
	$space = $1;
	$left = $2;
	$right = $3;
	if (not $right =~ /^\d+$/){
	    $right = "\$".$right;
	}
	print "$space"."push \@$left, $right\;\n";
    }
    # list pop()
    elsif ($line =~ /^(\s*)([^.]+).pop\((.*)\)/){
	forindex($1);
	$space = $1;
	$left = $2;
        $right = $3;
	# sample: list.pop()
	if ($right eq ''){
	    print "$space"."pop \@$left\;\n";
	}
	# sample: list.pop(3)
        if ($right =~ /^\d+$/){
            print "$space"."splice \@$left, $right, 1\;\n";
        }
    }
    # sample: for line in sys.stdin
    elsif ($line =~ /^(\s*)for (.*) in sys\.stdin/){
	$space = $1;
	forindex($space);
	$left = $2;
	print "$space"."foreach \$$left (<STDIN>) \{\n";
    }
    # sample: for line in (xxxxx)
    elsif ($line =~ /^(\s*)for (.*) in (\(.*\))/){
	forindex($1);
	print "$1"."foreach \$$2 $3 \{\n";
    }

    else {
        # Lines we can't translate are turned into comments
        print "#$line\n";
    }
}

# incase there is no last line to print "}"
while ($index > 0){
    print "\}\n";
    $index = $index - 4;
}

# to print "}"
sub forindex{
    my $space = $_[0];
    my $index1 = length $space;
    my $len = $index - $index1;
    while ($len - 4 >= 0){
        print "$space"."\}\n";
	$len = $len - 4;
    }
    $index = $index1;
}

# print
sub set0{
    my $line1 = $_[0];
    # get $1 as index, $2 as the content of print
    $line1 =~ /^(\s*)print\(.*?\)$/;
    $space = $1; 
    # default end of print in python is "\n"
    my $end = "\\n";
    if ($flag == 1){
        $end = "";
    }
    # sample: print("xxxxxxx") or print("xxxxxxx", end='xxx') or print("xxxxxxx"%xxxx, end='xxx')
    if ($line1 =~ /print\(\"(.*?)\".*\)/){
        my $text = $1;
	# if print(xxxx, end='xxxx'), change default end="\n" to specific end
        if ($line1 =~ /\,\s*end\=.(.*?)..$/){
            $end = $1;
        }
        else{ }
	# delete ", end='xxx'" part from print(xxx, end='xxx')
        $line1 =~ s/\,\s*end\=.*$//;
	# sample: print("%d lines" % line_count)
        if ($line1 =~ /print\(\".*?\"\s*\%\s*(.*?)\)$/){
            my $element = $1;
	    # sample: print("%d xxxx" % (x, x, x))
            if ($element =~ /^\(.*?\)$/){
                $element =~ s/\(//; 
                $element =~ s/\)//;
                my @eles = split ",\*", $element;
                my $eletext = " ";
                foreach $ele (@eles){
		    # x is a digit
                    if ($ele =~ /^\d+$/){
                        $eletext = $eletext."$ele, ";
                    }
		    # x is a variable
                    else {
                        $eletext = $eletext."\$$ele, ";
                    }
                }
		# clean the ", " at the end of $eletext
                $eletext =~ s/\,\s$//;
                print "$space$special"."printf \"$text$end\", $eletext\;\n";
            }
            else {
		#sample: print("%d xxxx" % x)
                if ($element =~ /^\d+$/){
                    print "$space$special"."printf \"$text$end\", $element\;\n";
                }
                else {
                    print "$space$special"."printf \"$text$end\", \$$element\;\n";
                }
            }
        }
	# sample: print("xxxxx", end='xx')
        else{
            print "$space$special"."print \"$text$end\"\;\n";
        }
    }
    # sample: print("xxxxxxx")
    #elsif ($line1 =~ /^(\s*)print\("(.*?)"\)$/){
	#print "$1print \"$2\\n\";\n";
    #}
    # sample: print(xxxxx)
    else {
        if ($line1 =~ /\,\s*end\=.(.*?)..$/){
            $end = $1;
        }
        else{}
	# clean the $line1 to get the elements inside
	$line1 =~ s/^\s*//;
        $line1 =~ s/\,\s*end\=.*$//;
        $line1 =~ s/print\(//;
        $line1 =~ s/\)//;
	# sample: print(xxx + xxx)
        if ($line1 =~ /[+\-*\/%]/){
            my @eles = split " ", $line1;
            my $eletext = "";
            foreach $ele (@eles){
                if ($ele =~ /^\d+$/){
                    $eletext = $eletext."$ele ";
                }
                elsif ($ele =~ /[+\-*\/%]/){
                    $eletext = $eletext."$ele ";
                }
                else {
                    $eletext = $eletext."\$$ele ";
                }
            }
            $eletext =~ s/\s$//;
            print "$space$special"."print $eletext, \"$end\"\;\n";
        }
	# sample: print(xxx, xxxx)
        else{
            my @eles = split(/,\s*/, $line1);
            my $eletext = "";
            foreach $ele (@eles){
                if ($ele =~ /^\d+$/){
                    $eletext = $eletext."$ele ";
                }
                else {
                    $eletext = $eletext."\$$ele ";
                }
            }
            $eletext =~ s/\s$//;
            print "$space$special"."print \"$eletext$end\"\;\n";
        }
    }
    $special = "";
    $flag = 0;
}

# set1 is a function for assign value to variable
sub set1{
    my $line1 = $_[0];
    $line1 =~ /^(\s*)([^=]+) \= ([^=]+[^:])$/;
    my $space = $1;
    my $left = $2;
    my $right = $3;
    # if this line is "list = [1, 3, 5]";
    if ($line =~ /[^=]+ = \[[^\]]*\]/){
        $type{$left} = 1;
        $right =~ s/^\[/\(/;
        $right =~ s/\]$/\)/;
        $left = "\@".$left; 
    }
    # if this line is "dict = {}"
    elsif ($line =~ /[^=]+ = \{.*\}/){
        $type{$left} = 2;
        $right =~ s/^\{/\(/;
        $right =~ s/\}$/\)/;
        $left = "\%".$left;
    }   
    else{
        $left = "\$".$left;
    }   
    if ($right eq '()'){
        next;
    }
    $right =~ s/\,[^\s]/\,\s/g;
    my @eles = split(/\s/, $right);
    #my @eles = split" ", $right;
    my $text = "";
    foreach $ele (@eles){
        if ($ele =~ /^(\(*)([+\-*\/%]*\d+\,*\)*)$/){
            $text = $text."$1$2 ";
        }
        elsif ($ele =~ /^[+\-*\/%]+$/){
	    $ele =~ s/\/\//\//;
            $text = $text."$ele ";
        }
        elsif ($ele =~ /<STDIN>/){
            $text = $text."$ele ";
        }
        # list "pop"
        elsif ($ele =~ /([^.]+)\.pop\((.*)\)$/){
            $left1 = $1;
            $right1 = $2;
            # sample: list.pop()
            if ($right1 eq ''){
                $text = "pop \@$left1";
            }
            # sample: list.pop(3)
            if ($right1 =~ /^\d+$/){
                $text = "splice \@$left1, $right1, 1";
            }
        }
        elsif ($ele =~ /^@/){
            $text = $text."$ele ";
        }
        # sample: lines = sys.stdin.readlines()
        elsif ($ele =~ /sys\.stdin\.readlines\(\)/){
            $text = "<STDIN>";
            $left =~ s/\$//;
            $type{$left} = 1;
            $left = "\@".$left;
        }
        # sample: x = "text"
        elsif ($ele =~ /\".*\"/){
            $text = $text.$ele;
        }
        else {
            $ele =~ /^(\(*)(.*)$/;
            $text = $text."$1\$$2 ";
        }
    } 
    # sample: x = "avc" + "jdoe"
    $text =~ s/\"\+\s*/\"\./g;      
    $text =~ s/\s$//;
    print "$space$special"."$left = $text\;\n";
    $special = "";
}
