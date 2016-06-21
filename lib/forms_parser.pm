package FormUtils;

#use strict;
use warnings;

use CGI::Cookie;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use DBI;
use JSON::XS;

BEGIN {
		use Exporter ();
		@ISA = "Exporter";
		@EXPORT =
		(
			
			'FORM_PARSE'
		);
}

#/**********************
# expect a hashref
sub FORM_PARSE {
    my $in = shift;
    
    my $usage;
    my @fields;
    
    #proceed if method is specified - [submition type:method] - json:post, post, get, json
    # [:]* fo future develop
    if ( scalar @{$$in{fields}} && $$in{method} ) {
            #/***********************************************
            # JSON
            if ( $$in{method} =~ 'json') {
                #parse json form data
                my $json = param('data');
                  #if parsed well
                  if ( scalar (@{$$json{fields}}) ) {
                    @fields = map { { $$_{name} => $_ } } @{$$in{fields}};
                  }
                  #cant' parsed
                  else {
                    return 0;
                  }
            }
            #/***********************************************
            # GET or POST
            else {
                #ok we got post of get
            }
    }
    else {
        return $usage;
    }


#/***********************************************/#
# converts a hashref to json code
sub jsonIt {
 my $in = shift;
 
 my $json_xs = JSON::XS->new();
  	$json_xs->pretty(1);
 my $json = $json_xs->encode($in);
	
 return $json;
}
#/***********************************************/#
# .. and vice versa
sub unJsonIt {
 my $in = shift;
   my $code;
   eval { $code = JSON::XS->new->utf8->decode($in); };
   #if $@ { return ""; }
   #else {
   # return $code;   
   #}
}

#if ( param($$field{name}) ) {
#                    $$field{value} = param($$field{name});
#                    push @fields, $field;
#                }
    
  
  #/*****************************************************************
  # Типовой вызов функции, выводится если небыло входящих параметров
=cut
    {
        method =>'json:get',  #// формат запроса на которые будет отвечать [json/xml/plain][:][/get/post/]
        url => 'good\/(\d+)', #// надо ли ожидать запросы от формы по маске адресов m//
                          
        fields => [
               {
                    field => 'name',
                    type => 'text',
                    validate => '.+',
                    error_message => 'Поле заполнено неправильно.', 
               },
               {
                    field=>'capture_str',
                    type => 'captcha',
                    validate => '[A-Za-z0-9]', #// type captcha запускает блок проверки капчи, но можно
                                               #// проверять и тоньше
                    error_message => 'Поле заполнено неправильно.', 
               },
        ],
        #/****************
        actions => {
            #// валидация прошла, действия.
            on_succes => {
                message => "Ваше сообщение успешно отправлено.",
                mail_send => {
                    to=>$params->{TMPL_VARS}->{const}->{email_for_feedback},
                    message=>qq{
			 <p>Здравствуйте! Получено сообщение с сайта $params->{project}->{domain}</p>
			 
			 <p>ФИО: [%name%]<br/>
			 Телефон: [%phone%]<br/>
			 Email: [%email%]<br/>			 
			 Текст сообщения: [%message%]<br/>
			 
                    },
                    subject=>'Сообщение с сайта '.$params->{project}->{domain},
                    from=>'robot@'.$params->{project}->{domain},
                },
                redirect => '/', #// После проверки формы сразу редиректить куда-то
                eval => '', #// выполнить блок
            },
            #// валидация не прошла
            on_error  => {
                message => '',
                eval => '', #// выполнить блок
            },
        },
        #/*************
        pre_encode =>'',  #// декодирование из кодировки х всего что принимается
        post_encode =>'', #// кодирование в кодировку х всего что отправляется
    };
=cut

}

END { }

1;
