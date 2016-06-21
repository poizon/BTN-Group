# где сидит tinymce
$tiny_mce_www = '../../tinymce/';
do '../connect';
my $dbh=DBI->connect("DBI:mysql:$DBname:$DBhost",$DBuser,$DBpassword, , { RaiseError => 1 }) || die($!);
my $sth=$dbh->prepare("SELECT project_id from manager where login=?");
$sth->execute($ENV{REMOTE_USER});
my $project_id=$sth->fetchrow();

# где на внешке растут картинки
$upload_path = '/files/project_'.$project_id;#.'/wysiwyg';

# куда заливать файлы
$upload_root_path = '../../files/project_'.$project_id;#.'/wysiwyg';

# типы файлов для загрузки
@types_file = qw(7z rar zip doc docx pdf xls xlsx odt ods cer crl); 

# типы изображений
@types_img = qw(gif jpg jpeg gif png bmp swf svg);

# максимальный размер файла
$file_size_max = 26*1024*1024;

#сортировка 1-по времени создания, 2-по названию, 0 - без сортировки
#сортировка файлов
$type_sort_file = 1;

#порядок сортировки файлов
$order_sort_file = 'desc';

#сортировка каталогов
$type_sort_dir = 2;

#порядок сортировки каталогов
$order_sort_dir = 'asc';
