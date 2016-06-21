#!/usr/bin/perl

# Да, это одно из немногих мест, где скрипт написан по-человечески, со strict'ом. (c) Leva
use strict;

use Graphics::Magick;
use Data::Dumper;

my $copyright_image;
my $image;

do $ENV{DOCUMENT_ROOT}.'/manager/connect';
use vars q{$CMSpath};

start();
exit;

sub start {
    my $data = LoadData();
    CheckData($data);
print "Content-Type: text/html\n\n";
#print Dumper($data);
    my $scalar_sizes = scalar @{$data->{'sizes'}};
    for (my $i = 0; $i < $scalar_sizes; $i++) {
        my $i_name = $i + 1;

        $image = Graphics::Magick->new();
        $image->Read($data->{'input_file'});
        ($data->{'picture_width'}, $data->{'picture_height'}) = $image->Get('base-columns','base-rows');

        if ($data->{'copyright'}) {
            $copyright_image = Graphics::Magick->new();
            #$data->{'copyright_file'} = "/var/share/www/sv-cms/htdocs/files/project_$data->{'project_id'}/copyright/copyright.png";
	    $data->{copyright_file} = "$CMSpath/files/project_$data->{project_id}/copyright/copyright.png";
            $copyright_image->Read($data->{'copyright_file'});
            ($data->{'copyright_width'}, $data->{'copyright_height'}) = $copyright_image->Get('base-columns','base-rows');
        }

        $data->{'border_width'}  = $data->{'sizes'}[$i]{'border_w'};
        $data->{'border_height'} = $data->{'sizes'}[$i]{'border_h'};
        $data->{'output_file'}   = "$data->{'filesource_name'}_mini$i_name.$data->{'filesource_ext'}";

        if (($data->{'picture_width'} <= $data->{'border_width'}) && 
        ($data->{'picture_height'} <= $data->{'border_height'})) {
            $data->{'width'}  = $data->{'picture_width'};
            $data->{'height'} = $data->{'picture_height'};
        }
#	print "Content-Type: text/html\n\n";
#	print Dumper($data);
        unless ($data->{'width'} && $data->{'height'}) {
            if (defined $data->{'crop'}) {
                if (($data->{'border_width'} != '0') && ($data->{'border_width'} != '0')) {
                    CropImage($data);
			print Dumper($data);
                } else {
                    ResizeImage($data);
                }
            } else {
                ResizeImage($data);
            }
        }
        if ($data->{'copyright_file'}) {
            AddCopyright($data);
        }
        WriteImage($data);
        undef $data->{'width'};
        undef $data->{'height'};
    }
}

sub LoadData {
    my $data = {};
# 1. Смотрим название исходного файла-картинки, получаем его имя и расширение
    $data->{'input_file'} = $ARGV['0'];
    if ($data->{'input_file'} =~ m/^(.+)\.(.*?)$/) {
        $data->{'filesource_name'} = $1;
        $data->{'filesource_ext'}  = $2;
    }

# 2. Анализируем все параметры, поступающие из конфигурационного файла
    foreach my $param (@ARGV) {

        # матчим все поступающие входные данные
        if ($param =~ m/^--(.+?)=(.+?)$/) {

            my ($option, $value) = ($1, $2);
            $value =~ s/^'|'$//g;
            $value =~ s/^"|"$//g;

            # получаем id проекта
            if ($option eq 'project_id') {
                $data->{'project_id'} = $value;
            }

            # получаем параметр кропа изображения
            if ($option eq 'crop') {
                $data->{'crop'} = $value;
            }

            # получаем параметр копирайта изображения
            if ($option eq 'copyright') {
                $data->{'copyright'} = $value;
            }

            # получаем массив значений ширины и высоты изменяемого изображения
            if ($option eq 'size') {
                if ($value =~ m/^(.+?)x(.+?)$/) {
                    push @{$data->{'sizes'}}, {'border_w' => $1, 'border_h' => $2};
                }
            }
        }
    }
    return $data;
}

sub CheckData {
    my $data = shift;

    my $error_counter = '0';
    my @errors = ();

    if (defined $data->{'project_id'}) {
        push @errors, "- Некорректно указан параметр project_id (ID проекта)<br>" if $data->{'project_id'} !~ m/^\d+$/;
        $error_counter++;
    }

    if (defined $data->{'filesource_ext'}) {
        push @errors, "- Допустимыми форматами закачиваемых файлов могут быть только: jpg, jpeg, png или bmp" if $data->{'filesource_ext'} !~ m/(jpg|jpeg|png|bmp)/;
    }

    if (defined $data->{'copyright'}) {
        push @errors, "- Не указан параметр project_id (ID проекта) для опции копирайта<br>" unless $data->{'project_id'};
        $error_counter++;
    }

    if ((defined $data->{'copyright'}) && (defined $data->{'project_id'})) {
        #push @errors, "- Файл с водяным знаком не сохранен на сервере<br>" unless -f "/var/share/www/sv-cms/htdocs/files/project_$data->{'project_id'}/copyright/copyright.png";
	push @errors, "- Файл с водяным знаком не сохранен на сервере<br>" unless -f "$CMSpath/files/project_$data->{project_id}/copyright/copyright.png";
        $error_counter++;
    }

    if (defined $data->{'crop'}) {
        push @errors, "- Некорректно указан параметр для кропа изображения (может быть только center - для центровых линий и golden_ratio - для правила \"золотого сечения\"<br>" if $data->{'crop'} !~ m/^(golden_ratio|center)$/;
        $error_counter++;
    }

    if($data->{'input_file'} !~ m/^[0-9a-zA-Z\._\-\/]+$/) {
        push @errors, "- Не указано или указано неверно имя входного файла ($data->{'input_file'})<br>";
        $error_counter++;
    }
    if (scalar @{$data->{'sizes'}}) {
        foreach my $rec (@{$data->{'sizes'}}) {
            if ($rec->{'border_w'} !~ m/^\d+$/ || $rec->{'border_h'} !~ m/^\d+$/) {
                push @errors, "- Некорректно указан габарит ширины или высоты ресайза в выражении \"$rec->{'border_w'}x$rec->{'border_h'}\"<br>";
                $error_counter++;
            }
            if (defined $data->{'crop'}) {
                if (($rec->{'border_w'} == '0') || ($rec->{'border_h'} == '0')) {
                    push @errors, "- При кропе изображения должны быть заданы оба габарита для ресайза (в данном случае габарит \"$rec->{'border_w'}x$rec->{'border_h'}\")<br>";
                    $error_counter++;
                }
            }
        }
    } else {
        push @errors, "- Должен быть указан хотя бы один размер для кропа или ресайза изображения<br>";
        $error_counter++;
    }

    if (scalar @errors) {
        my $error_text = join('', @errors);
        print $error_text;
        exit;
    }
}

sub ResizeImage {
    my $data = shift;

    if (($data->{'picture_width'} <= $data->{'border_width'}) && 
       ($data->{'picture_height'} <= $data->{'border_height'})) {

        $image->Resize(
            'width'  => $data->{'picture_width'},
            'height' => $data->{'picture_height'},
        );

    } elsif ($data->{'border_width'} != '0' && $data->{'border_height'} != '0') {

        $data->{'ratio_width'}  = $data->{'border_width'} / $data->{'picture_width'};
        $data->{'ratio_height'} = $data->{'border_height'} / $data->{'picture_height'};
        $data->{'ratio_diff'} = $data->{'ratio_width'} / $data->{'ratio_height'};

        if ($data->{'ratio_diff'} >= '1') {
            $data->{'ratio'} = $data->{'border_height'} / $data->{'picture_height'};
        } elsif ($data->{'ratio_diff'} < '1') {
            $data->{'ratio'} = $data->{'border_width'} / $data->{'picture_width'};
        } elsif (($data->{'border_height'} >= $data->{'picture_height'}) &&
                ($data->{'border_width'} >= $data->{'picture_width'})) {
            $data->{'ratio'} = undef;
        }
        if (defined $data->{'ratio'}) {
            $data->{'height'} = int($data->{'picture_height'} * $data->{'ratio'});
            $data->{'width'}  = int($data->{'picture_width'} * $data->{'ratio'});

            $image->Resize(
                'width'  => $data->{'width'},
                'height' => $data->{'height'}
            );

        } else {

            $image->Resize(
                'width'  => $data->{'picture_width'},
                'height' =>$data->{'picture_height'},
            );

        }

    } elsif ($data->{'border_height'} == '0') {

        if ($data->{'picture_width'} < $data->{'border_width'}) {

            $image->Resize(
                'width'  => $data->{'picture_width'},
                'height' => $data->{'picture_height'},
            );

        } else {

            $data->{'ratio'}  = $data->{'border_width'} / $data->{'picture_width'};
            $data->{'height'} = int($data->{'picture_height'} * $data->{'ratio'});
            $data->{'width'}  = int($data->{'picture_width'} * $data->{'ratio'});
            $image->Resize(
                'width'  => $data->{'width'},
                'height' => $data->{'height'},
            );
        }

    } elsif ($data->{'border_width'} == '0') {

        if ($data->{'picture_height'} < $data->{'border_height'}) {

            $image->Resize(
                'width'  => $data->{'picture_width'},
                'height' => $data->{'picture_height'},
            );
        } else {

            $data->{'ratio'}  = $data->{'border_height'} / $data->{'picture_height'};
            $data->{'height'} = int($data->{'picture_height'} * $data->{'ratio'});
            $data->{'width'}  = int($data->{'picture_width'} * $data->{'ratio'});

            $image->Resize(
                'width'  => $data->{'width'},
                'height' => $data->{'height'},
            );
        }
    }
    return $data;
}

sub CropImage {
    my $data = shift;

    if ($data->{'picture_width'} <= $data->{'picture_height'}) {
        $data->{'factor'} = $data->{'picture_width'} / $data->{'border_width'};
    } else {
        $data->{'factor'} = $data->{'picture_height'} / $data->{'border_height'};
    }

    if (defined $data->{'factor'}) {
        $data->{'height'} = sprintf("%.0f", $data->{'picture_height'} / $data->{'factor'});
        $data->{'width'}  = sprintf("%.0f", $data->{'picture_width'} / $data->{'factor'});
    } else {
        $data->{'width'}  = $data->{'picture_width'};
        $data->{'height'} = $data->{'picture_height'};
    }

    $image->Resize(
        'width'  => $data->{'width'},
        'height' => $data->{'height'},
    );

    if ($data->{'crop'} eq 'center') {
        my $difference_width  = sprintf("%.0f",($data->{'border_width'}  - $data->{'width'}));
        my $difference_height = sprintf("%.0f",($data->{'border_height'} - $data->{'height'}));
        if ($difference_width <= '0') {
            $data->{'x_crop_left'}  = abs(sprintf("%.0f", $difference_width / 2));
            $data->{'x_crop_right'} = sprintf("%.0f", $difference_width / 2);
        }
        if ($difference_height <= '0') {
            $data->{'y_crop_up'}   = abs(sprintf("%.0f", $difference_height / 2));
            $data->{'y_crop_down'} = sprintf("%.0f", $difference_height / 2);
        }
    } elsif ($data->{'crop'} eq 'golden_ratio') {
        my $difference_width  = sprintf("%.0f",($data->{'border_width'}  - $data->{'width'}));
        my $difference_height = sprintf("%.0f",($data->{'border_height'} - $data->{'height'}));
        if ($difference_width <= '0') {
            $data->{'x_crop_left'}  = abs(sprintf("%.0f", $difference_width / 1/3));
            $data->{'x_crop_right'} = "-".sprintf("%.0f", $data->{'x_crop_left'} * 2);
        }
        if ($difference_height <= '0') {
            $data->{'y_crop_up'}   = abs(sprintf("%.0f", $difference_height / 1/3));
            $data->{'y_crop_down'} = "-".sprintf("%.0f", $data->{'y_crop_up'} * 2);
        }
    }

    if ($data->{'x_crop_left'} || $data->{'y_crop_down'}) {

        $image->Crop(
            'width'  => $data->{'width'},
            'height' => $data->{'height'},
            'x'      => $data->{'x_crop_right'},
            'y'      => $data->{'y_crop_down'},
        );

        $image->Crop(
            'width'  => $data->{'width'},
            'height' => $data->{'height'},
            'x'      => $data->{'x_crop_left'},
            'y'      => $data->{'y_crop_up'},
        );
    }
    $data->{'width'} = $data->{'width'} - abs($data->{'x_crop_left'}) - abs($data->{'x_crop_right'});
    $data->{'height'} = $data->{'height'} - abs($data->{'y_crop_up'}) - abs($data->{'y_crop_down'});
    
    return $data;
}

sub AddCopyright {
    my $data = shift;

    if (($data->{'copyright_width'} <= $data->{'width'}) && 
       ($data->{'copyright_height'} <= $data->{'height'})) {

        $image->Composite(
            'image'   => $copyright_image,
            'compose' => 'Plus',
            'gravity' => 'Center',
        );

    } else {

        $data->{'copyright_ratio_width'}  = $data->{'width'} / $data->{'copyright_width'};
        $data->{'copyright_ratio_height'} = $data->{'height'} / $data->{'copyright_height'};
        $data->{'copyright_ratio_diff'} = $data->{'copyright_ratio_width'} / $data->{'copyright_ratio_height'};

        if ($data->{'copyright_ratio_diff'} >= '1') {
            $data->{'copyright_ratio'} = $data->{'height'} / $data->{'copyright_height'};

        } elsif ($data->{'copyright_ratio_diff'} < '1') {
            $data->{'copyright_ratio'} = $data->{'width'} / $data->{'copyright_width'};

        } elsif (($data->{'height'} >= $data->{'copyright_height'}) &&
                ($data->{'width'} >= $data->{'copyright_width'})) {
            $data->{'copyright_ratio'} = undef;
        }

        if (defined $data->{'copyright_ratio'}) {
            $data->{'copyright_height'} = int($data->{'copyright_height'} * $data->{'copyright_ratio'});
            $data->{'copyright_width'}  = int($data->{'copyright_width'} * $data->{'copyright_ratio'});
            $copyright_image->Resize(
                'width'  => $data->{'copyright_width'},
                'height' => $data->{'copyright_height'}
            );
            $image->Composite(
                'image'   => $copyright_image,
                'compose' => 'Plus',
                'gravity' => 'Center',
            );

        } else {
            $copyright_image->Resize(
                'width'  => $data->{'copyright_width'},
                'height' =>$data->{'copyright_height'},
            );
            $image->Composite(
                'image'   => $copyright_image,
                'compose' => 'Plus',
                'gravity' => 'Center',
            );
        }
    }
    return $data;
}

sub WriteImage {
    my $data = shift;
    my $write = $image->write($data->{'output_file'});
    my $print_text;
    $print_text = "Сохраняем файл $data->{'output_file'} (исходник с размерами $data->{'picture_width'}x$data->{'picture_height'}, измененный файл с размерами $data->{'width'}x$data->{'height'})";
    if (defined $data->{'crop'}) {
        if ($data->{'crop'} eq 'golden_ratio') {
            $print_text .= " и делаем \"Золотое сечение\"";
        } elsif ($data->{'crop'} eq 'center') {
            $print_text .= " и делаем сечение по центровым линиям";
        }
    }
    if (defined $data->{'copyright'}) {
        $print_text .= ", а также добавляем копирайт";
    }
    print "$print_text<br>";
}
