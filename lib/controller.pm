package controller;

sub new {
    my $class = shift;
    my $self = {
        url            = shift,
        header         = shift,
        code           = shift,
        title          = shift,
        description    = shift,
    };
    blass $self, $class;
    return $self;
    
    sub title {
        my ($self, $title) = shift;
                $self->{title} = $title;
                return $self;
    }
    sub description {
        my ($self, $desc) = shift;
                $self->{description} = $desc;
                return $self;
    }
    sub url {
        my ($self, $url) = shift;
                $self->{url} = $url;
                return $self;
    }
    1;
}

