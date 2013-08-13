
role Inline::C[Routine $r, Str $language, Str $code];

use NativeCall;

has int $!setup;
has $!code = "#ifdef WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif
$code";
has $!libname;

method postcircumfix:<( )>(Mu \args) {
    unless $!setup {
        $!setup      = 1;
        my $basename = IO::Spec.catfile( $*TMPDIR, 'inline' );
        $!libname    = $basename ~ "_" ~ $r.name;
        $!libname    = $basename ~ 1000.rand while $!libname.IO.e;
        my $o        = $*VM<config><o>;
        my $so       = $*VM<config><load_ext>;
        if my $CC = open( "$*VM<config><cc> -c $*VM<config><cc_shared> $*VM<config><cc_o_out>$!libname$o $*VM<config><ccflags> -xc -", :w, :p ) or warn $! {
            $CC.print( $!code );
            $CC.close;
            my $l_line = "$*VM<config><ld> $*VM<config><ld_load_flags> $*VM<config><ldflags> " ~
                         "$*VM<config><libs> $*VM<config><ld_out>$!libname$so $!libname$o";
            shell($l_line);
        }
    }
    
    &trait_mod:<is>($r, native => $!libname);
    $r(|args);
}
