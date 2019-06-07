#! /usr/bin/perl

#$cmd = "make poll";
$cmd = "make put";

# Cheesy ls wrapper. Dir MUST end in /.
sub dirls($)
{
    my $dir = shift @_;
    my @r = `ls $dir`;
    foreach (@r)
    {
        chomp $_;
        $_ = $dir . $_;
    }
    return @r;
}

@files = ( 'Makefile' );
# push @files, dirls('src');
push @files, 'WritWorthy.lua';
push @files, 'WritWorthy_Alchemy.lua';
push @files, 'WritWorthy_Enchanting.lua';
push @files, 'WritWorthy_Provisioning.lua';
push @files, 'WritWorthy_AutoQuest.lua';
push @files, 'WritWorthy_Log.lua';
push @files, 'WritWorthy_Util.lua';
push @files, 'WritWorthy_I18N.lua';
push @files, 'WritWorthy_Smithing.lua';
push @files, 'WritWorthy_Window.lua';
push @files, 'lang/en.lua';
push @files, 'lang/en2.lua';
push @files, 'Bindings.xml';
push @files, 'lang/en.lua';
print join("\n", @files) . "\n";

@prev_mtime = ();

$sleep_sec      =  2;
$dot_period_sec = 10;
$dot_sleep_sec  =  0;

sub mod_time()
{
    @mtime = ();
    foreach $file (@files)
    {
# print("FILE: $file .\n");
        @x = lstat $file;
        push @mtime, $x[9];
    }
    return @mtime;
}

for ( ; ; )
{
    @mtime = mod_time();

    if (join(" ", @mtime) ne join(" ", @prev_mtime))
    {
        clear_screen();
        print `$cmd 2>&1`;

        print STDERR "\n... waiting for changes ";
    }

    @prev_mtime = mod_time();

    sleep $sleep_sec;

    $dot_sleep_sec += $sleep_sec;
    if ($dot_period_sec <= ++$dot_sleep_sec)
    {
        $dot_sleep_sec = 0;
        print STDERR ".";
    }
}

sub clear_screen()
{
    my $clear      = "\e[2J";
    my $cursorhome = "\e[H";

    print "$clear$cursorhome";
}
