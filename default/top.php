<?php
/* ---------------------------------------------------- */
/* 程序名称: PHP探针-Yahei
/* 程序功能: 在网页上显示Linux系统的top命令结果
/* 程序开发: Yahei.Net
/* 联系方式: info@Yahei.net
/* Date: 2011-11-7 / 2011-11-7
/* ---------------------------------------------------- */
/* 使用条款:
/* 1.你可以自由免费的使用本程序.
/* 2.你可以修改本程序,仅限自己使用.
/* 3.如果你修改本程序再发布,必须要有新的功能或内容.
/* 4.作者不对该程序运行显示的数据负任何责任.
/* ---------------------------------------------------- */
error_reporting(0); //抑制所有错误信息
@header("content-Type: text/html; charset=utf-8"); //语言强制

$title = '雅黑PHP探针[TOP版]';
$version = 'v1.0';

$top = `top -n 1 -b`;
//$top = `ps -aux`;
$top = str_replace("<","&lt;",$top);
//$top = nl2br($top);

//ajax调用实时刷新
if($_GET['act']=='rt')
{
	$arr=array('top'=>"$top");
	$jarr=json_encode($arr); 
	echo $_GET['callback'],'(',$jarr,')';
	exit;
}
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><?php echo $title.$version; ?></title>
<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7" />
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<!-- Powered by: Yahei.Net -->
<style type="text/css">
<!--
* {font-family: Tahoma, "Microsoft Yahei", Arial; }
body{text-align: center; margin: 0 auto; padding: 0; background:#000000; color:#FFFFFF;font-size:12px;font-family:Tahoma, Arial}
a{color: #FFFFFF; text-decoration:none;}
#page {width: 100%; padding: 0 20px; margin: 0 auto; text-align: left;}
#top {width: 700px;word-break:break-all;}
#foot {width: 100%; text-align: left; }
-->
</style>
<script language="JavaScript" type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/jquery/1.3.1/jquery.min.js"></script>
<script type="text/javascript"> 
<!--
$(document).ready(function(){getJSONData();});
function getJSONData()
{
	setTimeout("getJSONData()", 2000);
	$.getJSON('?act=rt&callback=?', displayData);
}
function displayData(dataJSON)
{
	$("#top").html(dataJSON.top);
}
-->
</script>
</head>
<body>

<div id="page">

<pre id='top' style='font-family:vt7X13,"Courier New";font-size:11px;line-height:14px;word-break:break-all;'>
<?php echo $psout;?>
</pre>

<div id="foot">
<a href="http://www.yahei.net/" target="_blank"><?php echo $title.$version; ?></a>
<br /><br />提示：如果页面不显示TOP命令的结果,是因为服务器权限设置障碍。
</div>

</div>
</body>
</html>