#!D:\Perl64\bin\perl.exe
use LWP::Simple;
use LWP::UserAgent;
use LWP::RobotUA;
use HTTP::Cookies;
use HTML::Element;
use HTML::TreeBuilder;
use HTML::LinkExtor;
use DBI;
use Try::Tiny;
use FindBin; #抓出程式執行路徑

my $file = $FindBin::Bin; 			#程式執行路徑

$ua = LWP::UserAgent->new;
$ua->agent("MyApp/0.1 ");


my $page=1; 		#index1~index1173
my @article_link;	#save links
my %article_author;
my %article_state;
my %article_content;

########################GET ARTICLE INDEX###############################
while($page<1176)
{
	print "page:".$page."\n";
	&catch_index_href($page);
	$page++;	
}


########################GET ARTICLE CONTENT###############################
foreach my $key (keys %article_author)
{
	&get_atrticle_content($key);
}


foreach my $key (keys %article_author)
{	
	my @temp=split("	",$article_state{$key});

	$temp[3]=~s/://g;
	my $temp_name=$article_author{$key};
	if($temp_name=~s/\[//g)  #filter
	{
		# print $temp_name."\n";
		next;
	}
	else
	{
		print $temp_name."\n";
		my @time=split(" ",$temp[3]);
		my $time_tmp=$time[4];
		
		if($time[4]=~/\d+?/)
		{		
			my $filename=$file."//data//$time_tmp//".$article_author{$key}."_".$temp[3].".txt";
			open(FHD,"> $filename") || die "$!\n";
			print FHD $article_content{$key};
			close(FHD);
		}
		else
		{
			my $filename=$file."//data//".$article_author{$key}."_".$temp[3].".txt";
			open(FHD,"> $filename") || die "$!\n";
			print FHD $article_content{$key};
			close(FHD);
		}
		
	}		
}

my $filename=$file."//data//_index_all_state.txt";
open(FHD,"> $filename") || die "$!\n";
print FHD "Time	author	title\n";
foreach my $key (keys %article_author)
{
	my @temp=split("	",$article_state{$key});
	print FHD $temp[3]."	".$article_author{$key}."	".$temp[2]."\n";
}
close(FHD);


sub catch_index_href()
{
	my ($page)= @_;
	my $prozac_index = "https://www.ptt.cc/bbs/prozac/index".$page.".html"; #prozac index 
	print $prozac_index."\n";
	
	
	my $req = HTTP::Request->new(GET =>$prozac_index);# Create a request
	my $res = $ua->request($req) or die;              # Pass request to the user agent and get a response back
	my $html=$res->content; #Get web
	my $root = HTML::TreeBuilder->new_from_content($html);
	my $class = $root->find_by_attribute("class","r-list-container bbs-screen"); #get index
	
	if(!$class)
	{
		print "page error!! Will catch again.\n";
		&catch_index_href($page);
		return;
	}
	
	my @get_div=$class->find_by_attribute("class","r-ent");
	
	# print $#get_div."_GET\n";
	

	
	#############################GET LINK and AUTHOR#################################
	for(my $i=0;$i<=$#get_div;$i++)
	{
		my $tmp_title=$get_div[$i]->find_by_attribute("class","title")->as_text();
		# print $tmp_title."\n";
		if($tmp_title=~/本文已被刪除/)
		{
			print "the page has been delete!\n";
			next;
		}
		else
		{
			my $link = $get_div[$i]->find_by_tag_name("a")->attr('href');
			my $author= $get_div[$i]->find_by_attribute("class","author")->as_text();	#get author
			$article_author{$link}=$author;
		}
		
		# print $link."\n";
		# print $author."\n";
	}

}

sub get_atrticle_content()
{
	my ($page)= @_;
	my $prozac_index = "https://www.ptt.cc".$page; #article link
	print $prozac_index."\n";
	
	
	my $req = HTTP::Request->new(GET =>$prozac_index);# Create a request
	my $res = $ua->request($req) or die;              # Pass request to the user agent and get a response back
	my $html=$res->content; #Get web
	# print $html;
	my $root = HTML::TreeBuilder->new_from_content($html);
	my $class = $root->find_by_attribute("id","main-content"); #get title and time
	my @title; #save title
	
	
	if(!$class)  #page 404
	{
		return;
	}
	else
	{
		@title = $class->find_by_attribute("class","article-metaline");
	}	

	my $values="";
	my $content="";
	# print $#title."\n";
	#############################GET TITLE and TIME#################################
	for(my $i=0;$i<=$#title;$i++)
	{
		$value=$title[$i]->find_by_attribute("class","article-meta-value")->as_text();
		$values=$values."	".$value;
	}
	$article_state{$page}=$values;
	# print $values."V\n";
	#############################GET CONTENT#################################
	if($html=~/\d+?\<\/span\>\<\/div\>/g)
	{
		my $tmp=$';

		if($tmp=~/--\n<span class="f2">/g) # get content and signature
		{
			# print "********************\n".$`."*********\n";
			$content=$`;
		}
	}
	$content=~s/<.*?>//s;
	$article_content{$page}=$content;	
}


