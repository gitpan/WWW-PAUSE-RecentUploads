use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
     NAME              => 'WWW::PAUSE::RecentUploads',
     VERSION_FROM      => 'lib/WWW/PAUSE/RecentUploads.pm', 
     PREREQ_PM         => {
     	URI  					   => 1.35,
     	Carp 					   => 1.04,
     	'HTML::TokeParser::Simple' => 3.15,
     	'LWP::UserAgent'		   => 2.036,
     },
     ($] >= 5.005 ?     
       (ABSTRACT_FROM  => 'lib/WWW/PAUSE/RecentUploads.pm', 
        AUTHOR         => 'Zoffix Znet <zoffix@cpan.org>') : ()),
);
