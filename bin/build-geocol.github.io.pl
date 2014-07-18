use strict;
use warnings;
use Path::Tiny;

my $repos_path = path (__FILE__)->parent->parent->child ('local/repos');
my $dest_path = path (__FILE__)->parent->parent->child ('local/dest/geocol.github.io');
my $data_path = $dest_path->child ('data');

my @file;

sub sync_repo ($$) {
    my ($user, $repo) = @_;

    my $repo_url = 'git://github.com/' . $user . '/' . $repo;
    my $repo_path = $repos_path->child ($repo);
    (system 'git', 'clone', '--depth=1', $repo_url, $repo_path) == 0 or
        (system "cd \Q$repo_path\E && git add . && git reset --hard && git pull") == 0 or die $?;

    my $repo_data_path = $repo_path->child ('data');
    if ($repo_data_path->is_dir) {
        my $iter = $repo_data_path->iterator ({recurse => 1});
        while (my $path = $iter->()) {
            next unless $path->is_file and $path->basename =~ /\.json$/;
            my $dest_file_path = $data_path->child ($user, $repo, $path->relative ($repo_data_path));
            $dest_file_path->parent->mkpath;
            (system 'cp', $path => $dest_file_path) == 0 or die $?;

            my $doc_name = $path->relative ($repo_data_path);
            $doc_name =~ s/\.json$/.txt/;
            $doc_name =~ s{/}{-}g;
            my $doc_path = $repo_path->child ('doc', $doc_name);
            my $doc_url;
            if ($doc_path->is_file) {
                $doc_url = q<https://github.com/geocol/data-jp-areas/blob/master/> . $doc_path->relative ($repo_path);
            }

            push @file, {repo_url => $repo_url,
                         name => $path->relative ($repo_path)->stringify,
                         url => $dest_file_path->relative ($dest_path)->stringify,
                         doc_url => $doc_url};
        } # $path
    }
} # sync_repo

$dest_path->remove_tree ({safe => 0});
sync_repo 'geocol', 'data-jp-areas';
sync_repo 'geocol', 'data-jp-transport';

my @item;
for (sort { $a->{repo_url} cmp $b->{repo_url} or
            $a->{name} cmp $b->{name} } @file) {
    push @item, sprintf q{<li><a href="%s">%s %s</a>%s},
        $_->{url}, $_->{repo_url}, $_->{name},
        (defined $_->{doc_url} ? qq{ (<a href="$_->{doc_url}">document</a>)} : '');
}

my $index_path = $dest_path->child ('index.html');
$index_path->spew_utf8 (qq{
  <!DOCTYPE html>
  <title>Geocol data files</title>
  <h1>Geocol data files</h1>

  <p>See <a href="https://github.com/geocol/">GitHub organization page</a>
  for details.

  <ul>
    @item
  </ul>
});

my $makefile_path = $dest_path->child ('Makefile');
$makefile_path->spew_utf8 (qq{
all:
deps:
updatenightly:
\t(git checkout origin/builder || (git fetch --depth 1 origin && git checkout origin/builder)) && make updatenightly
});

my $remote_url = 'git@github.com:geocol/geocol.github.io';
my $remote_branch = 'master';

(system "cd \Q$dest_path\E &&
         git init &&
         git add data index.html Makefile &&
         git commit -m Generated &&
         git remote add origin \Q$remote_url\E &&
         git push origin +\Q$remote_branch\E") == 0 or die $?;

#         git checkout --orphan \Q$remote_branch\E &&
#         git commit -m Generated &&

## License: Public Domain.
