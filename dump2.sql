-- MySQL dump 10.13  Distrib 5.5.31, for debian-linux-gnu (x86_64)
--
-- Host: 192.168.8.81    Database: svcms
-- ------------------------------------------------------
-- Server version	5.5.31-0+wheezy1-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES cp1251 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `template`
--

DROP TABLE IF EXISTS `template`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `template` (
  `template_id` int(11) NOT NULL AUTO_INCREMENT,
  `folder` varchar(255) NOT NULL DEFAULT '',
  `type` tinyint(1) unsigned NOT NULL DEFAULT '0',
  `header` varchar(200) NOT NULL DEFAULT '',
  `options` text NOT NULL,
  PRIMARY KEY (`template_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1663 DEFAULT CHARSET=cp1251;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `template`
--
-- WHERE:  template_id=1543

LOCK TABLES `template` WRITE;
/*!40000 ALTER TABLE `template` DISABLE KEYS */;
INSERT INTO `template` VALUES (1543,'basistranslogistik',0,'basistranslogistik.designb2b.ru','');
/*!40000 ALTER TABLE `template` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `template_const`
--

DROP TABLE IF EXISTS `template_const`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `template_const` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) DEFAULT NULL,
  `sort` tinyint(1) DEFAULT NULL,
  `type` varchar(20) NOT NULL DEFAULT '',
  `header` varchar(255) NOT NULL DEFAULT '',
  `description` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `template_id` (`template_id`),
  CONSTRAINT `template_const_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `template` (`template_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14663 DEFAULT CHARSET=cp1251;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `template_const`
--
-- WHERE:  template_id=1543

LOCK TABLES `template_const` WRITE;
/*!40000 ALTER TABLE `template_const` DISABLE KEYS */;
INSERT INTO `template_const` VALUES (13125,1543,1,'text','companyname','Название компании'),(13126,1543,2,'text','email_for_feedback','E-mail для связи'),(13127,1543,4,'text','phone','Телефон'),(13128,1543,6,'text','copy','Копирайт'),(13129,1543,7,'textarea','counter','Счетчики сайта'),(13131,1543,8,'text','slogan','Слоган'),(13132,1543,5,'text','phone_2','Телефон 2'),(13133,1543,9,'text','address','Адрес'),(13165,1543,10,'text','good_perpage','Товаров на странице'),(13166,1543,11,'text','perpage_galery','Партнеров на странице');
/*!40000 ALTER TABLE `template_const` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `url_run_code`
--

DROP TABLE IF EXISTS `url_run_code`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `url_run_code` (
  `url_run_code_id` int(11) NOT NULL AUTO_INCREMENT,
  `header` text NOT NULL,
  `template_id` int(11) DEFAULT NULL,
  `url_regexp` varchar(200) NOT NULL DEFAULT '',
  `run_code` text NOT NULL,
  `sort` tinyint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`url_run_code_id`),
  KEY `template_id` (`template_id`),
  CONSTRAINT `url_run_code_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `template` (`template_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=13821 DEFAULT CHARSET=cp1251;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `url_run_code`
--
-- WHERE:  template_id=1543

LOCK TABLES `url_run_code` WRITE;
/*!40000 ALTER TABLE `url_run_code` DISABLE KEYS */;
INSERT INTO `url_run_code` VALUES (12928,'*',1543,'','# Верхнее меню\r\n#&GET_DATA({table=>\'top_menu_tree\',order=>\'sort\',tree_use=>1,to_tmpl=>\'top_menu\',select_fields=>\"top_menu_tree_id, url, header, if(url=?,1,0) as act, \'\'\",}, $params->{PATH_INFO});\r\n$tv=$params->{TMPL_VARS};\r\n\r\n$tv->{top_menu}=$params->{dbh}->selectall_arrayref(\"select p.*,if(url=?,1,0) as act,(SELECT count(*) FROM top_menu_tree WHERE parent_id = p.top_menu_tree_id AND project_id = $params->{project}{project_id}) as childs from top_menu_tree p where p.project_id = $params->{project}{project_id} and p.parent_id is null order by sort\",{Slice=>{}},$params->{PATH_INFO});\r\nforeach(@{$tv->{top_menu}}){\r\n  if($_->{childs} > 0 ){\r\n    $_->{child}=&GET_DATA({table=>\'top_menu_tree\',where=>\'parent_id = ?\',order=>\'sort\',},$_->{top_menu_tree_id});\r\n    foreach(@{$_->{child}}){$_->{child}=[];}\r\n  }else{$_->{child}=[];}\r\n}\r\n\r\n&GET_DATA({struct=>\'service_rubricator\',where=>\'enabled=1 and path=\"\"\',order=>\'sort\',to_tmpl=>\'SERVICE\'});\r\n&mk_url($tv->{SERVICE},\'service\');\r\n\r\n&GET_DATA({struct=>\'rubricator\',where=>\'enabled=1 and specpredl=1\',order=>\'sort\',to_tmpl=>\'CATALOG\'});\r\n&mk_url($tv->{CATALOG},\'catalog\');\r\n\r\n&GET_DATA({struct=>\'galery\',to_tmpl=>\'PARTNER\',where=>\'enabled=1 and specpredl=1\'});\r\n\r\n&GET_DATA({struct=>\'good\',to_tmpl=>\'SPEC\',where=>\'enabled=1 and specpredl=1\'});\r\n&mk_url($tv->{SPEC},\'good\');\r\n\r\n\r\n#&GET_DATA({struct=>\'\',where=>\'\',to_tmpl=>\'\',order=>\'\'});\r\n#&mk_url($tv->{},\'\');\r\n#$tv->{RSIDE}=[];\r\n$tv->{LSIDE}=[\'SERVICE_BOX\',\'CATALOG_BOX\',\'PARTNER_BOX\'];\r\n\r\n#Для форм обратной связи\r\n@p=param;\r\nif(@af_arr = grep param($_) eq \'form_send\',@p){ $af = $af_arr[0];}\r\n#foreach(@p){$af = $_ if param($_) eq \'form_send\';}\r\nif($af){\r\n  my $err=$af.\'_err\';\r\n  my $vls=$af.\'_vls\';\r\n  my $err_msg=$af.\'_err_msg\';\r\n  my $ok_msg=$af.\'_ok_msg\';\r\n  my $subj = {\r\n    pop1 => \'Заявка\',\r\n    pop2 => \'Обратный звонок\',\r\n    form1 => \'\',\r\n    form2 => \'\',\r\n  };\r\n  my $fields={\r\n    pop1=>[\r\n      {name=>\'name\',description=>\'ФИО\',regexp=>\'.+\',},\r\n      {name=>\'phone\',description=>\'Телефон\'},#regexp=>\'.+\',},\r\n      {name=>\'email\',description=>\'E-mail\',regexp=>\'^[^@]+@+[^\\.]+\\.+[^\\.]{2,6}$\'},\r\n      #{name=>\'email\',description=>\'E-mail\',regexp=>\'\\w+@[a-zA-Z_]+\\.[a-zA-Z]{2,6}\',}, # old format for check email\r\n      {name=>\'message\',description=>\'Сообщение\'},#regexp=>\'.+\',},\r\n    ],\r\n    pop2=>[\r\n      {name=>\'name\',description=>\'ФИО\',regexp=>\'.+\',},\r\n      {name=>\'phone\',description=>\'Телефон\',regexp=>\'.+\',},\r\n      {name=>\'time\',description=>\'Время\'},#regexp=>\'.+\',},\r\n      #{name=>\'email\',description=>\'E-mail\',regexp=>\'^[^@]+@+[^\\.]+\\.+[^\\.]{2,6}$\'},\r\n      #{name=>\'email\',description=>\'E-mail\',regexp=>\'\\w+@[a-zA-Z_]+\\.[a-zA-Z]{2,6}\',}, # old format for check email\r\n      {name=>\'message\',description=>\'Сообщение\'},#regexp=>\'.+\',},\r\n    ],\r\n  };\r\n#  $fields->{pop2}=$fields->{form1}=$fields->{form2}=$fields->{pop1};\r\n  my $mail=[\r\n    {to=>$tv->{const}{email_for_feedback},subject=>$subj->{$af}.\' с сайта http://\'.$params->{project}{domain},message=>&fb_msg2($fields->{$af}),}\r\n  ];\r\n  \r\n  ($tv->{\"$err\"},$tv->{\"$vls\"})=&GET_FORM({\r\n    action_field=>$af,use_capture=>1,fields=>$fields->{$af},mail_send=>$mail,\r\n  });\r\n  $tv->{\"$err_msg\"}=\'<div style=\"background:#faa;border:1px solid #f00;padding:10px;margin:10px;\">\'.join(\'<br>\',@{$tv->{\"$err\"}}).\'</div>\';\r\n  $tv->{\"$ok_msg\"}=\'<div style=\"background:#9d9;border:1px solid green;padding:10px;margin:10px;\">Спасибо, ваше сообщение отправлено.</div>\';\r\n}',1),(12929,'Главная',1543,'^\\/$','$tv=$params->{TMPL_VARS};\r\n$tv->{promo}{title}=\'Главная\' unless($tv->{promo}{title});\r\n$tv->{page_type}=\'main\';\r\n\r\n&GET_DATA({table=>\'content\',where=>qq{url=\'/\'},onerow=>1,to_tmpl=>\'content\'});\r\n\r\n&GET_DATA({table=>\'content\',where=>\'url LIKE ?\',to_tmpl=>\'BLOCKS\'},\'__block_%\');\r\nmap {$n=$_->{url};$n=~s/^__//;$tv->{$n}=$_;} @{$tv->{BLOCKS}};\r\n\r\n&GET_DATA({struct=>\'images\',to_tmpl=>\'IMAGES\',where=>\'enabled=1\'});\r\n&GET_DATA({struct=>\'rubricator\',to_tmpl=>\'TOP_CATALOG\',where=>\'enabled=1 and specpredl=1\',order=>\'sort\'});\r\n&mk_url($tv->{TOP_CATALOG},\'catalog\');\r\n#\r\n\r\n$tv->{LSIDE}=[];',2),(12930,'Статика',1543,'^(.*)$','my $url=$1;\r\nif(!$params->{TMPL_VARS}->{page_type}){ # Проверяем, есть ли текстовая страница по данному url\'у\r\n	if(\r\n		$params->{TMPL_VARS}->{content}=&GET_DATA({\r\n			table=>\'content\',\r\n			url=>$url,\r\n			onerow=>1\r\n		})\r\n	){\r\n		$params->{TMPL_VARS}->{title} = $params->{TMPL_VARS}->{content}->{header};\r\n		$params->{TMPL_VARS}->{page_type}=\'text_page\';\r\n		$params->{TMPL_VARS}->{promo}->{title}=$params->{TMPL_VARS}->{content}->{header}\r\n			unless($params->{TMPL_VARS}->{promo}->{title});\r\n	}\r\n}',8),(12943,'Услуги(рубрикатор)',1543,'^\\/service(?(?=\\/(\\d+))\\/(\\d+))$','my $rubricator_id=$1;\r\n$tbl=\'service_rubricator\'; #таблица\r\n$tv=$params->{TMPL_VARS};\r\n&GET_DATA({table=>\'content\',where=>\'url=?\',onerow=>1,to_tmpl=>\'info\'},\'/service\');\r\n\r\nif($rubricator_id=~m/^\\d+$/){ # выбран раздел рубрикатора\r\n  if($tv->{content}=&GET_DATA({struct=>$tbl,where=>\'enabled=1\',onerow=>1,id=>$rubricator_id})){\r\n    $tv->{page_type}=\'service/services\';\r\n    &GET_DATA({struct=>$tbl,where=>\'parent_id=? AND enabled=1\',to_tmpl=>\'LIST\',order=>\'sort\',},$rubricator_id);\r\n    unless(scalar(@{$tv->{LIST}})){$tv->{page_type}=\'service/services_in\';}\r\n    # хлебные крошки\r\n    &GET_PATH({struct=>$tbl,id=>$rubricator_id,to_tmpl=>\'PATH_INFO\',create_href=>\'/service/[%id%]\'});    \r\n  }\r\n}\r\nelse{\r\n  $tv->{LSIDE}=[\'CATALOG_BOX\',\'PARTNER_BOX\'];\r\n  $tv->{page_type}=\'service/services\';\r\n  $tv->{content}=$tv->{info};\r\n  &GET_DATA({struct=>$tbl,where=>\'enabled=1 and path=\"\"\',to_tmpl=>\'LIST\',order=>\'sort\',});\r\n}\r\n\r\n&mk_url($tv->{LIST},\'service\');\r\n$tv->{promo}->{title}=$tv->{content}{header} unless($tv->{promo}->{title});\r\nunshift @{$tv->{PATH_INFO}},{header=>$tv->{info}{header},href=>\'/service\'};',3),(12944,'Каталог',1543,'^\\/catalog(?(?=\\/(\\d+))\\/(\\d+))$','my $rid = $1;\r\nmy $tv = $params->{TMPL_VARS};\r\nmy $tbl = \'rubricator\';\r\nmy $url = \'catalog\';\r\n&GET_DATA({table=>\'content\',to_tmpl=>\'info\',where=>\'url=?\',onerow=>1},\'/catalog\');\r\n\r\nif($rid =~ m/^\\d+$/){ # выбран раздел рубрикатора\r\n  if($tv->{content}=&GET_DATA({where=>\'enabled=1\',struct=>$tbl,onerow=>1,id=>$rid})){\r\n    $tv->{page_type}=\'catalog/catalog\';\r\n    &GET_DATA({struct=>$tbl,where=>\'parent_id=? AND enabled=1\',order=>\'sort\',to_tmpl=>\'LIST\',},$rid);\r\n    unless(scalar(@{$tv->{LIST}})){\r\n      $tv->{maxpage}=&GET_DATA({where=>\'rubricator_id=? AND enabled=1\',order=>\'id desc\',struct=>\'good\',to_tmpl=>\'LIST\',perpage=>$tv->{const}->{good_perpage}},$rid);\r\n      $tv->{page_type}=\'catalog/spisok\';\r\n      $url=\'good\';\r\n    }   \r\n    &GET_PATH({struct=>$tbl,id=>$rid,to_tmpl=>\'PATH_INFO\',create_href=>\'/catalog/[%id%]\'});\r\n    $tv->{page} = undef unless(param(\'page\') <= $tv->{maxpage});\r\n  }\r\n}\r\nelse{\r\n  $tv->{LSIDE}=[\'SERVICE_BOX\',\'PARTNER_BOX\'];\r\n  $tv->{page_type}=\'catalog/catalog\';\r\n  #&GET_DATA({struct=>\'rubricator\',to_tmpl=>\'LIST\',tree_use=>1,order=>\'sort\',where=>\'enabled=1\',});\r\n  &GET_DATA({struct=>$tbl,to_tmpl=>\'LIST\',where=>\'enabled=1 AND path=\"\"\',order=>\'sort\',});\r\n  $tv->{content}=$tv->{info};\r\n}\r\n\r\n&mk_url($tv->{LIST},$url);\r\n$tv->{promo}{title}=$tv->{content}{header} unless($tv->{promo}{title});\r\nunshift @{$tv->{PATH_INFO}},{header=>$tv->{info}{header},href=>\'/catalog\'};',4),(12945,'Товар',1543,'^\\/good(?(?=\\/(\\d+))\\/(\\d+))$','my $gid=$1;\r\n$tv=$params->{TMPL_VARS};\r\n\r\nif($gid =~ m/^\\d+$/){\r\n  if($tv->{content} = &GET_DATA({struct=>\'good\',id=>$gid,onerow=>1,})){    \r\n    &GET_PATH({struct=>\'rubricator\',id=>$tv->{content}{rubricator_id},to_tmpl=>\'PATH_INFO\',create_href=>\'/catalog/[%id%]\'});\r\n    &GET_DATA({table=>\'content\',where=>\'url=?\',onerow=>1,to_tmpl=>\'info\'},\'/catalog\');\r\n    push @{$tv->{PATH_INFO}},{href=>\'\',header=>$tv->{content}{header}};\r\n    unshift @{$tv->{PATH_INFO}},{href=>\'/catalog\',header=>$tv->{info}{header}};\r\n    $tv->{page_type}=\'catalog/catalog_detali\';\r\n    $tv->{promo}{title}=$tv->{content}{header} unless($tv->{promo}{title});\r\n    \r\n=cut\r\n# Фотогалерея\r\n    if($tv->{photos}=&GET_DATA({table=>\'struct_\'.$params->{project}{project_id}.\'_good_galery\',where=>\'good_id=?\',order=>\'sort\',},$gid)){\r\n      $p=\'/files/project_\'.$params->{project}{project_id}.\'/good/\';\r\n      map{\r\n        my ($f,$e) = split(\'\\.\',$_->{photo});\r\n        $_->{photo_and_path_mini1}=$p.$f.\'_mini1.\'.$e;\r\n        $_->{photo_and_path_mini2}=$p.$f.\'_mini2.\'.$e;\r\n      }@{$tv->{photos}};\r\n    }\r\n=cut    \r\n    \r\n  }\r\n}',5),(12946,'Список',1543,'^\\/partner(?(?=\\/(\\d+))\\/(\\d+))$','my $id=$1;\r\nmy $tbl=\'galery\';\r\nmy $url = \'partner\';\r\nmy $fld = \'partner\';\r\nmy $tv=$params->{TMPL_VARS};\r\nmy $perpage=$tv->{const}{\"perpage_$tbl\"};\r\nmy $order=\'id desc\';\r\n\r\n&GET_DATA({table=>\'content\',where=>\'url=?\',to_tmpl=>\'info\',onerow=>1},\'/\'.$url);\r\n\r\nif($id=~ m/^\\d+$/){\r\n  if($tv->{content}=&GET_DATA({struct=>$tbl,where=>\'enabled=1\',id=>$id,onerow=>1,})){\r\n    $tv->{page_type}=$fld.\'/list-in\';\r\n    push @{$tv->{PATH_INFO}},{header=>$tv->{content}{header},href=>\'\'};\r\n  }\r\n}\r\nelse{\r\n  $tv->{LSIDE}=[\'SERVICE_BOX\',\'CATALOG_BOX\'];\r\n  $tv->{content}=$tv->{info};\r\n  $tv->{page_type}=$fld.\'/list\';\r\n  $tv->{maxpage}=&GET_DATA({struct=>$tbl,to_tmpl=>\'LIST\',where=>\'enabled=1\',perpage=>$perpage,order=>$order,});\r\n  &mk_url($tv->{LIST},$url);\r\n}\r\n\r\n$tv->{promo}{title}=$tv->{content}{header} unless($tv->{promo}{title});\r\nunshift @{$tv->{PATH_INFO}},{header=>$tv->{info}{header},href=>\'/\'.$url};',6),(12958,'Список',1543,'^\\/spec$','my $id=$1;\r\nmy $tbl=\'good\';\r\nmy $url = $tbl;\r\nmy $fld = \'catalog/\';\r\nmy $tv=$params->{TMPL_VARS};\r\nmy $perpage=$tv->{const}{good_perpage};\r\nmy $order=\'id desc\';\r\n\r\n&GET_DATA({table=>\'content\',where=>\'url=?\',to_tmpl=>\'info\',onerow=>1},\'/\'.$url);\r\n\r\n#if($id=~ m/^\\d+$/){\r\n#  if($tv->{content}=&GET_DATA({struct=>$tbl,where=>\'enabled=1\',id=>$id,onerow=>1,})){\r\n#    $tv->{page_type}=$fld.\'list-in\';\r\n#    push @{$tv->{PATH_INFO}},{header=>$tv->{content}{header},href=>\'\'};\r\n#  }\r\n#}\r\n#else{\r\n  $tv->{content}=$tv->{info};\r\n  $tv->{page_type}=$fld.\'spisok\';\r\n  $tv->{maxpage}=&GET_DATA({struct=>$tbl,to_tmpl=>\'LIST\',where=>\'enabled=1 and specpredl=1\',perpage=>$perpage,order=>$order,});\r\n  &mk_url($tv->{LIST},$url);\r\n#}\r\n\r\n$tv->{promo}{title}=$tv->{content}{header} unless($tv->{promo}{title});\r\nunshift @{$tv->{PATH_INFO}},{header=>$tv->{info}{header},href=>\'/\'.$url};',7);
/*!40000 ALTER TABLE `url_run_code` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `url_rules`
--

DROP TABLE IF EXISTS `url_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `url_rules` (
  `url_rules_id` int(11) NOT NULL AUTO_INCREMENT,
  `template_id` int(11) DEFAULT NULL,
  `url_regexp` varchar(200) NOT NULL DEFAULT '',
  `template_name` varchar(200) NOT NULL DEFAULT '',
  `header` text NOT NULL,
  `sort` tinyint(2) NOT NULL DEFAULT '0',
  PRIMARY KEY (`url_rules_id`),
  KEY `template_id` (`template_id`),
  CONSTRAINT `url_rules_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `template` (`template_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=899 DEFAULT CHARSET=cp1251;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `url_rules`
--
-- WHERE:  template_id=1543

LOCK TABLES `url_rules` WRITE;
/*!40000 ALTER TABLE `url_rules` DISABLE KEYS */;
/*!40000 ALTER TABLE `url_rules` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `capture_setting`
--

DROP TABLE IF EXISTS `capture_setting`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `capture_setting` (
  `template_id` int(11) NOT NULL DEFAULT '0',
  `width` varchar(3) DEFAULT NULL,
  `height` varchar(3) DEFAULT NULL,
  `deg1_from` varchar(2) DEFAULT NULL,
  `deg1_to` varchar(2) DEFAULT NULL,
  `deg2_from` varchar(2) DEFAULT NULL,
  `deg2_to` varchar(2) DEFAULT NULL,
  `background` varchar(7) DEFAULT NULL,
  `color` varchar(7) DEFAULT NULL,
  `fontsize` varchar(2) DEFAULT NULL,
  `chars_count` tinyint(1) DEFAULT '6',
  `method` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`template_id`),
  CONSTRAINT `capture_setting_ibfk_1` FOREIGN KEY (`template_id`) REFERENCES `template` (`template_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=cp1251;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `capture_setting`
--
-- WHERE:  template_id=1543

LOCK TABLES `capture_setting` WRITE;
/*!40000 ALTER TABLE `capture_setting` DISABLE KEYS */;
INSERT INTO `capture_setting` VALUES (1543,'80','60','0','0','0','0','','','',1,1);
/*!40000 ALTER TABLE `capture_setting` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'svcms'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-05-31 10:41:52
