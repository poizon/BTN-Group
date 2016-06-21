package misc;

use Data::Dumper;

do './admin/connect';

our $site_domain = ($ENV{HTTP_HOST} =~ m!(www\.)?(.*)!is)[1];
our $db = [
	{
	dsn => "dbi:mysql:dbname=$DBname;host=$DBhost",
	login => $DBuser,
	password => $DBpassword,
	RaiseError => 0
	}
];

###############################################################################
sub handler {
	my ($pwf, $m, @p) = @_;
	$pwf->db->faq->order('id desc')->limit(2)->to_tmpl('right_faq');

	my $limit_left_news = $pwf->db->const->where(name=>'limit_left_news')->onerow->value->get;
	$pwf->db->news->where(press=>0)->order('registered DESC')->limit($limit_left_news)->to_tmpl('left_news');

	$pwf->db->house_list->where(enabled=>1, top=>1)->order('RAND()')->limit(1)->to_tmpl('left_objects');
	foreach my $h (@{$pwf->{TMPL_VARS}->{left_objects}}) {
		if ($h->{img}) {
			$h->{img} =~ m|^(.+?)\.(.+)$|is;
			$h->{preview} = "$1\_preview.$2";
		}
	}

	$pwf->db->ready_objects->where(top=>1)->order('RAND()')->limit(1)->to_tmpl('left_ready_objects');
	foreach my $h (@{$pwf->{TMPL_VARS}->{left_ready_objects}}) {
		if ($h->{img}) {
			$h->{img} =~ m|^(.+?)\.(.+)$|is;
			$h->{preview} = "$1\_preview.$2";
		}
	}

	$pwf->db->partners->order('id desc')->to_tmpl('partners');

	$pwf->db->const->where(name=>'name_ready_objects')->onerow->value->to_tmpl('name_ready_objects');
	$pwf->db->const->where(name=>'feedback_email')->onerow->to_tmpl('feedback');
	$pwf->db->const->where(name=>'liveinternet')->onerow->to_tmpl('liveinternet');
	$pwf->db->const->where(name=>'banner_code')->onerow->to_tmpl('banner_code');
	$pwf->db->const->where(name=>'partners_header')->onerow->to_tmpl('partners_header');
	$pwf->db->static->where(id=>2)->onerow->to_tmpl('contacts');

	$pwf->db->promo->fields('promo_title TITLE, promo_keywords KEYWORDS, promo_description DESCRIPTION, promo_body BODY')->where(url=>$ENV{REQUEST_URI})->onerow->to_tmpl('promo');
	if (!$pwf->{TMPL_VARS}->{promo}->{TITLE}) {
		my $uri = ($ENV{REQUEST_URI}=~m!^(.*)/.*$!)[0];
		$pwf->db->promo->fields('promo_title TITLE, promo_keywords KEYWORDS, promo_description DESCRIPTION, promo_body BODY')->where(url=>$uri)->onerow->to_tmpl('promo');
	}

	return undef;
}
###############################################################################

return 1;
